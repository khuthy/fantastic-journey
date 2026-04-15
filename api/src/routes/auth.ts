import { Hono } from 'hono';
import { getDb } from '../db/client';
import { hashPassword, verifyPassword } from '../lib/password';
import { signAccessToken, signRefreshToken, verifyRefreshToken, REFRESH_TTL_MS } from '../lib/jwt';
import { sha256 } from '../lib/crypto';
import { authRateLimit } from '../middleware/rate-limit';
import { authMiddleware } from '../middleware/auth';
import { badRequest, unauthorized, conflict, serverError, safeUser } from '../lib/errors';
import type { Env, Variables, DbUser } from '../types';

const auth = new Hono<{ Bindings: Env; Variables: Variables }>();

// Apply rate limiting to all auth routes
auth.use('*', authRateLimit);

// ---------------------------------------------------------------------------
// POST /auth/register
// ---------------------------------------------------------------------------
auth.post('/register', async (c) => {
  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const { email, password, full_name, phone, unit_number, id_number, vehicle_registration } = body;

  if (!email || !password || !full_name || !phone || !unit_number) {
    return badRequest(c, 'email, password, full_name, phone, and unit_number are required');
  }
  if (typeof password !== 'string' || password.length < 8) {
    return badRequest(c, 'Password must be at least 8 characters');
  }

  const sql = getDb(c.env);

  // Check email uniqueness
  const existing = await sql`SELECT id FROM users WHERE email = ${String(email).toLowerCase()}`;
  if (existing.length > 0) {
    return conflict(c, 'An account with this email already exists');
  }

  const passwordHash = await hashPassword(String(password));

  const rows = await sql`
    INSERT INTO users (email, password_hash, full_name, phone, unit_number, id_number, vehicle_registration)
    VALUES (
      ${String(email).toLowerCase()},
      ${passwordHash},
      ${String(full_name)},
      ${String(phone)},
      ${String(unit_number)},
      ${id_number ? String(id_number) : null},
      ${vehicle_registration ? String(vehicle_registration) : null}
    )
    RETURNING *
  `;

  const user = rows[0] as DbUser;
  return c.json({ success: true, user: safeUser(user as Record<string, unknown>) }, 201);
});

// ---------------------------------------------------------------------------
// POST /auth/sign-in
// ---------------------------------------------------------------------------
auth.post('/sign-in', async (c) => {
  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const { email, password } = body;
  if (!email || !password) {
    return badRequest(c, 'email and password are required');
  }

  const sql = getDb(c.env);

  const rows = await sql`
    SELECT * FROM users WHERE email = ${String(email).toLowerCase()} AND is_active = TRUE
  `;

  if (rows.length === 0) {
    return unauthorized(c, 'Invalid email or password');
  }

  const user = rows[0] as DbUser;
  const valid = await verifyPassword(String(password), user.password_hash);
  if (!valid) {
    return unauthorized(c, 'Invalid email or password');
  }

  // Issue tokens
  const accessToken = await signAccessToken(
    { sub: user.id, email: user.email, role: user.role },
    c.env.JWT_SECRET,
  );
  const refreshToken = await signRefreshToken(user.id, c.env.JWT_REFRESH_SECRET);
  const tokenHash = await sha256(refreshToken);
  const expiresAt = new Date(Date.now() + REFRESH_TTL_MS).toISOString();

  // Store hashed refresh token
  await sql`
    INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
    VALUES (${user.id}, ${tokenHash}, ${expiresAt})
  `;

  // Update last_login_at
  await sql`UPDATE users SET last_login_at = NOW() WHERE id = ${user.id}`;

  return c.json({
    success: true,
    access_token: accessToken,
    refresh_token: refreshToken,
    user: safeUser(user as Record<string, unknown>),
  });
});

// ---------------------------------------------------------------------------
// POST /auth/refresh
// ---------------------------------------------------------------------------
auth.post('/refresh', async (c) => {
  let body: Record<string, unknown>;
  try {
    body = await c.req.json<Record<string, unknown>>();
  } catch {
    return badRequest(c, 'Invalid JSON body');
  }

  const { refresh_token } = body;
  if (!refresh_token) return badRequest(c, 'refresh_token is required');

  let userId: string;
  try {
    userId = await verifyRefreshToken(String(refresh_token), c.env.JWT_REFRESH_SECRET);
  } catch {
    return unauthorized(c, 'Invalid or expired refresh token');
  }

  const sql = getDb(c.env);
  const tokenHash = await sha256(String(refresh_token));

  // Validate token exists in DB and hasn't expired
  const stored = await sql`
    SELECT id FROM refresh_tokens
    WHERE user_id = ${userId} AND token_hash = ${tokenHash} AND expires_at > NOW()
  `;
  if (stored.length === 0) {
    return unauthorized(c, 'Refresh token not found or expired');
  }

  const userRows = await sql`SELECT * FROM users WHERE id = ${userId} AND is_active = TRUE`;
  if (userRows.length === 0) return unauthorized(c, 'User not found');

  const user = userRows[0] as DbUser;

  // Rotate: delete old token, issue new pair
  await sql`DELETE FROM refresh_tokens WHERE user_id = ${userId} AND token_hash = ${tokenHash}`;

  const newAccessToken = await signAccessToken(
    { sub: user.id, email: user.email, role: user.role },
    c.env.JWT_SECRET,
  );
  const newRefreshToken = await signRefreshToken(user.id, c.env.JWT_REFRESH_SECRET);
  const newHash = await sha256(newRefreshToken);
  const newExpiry = new Date(Date.now() + REFRESH_TTL_MS).toISOString();

  await sql`
    INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
    VALUES (${userId}, ${newHash}, ${newExpiry})
  `;

  return c.json({
    success: true,
    access_token: newAccessToken,
    refresh_token: newRefreshToken,
  });
});

// ---------------------------------------------------------------------------
// POST /auth/sign-out  (authenticated)
// ---------------------------------------------------------------------------
auth.post('/sign-out', authMiddleware, async (c) => {
  const userId = c.get('user').sub;
  const sql = getDb(c.env);

  // Revoke all refresh tokens for this user (sign out everywhere)
  await sql`DELETE FROM refresh_tokens WHERE user_id = ${userId}`;

  return c.json({ success: true });
});

export default auth;
