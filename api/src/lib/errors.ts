import type { Context } from 'hono';
import type { Env, Variables } from '../types';

type AppContext = Context<{ Bindings: Env; Variables: Variables }>;

/** Return a standardised JSON error response. */
export function err(c: AppContext, status: number, message: string) {
  return c.json({ success: false, message }, status as Parameters<typeof c.json>[1]);
}

/** 400 */
export const badRequest  = (c: AppContext, msg = 'Bad request')    => err(c, 400, msg);
/** 401 */
export const unauthorized = (c: AppContext, msg = 'Unauthorized')  => err(c, 401, msg);
/** 403 */
export const forbidden    = (c: AppContext, msg = 'Forbidden')     => err(c, 403, msg);
/** 404 */
export const notFound     = (c: AppContext, msg = 'Not found')     => err(c, 404, msg);
/** 409 */
export const conflict     = (c: AppContext, msg = 'Conflict')      => err(c, 409, msg);
/** 422 */
export const unprocessable = (c: AppContext, msg: string)          => err(c, 422, msg);
/** 429 */
export const tooManyRequests = (c: AppContext, msg = 'Too many requests') => err(c, 429, msg);
/** 500 */
export const serverError  = (c: AppContext, msg = 'Internal server error') => err(c, 500, msg);

/** Strip the password_hash field before returning a user to the client. */
export function safeUser(row: Record<string, unknown>) {
  const { password_hash: _, ...safe } = row;
  return safe;
}
