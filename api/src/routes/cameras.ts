import { Hono } from 'hono';
import { getDb } from '../db/client';
import { authMiddleware, requireRole } from '../middleware/auth';
import { badRequest, notFound } from '../lib/errors';
import type { Env, Variables } from '../types';

const cameras = new Hono<{ Bindings: Env; Variables: Variables }>();

cameras.use('*', authMiddleware);

// Security guards and admins can access cameras
cameras.use('*', requireRole('security', 'admin'));

// ---------------------------------------------------------------------------
// GET /cameras
// ---------------------------------------------------------------------------
cameras.get('/', async (c) => {
  const sql = getDb(c.env);
  const rows = await sql`SELECT * FROM cameras ORDER BY location, name`;
  return c.json(rows);
});

// ---------------------------------------------------------------------------
// GET /cameras/:id
// ---------------------------------------------------------------------------
cameras.get('/:id', async (c) => {
  const sql = getDb(c.env);
  const rows = await sql`SELECT * FROM cameras WHERE id = ${c.req.param('id')}`;
  if (rows.length === 0) return notFound(c, 'Camera not found');
  return c.json(rows[0]);
});

// ---------------------------------------------------------------------------
// POST /cameras  (admin only)
// ---------------------------------------------------------------------------
cameras.post('/', requireRole('admin'), async (c) => {
  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const { name, location, stream_url, status = 'online', ip_address, model, r2_bucket_path } = body;
  if (!name || !location || !stream_url) {
    return badRequest(c, 'name, location, and stream_url are required');
  }

  const sql = getDb(c.env);
  const rows = await sql`
    INSERT INTO cameras (name, location, stream_url, status, ip_address, model, r2_bucket_path)
    VALUES (
      ${String(name)},
      ${String(location)},
      ${String(stream_url)},
      ${String(status)},
      ${ip_address ? String(ip_address) : null},
      ${model ? String(model) : null},
      ${r2_bucket_path ? String(r2_bucket_path) : null}
    )
    RETURNING *
  `;

  return c.json(rows[0], 201);
});

// ---------------------------------------------------------------------------
// PATCH /cameras/:id  (admin only)
// ---------------------------------------------------------------------------
cameras.patch('/:id', requireRole('admin'), async (c) => {
  const { id } = c.req.param();
  const sql = getDb(c.env);

  const existing = await sql`SELECT id FROM cameras WHERE id = ${id}`;
  if (existing.length === 0) return notFound(c, 'Camera not found');

  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const allowed = ['name', 'location', 'stream_url', 'status', 'thumbnail_url',
                   'last_footage_key', 'ip_address', 'model', 'is_recording', 'r2_bucket_path'];
  const updates = Object.fromEntries(Object.entries(body).filter(([k]) => allowed.includes(k)));
  if (Object.keys(updates).length === 0) return badRequest(c, 'No valid fields to update');

  const setClauses = Object.entries(updates)
    .map(([k, v]) => sql`${sql(k)} = ${v as string}`)
    .reduce((a, b) => sql`${a}, ${b}`);

  const rows = await sql`
    UPDATE cameras SET ${setClauses}, updated_at = NOW() WHERE id = ${id} RETURNING *
  `;

  return c.json(rows[0]);
});

// ---------------------------------------------------------------------------
// DELETE /cameras/:id  (admin only)
// ---------------------------------------------------------------------------
cameras.delete('/:id', requireRole('admin'), async (c) => {
  const sql = getDb(c.env);
  const result = await sql`DELETE FROM cameras WHERE id = ${c.req.param('id')} RETURNING id`;
  if (result.length === 0) return notFound(c, 'Camera not found');
  return c.json({ success: true });
});

// ---------------------------------------------------------------------------
// GET /cameras/:id/footage
// Query params: from, to, page, limit
// ---------------------------------------------------------------------------
cameras.get('/:id/footage', async (c) => {
  const { id } = c.req.param();
  const { from, to, page = '1', limit = '30' } = c.req.query();
  const sql = getDb(c.env);

  const offset = (Math.max(1, parseInt(page, 10)) - 1) * Math.min(100, parseInt(limit, 10));
  const limitVal = Math.min(100, parseInt(limit, 10));
  const fromDate = from ? new Date(from) : null;
  const toDate   = to   ? new Date(to)   : null;

  const camera = await sql`SELECT id FROM cameras WHERE id = ${id}`;
  if (camera.length === 0) return notFound(c, 'Camera not found');

  const rows = await sql`
    SELECT * FROM footage_records
    WHERE camera_id = ${id}
      ${fromDate ? sql`AND start_time >= ${fromDate.toISOString()}` : sql``}
      ${toDate   ? sql`AND start_time <= ${toDate.toISOString()}`   : sql``}
    ORDER BY start_time DESC
    LIMIT ${limitVal} OFFSET ${offset}
  `;

  return c.json(rows);
});

// ---------------------------------------------------------------------------
// POST /cameras/:id/footage  — register a new footage record (from recording agent)
// ---------------------------------------------------------------------------
cameras.post('/:id/footage', async (c) => {
  const { id } = c.req.param();
  const sql = getDb(c.env);

  const camera = await sql`SELECT id FROM cameras WHERE id = ${id}`;
  if (camera.length === 0) return notFound(c, 'Camera not found');

  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const { r2_key, start_time, end_time, file_size_bytes = 0, thumbnail_key, duration_seconds } = body;
  if (!r2_key || !start_time || !end_time) {
    return badRequest(c, 'r2_key, start_time, and end_time are required');
  }

  const rows = await sql`
    INSERT INTO footage_records (camera_id, r2_key, start_time, end_time, file_size_bytes, thumbnail_key, duration_seconds)
    VALUES (
      ${id},
      ${String(r2_key)},
      ${new Date(String(start_time)).toISOString()},
      ${new Date(String(end_time)).toISOString()},
      ${Number(file_size_bytes)},
      ${thumbnail_key ? String(thumbnail_key) : null},
      ${duration_seconds ? Number(duration_seconds) : null}
    )
    RETURNING *
  `;

  // Update camera's last_footage_key
  await sql`
    UPDATE cameras SET last_footage_key = ${String(r2_key)}, updated_at = NOW() WHERE id = ${id}
  `;

  return c.json(rows[0], 201);
});

export default cameras;
