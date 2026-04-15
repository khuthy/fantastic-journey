import { Hono } from 'hono';
import { getDb } from '../db/client';
import { authMiddleware, requireRole } from '../middleware/auth';
import { badRequest, notFound } from '../lib/errors';
import type { Env, Variables } from '../types';

const announcements = new Hono<{ Bindings: Env; Variables: Variables }>();

announcements.use('*', authMiddleware);

// ---------------------------------------------------------------------------
// GET /announcements
// Returns active announcements visible to the caller's role.
// Query params: target_role, page, limit
// ---------------------------------------------------------------------------
announcements.get('/', async (c) => {
  const { target_role, page = '1', limit = '20' } = c.req.query();
  const caller = c.get('user');
  const sql = getDb(c.env);

  const offset = (Math.max(1, parseInt(page, 10)) - 1) * Math.min(100, parseInt(limit, 10));
  const limitVal = Math.min(100, parseInt(limit, 10));

  // Filter to announcements targeted at caller's role (or all-roles announcements)
  const roleFilter = target_role ?? caller.role;

  const rows = await sql`
    SELECT * FROM announcements
    WHERE (expires_at IS NULL OR expires_at > NOW())
      AND (target_roles IS NULL OR ${roleFilter} = ANY(target_roles))
    ORDER BY is_pinned DESC, created_at DESC
    LIMIT ${limitVal} OFFSET ${offset}
  `;

  return c.json(rows);
});

// ---------------------------------------------------------------------------
// GET /announcements/:id
// ---------------------------------------------------------------------------
announcements.get('/:id', async (c) => {
  const sql = getDb(c.env);
  const rows = await sql`SELECT * FROM announcements WHERE id = ${c.req.param('id')}`;
  if (rows.length === 0) return notFound(c, 'Announcement not found');
  return c.json(rows[0]);
});

// ---------------------------------------------------------------------------
// POST /announcements  (admin only)
// ---------------------------------------------------------------------------
announcements.post('/', requireRole('admin'), async (c) => {
  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const { title, body: msgBody, priority = 'medium', expires_at, image_url, is_pinned = false, target_roles } = body;

  if (!title || !msgBody) return badRequest(c, 'title and body are required');

  const validPriorities = ['low', 'medium', 'high', 'urgent'];
  if (!validPriorities.includes(String(priority))) {
    return badRequest(c, `priority must be one of: ${validPriorities.join(', ')}`);
  }

  const caller = c.get('user');
  const sql = getDb(c.env);

  // Resolve author name from DB
  const userRows = await sql`SELECT full_name FROM users WHERE id = ${caller.sub}`;
  const authorName = (userRows[0] as { full_name: string } | undefined)?.full_name ?? 'Admin';

  const rows = await sql`
    INSERT INTO announcements (title, body, author_id, author_name, priority, expires_at, image_url, is_pinned, target_roles)
    VALUES (
      ${String(title)},
      ${String(msgBody)},
      ${caller.sub},
      ${authorName},
      ${String(priority)},
      ${expires_at ? new Date(String(expires_at)).toISOString() : null},
      ${image_url ? String(image_url) : null},
      ${Boolean(is_pinned)},
      ${Array.isArray(target_roles) ? target_roles : null}
    )
    RETURNING *
  `;

  return c.json(rows[0], 201);
});

// ---------------------------------------------------------------------------
// PATCH /announcements/:id  (admin only)
// ---------------------------------------------------------------------------
announcements.patch('/:id', requireRole('admin'), async (c) => {
  const { id } = c.req.param();
  const sql = getDb(c.env);

  const rows = await sql`SELECT id FROM announcements WHERE id = ${id}`;
  if (rows.length === 0) return notFound(c, 'Announcement not found');

  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const allowed = ['title', 'body', 'priority', 'expires_at', 'image_url', 'is_pinned', 'target_roles'];
  const updates = Object.fromEntries(Object.entries(body).filter(([k]) => allowed.includes(k)));

  if (Object.keys(updates).length === 0) return badRequest(c, 'No valid fields to update');

  const setClauses = Object.entries(updates)
    .map(([k, v]) => sql`${sql(k)} = ${v as string}`)
    .reduce((a, b) => sql`${a}, ${b}`);

  const updated = await sql`
    UPDATE announcements SET ${setClauses}, updated_at = NOW() WHERE id = ${id} RETURNING *
  `;

  return c.json(updated[0]);
});

// ---------------------------------------------------------------------------
// DELETE /announcements/:id  (admin only)
// ---------------------------------------------------------------------------
announcements.delete('/:id', requireRole('admin'), async (c) => {
  const { id } = c.req.param();
  const sql = getDb(c.env);

  const result = await sql`DELETE FROM announcements WHERE id = ${id} RETURNING id`;
  if (result.length === 0) return notFound(c, 'Announcement not found');

  return c.json({ success: true });
});

export default announcements;
