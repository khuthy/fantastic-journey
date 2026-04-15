import { Hono } from 'hono';
import { authMiddleware, requireRole } from '../middleware/auth';
import { presignDownload, presignUpload, deleteObject, listObjects } from '../lib/r2';
import { badRequest, forbidden } from '../lib/errors';
import type { Env, Variables } from '../types';

const r2 = new Hono<{ Bindings: Env; Variables: Variables }>();

r2.use('*', authMiddleware);

// ---------------------------------------------------------------------------
// Allowed key prefixes per role
// Prevents residents from accessing footage, etc.
// ---------------------------------------------------------------------------
function isKeyAllowed(key: string, role: string): boolean {
  if (role === 'admin') return true;
  if (role === 'security') return key.startsWith('cameras/');
  // residents: only their own avatar uploads
  if (role === 'resident') return key.startsWith('avatars/');
  return false;
}

// ---------------------------------------------------------------------------
// GET /r2/presign?key=...&operation=upload|download&expiry_seconds=3600
// ---------------------------------------------------------------------------
r2.get('/presign', async (c) => {
  const { key, operation, expiry_seconds = '3600', content_type = 'application/octet-stream' } = c.req.query();

  if (!key) return badRequest(c, 'key is required');
  if (operation !== 'upload' && operation !== 'download') {
    return badRequest(c, 'operation must be "upload" or "download"');
  }

  const caller = c.get('user');
  if (!isKeyAllowed(key, caller.role)) {
    return forbidden(c, 'You do not have permission to access this object');
  }

  const expiry = Math.min(Math.max(60, parseInt(expiry_seconds, 10)), 86_400);

  const url =
    operation === 'upload'
      ? await presignUpload(c.env, key, content_type, expiry)
      : await presignDownload(c.env, key, expiry);

  return c.json({ url, expires_in: expiry });
});

// ---------------------------------------------------------------------------
// GET /r2/list?prefix=cameras/cam1/&max_keys=100&continuation_token=...
// Security + admin only
// ---------------------------------------------------------------------------
r2.get('/list', requireRole('security', 'admin'), async (c) => {
  const { prefix = '', max_keys = '100', continuation_token } = c.req.query();

  const { objects, nextToken } = await listObjects(
    c.env,
    prefix,
    Math.min(500, parseInt(max_keys, 10)),
    continuation_token,
  );

  return c.json({ objects, next_continuation_token: nextToken ?? null });
});

// ---------------------------------------------------------------------------
// DELETE /r2/object?key=...  (admin only)
// ---------------------------------------------------------------------------
r2.delete('/object', requireRole('admin'), async (c) => {
  const { key } = c.req.query();
  if (!key) return badRequest(c, 'key is required');

  await deleteObject(c.env, key);
  return c.json({ success: true });
});

export default r2;
