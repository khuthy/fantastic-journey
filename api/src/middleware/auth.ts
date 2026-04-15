import { createMiddleware } from 'hono/factory';
import { verifyAccessToken } from '../lib/jwt';
import { unauthorized } from '../lib/errors';
import type { Env, Variables } from '../types';

/**
 * JWT authentication middleware.
 * Reads the Bearer token from the Authorization header, verifies it, and
 * stores the decoded payload in `c.var.user` for downstream handlers.
 */
export const authMiddleware = createMiddleware<{
  Bindings: Env;
  Variables: Variables;
}>(async (c, next) => {
  const header = c.req.header('Authorization');
  if (!header?.startsWith('Bearer ')) {
    return unauthorized(c, 'Missing or malformed Authorization header');
  }

  const token = header.slice(7);
  try {
    const payload = await verifyAccessToken(token, c.env.JWT_SECRET);
    c.set('user', payload);
  } catch {
    return unauthorized(c, 'Invalid or expired access token');
  }

  return next();
});

/**
 * Role-gate middleware — call after authMiddleware.
 * Usage: requireRole('admin', 'security')
 */
export function requireRole(...roles: string[]) {
  return createMiddleware<{ Bindings: Env; Variables: Variables }>(
    async (c, next) => {
      const user = c.get('user');
      if (!roles.includes(user.role)) {
        return c.json({ success: false, message: 'Forbidden' }, 403);
      }
      return next();
    },
  );
}
