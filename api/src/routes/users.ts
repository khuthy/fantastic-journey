import { Hono } from 'hono';
import { getDb } from '../db/client';
import { authMiddleware, requireRole } from '../middleware/auth';
import { badRequest, notFound, safeUser } from '../lib/errors';
import type { Env, Variables } from '../types';

const users = new Hono<{ Bindings: Env; Variables: Variables }>();

users.use('*', authMiddleware);

// ---------------------------------------------------------------------------
// GET /users/me
// ---------------------------------------------------------------------------
users.get('/me', async (c) => {
  const sql = getDb(c.env);
  const rows = await sql`SELECT * FROM users WHERE id = ${c.get('user').sub}`;
  if (rows.length === 0) return notFound(c, 'User not found');
  return c.json(safeUser(rows[0] as Record<string, unknown>));
});

// ---------------------------------------------------------------------------
// GET /users  (admin only)
// Query params: role, search, page, limit
// ---------------------------------------------------------------------------
users.get('/', requireRole('admin'), async (c) => {
  const { role, search, page = '1', limit = '20' } = c.req.query();
  const sql = getDb(c.env);

  const offset = (Math.max(1, parseInt(page, 10)) - 1) * Math.min(100, parseInt(limit, 10));
  const limitVal = Math.min(100, parseInt(limit, 10));

  let rows: Record<string, unknown>[];

  if (search) {
    const pattern = `%${search}%`;
    rows = (await sql`
      SELECT * FROM users
      WHERE (full_name ILIKE ${pattern} OR email ILIKE ${pattern} OR unit_number ILIKE ${pattern})
        ${role ? sql`AND role = ${role}` : sql``}
      ORDER BY created_at DESC
      LIMIT ${limitVal} OFFSET ${offset}
    `) as Record<string, unknown>[];
  } else {
    rows = (await sql`
      SELECT * FROM users
      WHERE TRUE
        ${role ? sql`AND role = ${role}` : sql``}
      ORDER BY created_at DESC
      LIMIT ${limitVal} OFFSET ${offset}
    `) as Record<string, unknown>[];
  }

  return c.json(rows.map(safeUser));
});

// ---------------------------------------------------------------------------
// PATCH /users/:id
// Residents can only update their own profile.
// Admin can update any user.
// ---------------------------------------------------------------------------
const ALLOWED_SELF_FIELDS = new Set([
  'full_name', 'phone', 'unit_number', 'vehicle_registration', 'avatar_url',
]);
const ALLOWED_ADMIN_FIELDS = new Set([
  ...ALLOWED_SELF_FIELDS,
  'role', 'is_verified', 'is_active', 'id_number',
]);

users.patch('/:id', async (c) => {
  const { id } = c.req.param();
  const caller = c.get('user');
  const sql = getDb(c.env);

  const isSelf  = caller.sub === id;
  const isAdmin = caller.role === 'admin';

  if (!isSelf && !isAdmin) {
    return c.json({ success: false, message: 'Forbidden' }, 403);
  }

  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const allowed = isAdmin ? ALLOWED_ADMIN_FIELDS : ALLOWED_SELF_FIELDS;
  const updates = Object.fromEntries(
    Object.entries(body).filter(([k]) => allowed.has(k)),
  );

  if (Object.keys(updates).length === 0) {
    return badRequest(c, 'No valid fields to update');
  }

  // Build SET clause dynamically
  const setClauses = Object.entries(updates)
    .map(([k, v]) => sql`${sql(k)} = ${v as string}`)
    .reduce((a, b) => sql`${a}, ${b}`);

  const rows = await sql`
    UPDATE users SET ${setClauses} WHERE id = ${id} RETURNING *
  `;

  if (rows.length === 0) return notFound(c, 'User not found');
  return c.json(safeUser(rows[0] as Record<string, unknown>));
});

export default users;
