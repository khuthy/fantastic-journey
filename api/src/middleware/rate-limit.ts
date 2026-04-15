import { createMiddleware } from 'hono/factory';
import { tooManyRequests } from '../lib/errors';
import type { Env, Variables } from '../types';

interface RateLimitOptions {
  /** Max requests per window */
  limit: number;
  /** Window duration in seconds */
  windowSeconds: number;
  /** Key prefix to namespace different endpoints */
  keyPrefix: string;
}

/**
 * Simple sliding-window rate limiter backed by Cloudflare KV.
 *
 * KV provides ~eventual consistency so this is a "soft" rate limit —
 * sufficient for abuse prevention without requiring Durable Objects.
 */
export function rateLimit(opts: RateLimitOptions) {
  return createMiddleware<{ Bindings: Env; Variables: Variables }>(
    async (c, next) => {
      // Use the connecting IP as the discriminator
      const ip = c.req.header('CF-Connecting-IP') ?? 'unknown';
      const key = `rl:${opts.keyPrefix}:${ip}`;

      const raw = await c.env.RATE_LIMIT_KV.get(key);
      const count = raw ? parseInt(raw, 10) : 0;

      if (count >= opts.limit) {
        return tooManyRequests(c, `Rate limit exceeded. Retry after ${opts.windowSeconds}s`);
      }

      // Increment counter; set TTL on first request
      await c.env.RATE_LIMIT_KV.put(key, String(count + 1), {
        expirationTtl: opts.windowSeconds,
      });

      return next();
    },
  );
}

/** Presets */
export const authRateLimit = rateLimit({ limit: 10, windowSeconds: 60, keyPrefix: 'auth' });
export const apiRateLimit  = rateLimit({ limit: 300, windowSeconds: 60, keyPrefix: 'api' });
