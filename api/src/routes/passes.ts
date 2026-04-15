import { Hono } from 'hono';
import { getDb } from '../db/client';
import { authMiddleware, requireRole } from '../middleware/auth';
import { generateOtp, generateQrToken } from '../lib/crypto';
import { badRequest, notFound, unprocessable } from '../lib/errors';
import type { Env, Variables, DbPass, DbUser } from '../types';

const passes = new Hono<{ Bindings: Env; Variables: Variables }>();

passes.use('*', authMiddleware);

// ---------------------------------------------------------------------------
// POST /passes  — create a visitor pass
// ---------------------------------------------------------------------------
passes.post('/', async (c) => {
  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const {
    resident_id,
    visitor_name,
    visitor_phone,
    pass_type,
    expires_at,
    vehicle_registration,
    purpose,
    max_uses = 1,
    notes,
  } = body;

  if (!visitor_name || !visitor_phone || !pass_type || !expires_at) {
    return badRequest(c, 'visitor_name, visitor_phone, pass_type, and expires_at are required');
  }
  if (pass_type !== 'qr' && pass_type !== 'otp') {
    return badRequest(c, 'pass_type must be "qr" or "otp"');
  }

  const caller = c.get('user');
  // Residents can only create passes for themselves
  const effectiveResidentId =
    caller.role === 'admin' && resident_id
      ? String(resident_id)
      : caller.sub;

  const sql = getDb(c.env);

  // Verify resident exists
  const residentRows = await sql`
    SELECT id FROM users WHERE id = ${effectiveResidentId} AND is_active = TRUE
  `;
  if (residentRows.length === 0) return notFound(c, 'Resident not found');

  const expiresDate = new Date(String(expires_at));
  if (isNaN(expiresDate.getTime()) || expiresDate <= new Date()) {
    return badRequest(c, 'expires_at must be a valid future date');
  }

  // Generate the token
  const token = pass_type === 'otp' ? generateOtp() : generateQrToken();

  const rows = await sql`
    INSERT INTO visitor_passes (
      resident_id, visitor_name, visitor_phone, pass_type,
      token, expires_at, vehicle_registration, purpose, max_uses, notes
    ) VALUES (
      ${effectiveResidentId},
      ${String(visitor_name)},
      ${String(visitor_phone)},
      ${pass_type},
      ${token},
      ${expiresDate.toISOString()},
      ${vehicle_registration ? String(vehicle_registration) : null},
      ${purpose ? String(purpose) : null},
      ${Number(max_uses)},
      ${notes ? String(notes) : null}
    )
    RETURNING *
  `;

  return c.json({ success: true, ...(rows[0] as DbPass) }, 201);
});

// ---------------------------------------------------------------------------
// GET /passes  — list passes
// Query params: resident_id, status, page, limit
// ---------------------------------------------------------------------------
passes.get('/', async (c) => {
  const { resident_id, status, page = '1', limit = '20' } = c.req.query();
  const caller = c.get('user');
  const sql = getDb(c.env);

  const offset = (Math.max(1, parseInt(page, 10)) - 1) * Math.min(100, parseInt(limit, 10));
  const limitVal = Math.min(100, parseInt(limit, 10));

  // Residents can only see their own passes
  const effectiveResidentId =
    caller.role === 'resident'
      ? caller.sub
      : resident_id && resident_id !== 'all'
      ? resident_id
      : null;

  // Auto-expire passes that have passed their expiry date
  await sql`
    UPDATE visitor_passes
    SET status = 'expired'
    WHERE status = 'active' AND expires_at < NOW()
  `;

  const rows = await sql`
    SELECT vp.*, u.unit_number as resident_unit, u.full_name as resident_name
    FROM visitor_passes vp
    JOIN users u ON u.id = vp.resident_id
    WHERE TRUE
      ${effectiveResidentId ? sql`AND vp.resident_id = ${effectiveResidentId}` : sql``}
      ${status ? sql`AND vp.status = ${status}` : sql``}
    ORDER BY vp.created_at DESC
    LIMIT ${limitVal} OFFSET ${offset}
  `;

  return c.json(rows);
});

// ---------------------------------------------------------------------------
// GET /passes/:id
// ---------------------------------------------------------------------------
passes.get('/:id', async (c) => {
  const { id } = c.req.param();
  const caller = c.get('user');
  const sql = getDb(c.env);

  const rows = await sql`
    SELECT vp.*, u.unit_number as resident_unit, u.full_name as resident_name
    FROM visitor_passes vp
    JOIN users u ON u.id = vp.resident_id
    WHERE vp.id = ${id}
  `;

  if (rows.length === 0) return notFound(c, 'Pass not found');
  const pass = rows[0] as DbPass & { resident_unit: string };

  // Residents can only view their own passes
  if (caller.role === 'resident' && pass.resident_id !== caller.sub) {
    return c.json({ success: false, message: 'Forbidden' }, 403);
  }

  return c.json(pass);
});

// ---------------------------------------------------------------------------
// POST /passes/validate  — called by security guard at the gate
// ---------------------------------------------------------------------------
passes.post('/validate', requireRole('security', 'admin'), async (c) => {
  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const { token } = body;
  if (!token) return badRequest(c, 'token is required');

  const sql = getDb(c.env);
  const guardId = c.get('user').sub;

  // Find the pass by token
  const rows = await sql`
    SELECT vp.*, u.unit_number as resident_unit, u.full_name as resident_name, u.phone as resident_phone
    FROM visitor_passes vp
    JOIN users u ON u.id = vp.resident_id
    WHERE vp.token = ${String(token)}
  `;

  // Record the attempt in entry_log regardless of outcome
  const logEntry = async (
    pass: (DbPass & Record<string, string>) | null,
    success: boolean,
    reason?: string,
  ) => {
    await sql`
      INSERT INTO entry_log (
        pass_id, visitor_name, visitor_phone,
        resident_id, resident_unit, guard_id,
        vehicle_registration, pass_type, success, failure_reason
      ) VALUES (
        ${pass?.id ?? null},
        ${pass?.visitor_name ?? 'Unknown'},
        ${pass?.visitor_phone ?? null},
        ${pass?.resident_id ?? null},
        ${pass?.resident_unit ?? null},
        ${guardId},
        ${pass?.vehicle_registration ?? null},
        ${pass?.pass_type ?? null},
        ${success},
        ${reason ?? null}
      )
    `;
  };

  if (rows.length === 0) {
    await logEntry(null, false, 'Token not found');
    return c.json({
      valid: false,
      message: 'Pass not found. Please check the code and try again.',
    }, 200);
  }

  const pass = rows[0] as DbPass & Record<string, string>;

  // --- Validation checks ---
  if (pass.status === 'revoked') {
    await logEntry(pass, false, 'Pass revoked');
    return c.json({ valid: false, message: 'This pass has been revoked by the resident.' });
  }
  if (pass.status === 'expired' || new Date(pass.expires_at) < new Date()) {
    await logEntry(pass, false, 'Pass expired');
    // Ensure status is updated
    await sql`UPDATE visitor_passes SET status = 'expired' WHERE id = ${pass.id}`;
    return c.json({ valid: false, message: 'This pass has expired.' });
  }
  if (pass.use_count >= pass.max_uses) {
    await logEntry(pass, false, 'Max uses exceeded');
    await sql`UPDATE visitor_passes SET status = 'used' WHERE id = ${pass.id}`;
    return c.json({ valid: false, message: 'This pass has already been used the maximum number of times.' });
  }

  // --- Valid: increment use_count, update status if exhausted ---
  const newCount = pass.use_count + 1;
  const newStatus = newCount >= pass.max_uses ? 'used' : 'active';

  await sql`
    UPDATE visitor_passes
    SET use_count = ${newCount}, status = ${newStatus}, updated_at = NOW()
    WHERE id = ${pass.id}
  `;

  await logEntry(pass, true);

  return c.json({
    valid: true,
    message: 'Access granted.',
    visitor_name: pass.visitor_name,
    visitor_phone: pass.visitor_phone,
    resident_unit: pass.resident_unit,
    resident_name: pass.resident_name,
    vehicle_registration: pass.vehicle_registration,
    pass_type: pass.pass_type,
    expires_at: pass.expires_at,
    uses_remaining: pass.max_uses - newCount,
  });
});

// ---------------------------------------------------------------------------
// PATCH /passes/:id  — revoke or update a pass
// ---------------------------------------------------------------------------
passes.patch('/:id', async (c) => {
  const { id } = c.req.param();
  const caller = c.get('user');
  const sql = getDb(c.env);

  const rows = await sql`SELECT * FROM visitor_passes WHERE id = ${id}`;
  if (rows.length === 0) return notFound(c, 'Pass not found');
  const pass = rows[0] as DbPass;

  if (caller.role === 'resident' && pass.resident_id !== caller.sub) {
    return c.json({ success: false, message: 'Forbidden' }, 403);
  }

  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const { status } = body;
  if (status && !['revoked'].includes(String(status))) {
    return unprocessable(c, 'Residents may only revoke passes (status: "revoked")');
  }

  const updated = await sql`
    UPDATE visitor_passes SET status = ${String(status)}, updated_at = NOW()
    WHERE id = ${id}
    RETURNING *
  `;

  return c.json(updated[0]);
});

export default passes;
