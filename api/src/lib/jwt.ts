import { SignJWT, jwtVerify, type JWTPayload } from 'jose';
import type { JwtPayload, UserRole } from '../types';

const ACCESS_TTL  = 60 * 60;          // 1 hour  (seconds)
const REFRESH_TTL = 60 * 60 * 24 * 30; // 30 days (seconds)

function secretBytes(secret: string): Uint8Array {
  return new TextEncoder().encode(secret);
}

// ---------------------------------------------------------------------------
// Access token
// ---------------------------------------------------------------------------

export async function signAccessToken(
  payload: Omit<JwtPayload, 'iat' | 'exp'>,
  secret: string,
): Promise<string> {
  return new SignJWT({ email: payload.email, role: payload.role })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(payload.sub)
    .setIssuedAt()
    .setExpirationTime(`${ACCESS_TTL}s`)
    .sign(secretBytes(secret));
}

export async function verifyAccessToken(
  token: string,
  secret: string,
): Promise<JwtPayload> {
  const { payload } = await jwtVerify(token, secretBytes(secret));
  return jwtPayloadToTyped(payload);
}

// ---------------------------------------------------------------------------
// Refresh token
// ---------------------------------------------------------------------------

export async function signRefreshToken(userId: string, secret: string): Promise<string> {
  return new SignJWT({})
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime(`${REFRESH_TTL}s`)
    .sign(secretBytes(secret));
}

export async function verifyRefreshToken(token: string, secret: string): Promise<string> {
  const { payload } = await jwtVerify(token, secretBytes(secret));
  if (!payload.sub) throw new Error('Missing sub in refresh token');
  return payload.sub;
}

export const REFRESH_TTL_MS = REFRESH_TTL * 1000;

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

function jwtPayloadToTyped(p: JWTPayload): JwtPayload {
  if (!p.sub) throw new Error('JWT missing sub');
  return {
    sub: p.sub,
    email: (p['email'] as string) ?? '',
    role: (p['role'] as UserRole) ?? 'resident',
    iat: p.iat,
    exp: p.exp,
  };
}
