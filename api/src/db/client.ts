import { neon, type NeonQueryFunction } from '@neondatabase/serverless';
import type { Env } from '../types';

/**
 * Returns a tagged-template SQL executor bound to this request's Neon connection.
 *
 * @neondatabase/serverless uses an HTTP transport, so it works correctly inside
 * Cloudflare Workers without requiring a persistent TCP connection.
 *
 * Usage:
 *   const sql = getDb(env);
 *   const rows = await sql`SELECT * FROM users WHERE id = ${userId}`;
 */
export function getDb(env: Env): NeonQueryFunction<false, false> {
  return neon(env.DATABASE_URL);
}
