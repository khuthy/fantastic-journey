import { Hono } from 'hono';
import { getDb } from '../db/client';
import { authMiddleware, requireRole } from '../middleware/auth';
import type { Env, Variables } from '../types';

const entryLog = new Hono<{ Bindings: Env; Variables: Variables }>();

entryLog.use('*', authMiddleware);

// ---------------------------------------------------------------------------
// GET /entry-log
// Security guards see all entries; residents see only their own.
// Query params: from, to, page, limit
// ---------------------------------------------------------------------------
entryLog.get('/', async (c) => {
  const { from, to, page = '1', limit = '50' } = c.req.query();
  const caller = c.get('user');
  const sql = getDb(c.env);

  const offset = (Math.max(1, parseInt(page, 10)) - 1) * Math.min(100, parseInt(limit, 10));
  const limitVal = Math.min(100, parseInt(limit, 10));

  const fromDate = from ? new Date(from) : null;
  const toDate   = to   ? new Date(to)   : null;

  const rows = await sql`
    SELECT el.*, u.full_name as guard_name
    FROM entry_log el
    LEFT JOIN users u ON u.id = el.guard_id
    WHERE TRUE
      ${caller.role === 'resident' ? sql`AND el.resident_id = ${caller.sub}` : sql``}
      ${fromDate ? sql`AND el.created_at >= ${fromDate.toISOString()}` : sql``}
      ${toDate   ? sql`AND el.created_at <= ${toDate.toISOString()}`   : sql``}
    ORDER BY el.created_at DESC
    LIMIT ${limitVal} OFFSET ${offset}
  `;

  return c.json(rows);
});

export default entryLog;
