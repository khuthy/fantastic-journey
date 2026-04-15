import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { secureHeaders } from 'hono/secure-headers';
import { prettyJSON } from 'hono/pretty-json';

import authRouter         from './routes/auth';
import usersRouter        from './routes/users';
import passesRouter       from './routes/passes';
import entryLogRouter     from './routes/entry-log';
import announcementsRouter from './routes/announcements';
import camerasRouter      from './routes/cameras';
import r2Router           from './routes/r2';
import { apiRateLimit }   from './middleware/rate-limit';
import { serverError }    from './lib/errors';
import type { Env, Variables } from './types';

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------
const app = new Hono<{ Bindings: Env; Variables: Variables }>();

// ---------------------------------------------------------------------------
// Global middleware
// ---------------------------------------------------------------------------
app.use('*', async (c, next) => {
  // CORS — restrict to configured origin in production
  const origin = c.env.ENVIRONMENT === 'development' ? '*' : c.env.CORS_ORIGIN;
  return cors({
    origin,
    allowMethods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
    allowHeaders: ['Content-Type', 'Authorization'],
    maxAge: 86_400,
  })(c, next);
});

app.use('*', secureHeaders());
app.use('*', prettyJSON());

// Only log in non-production to avoid leaking request details
app.use('*', async (c, next) => {
  if (c.env.ENVIRONMENT !== 'production') {
    return logger()(c, next);
  }
  return next();
});

// Apply general rate limit to all API routes
app.use('/api/*', apiRateLimit);

// ---------------------------------------------------------------------------
// Health check (no auth required)
// ---------------------------------------------------------------------------
app.get('/', (c) =>
  c.json({
    name: 'Protea Glen Gate Access API',
    version: '1.0.0',
    status: 'ok',
    environment: c.env.ENVIRONMENT,
  }),
);

app.get('/health', (c) => c.json({ status: 'ok', ts: new Date().toISOString() }));

// ---------------------------------------------------------------------------
// Routes
// ---------------------------------------------------------------------------
app.route('/auth',          authRouter);
app.route('/users',         usersRouter);
app.route('/passes',        passesRouter);
app.route('/entry-log',     entryLogRouter);
app.route('/announcements', announcementsRouter);
app.route('/cameras',       camerasRouter);
app.route('/r2',            r2Router);

// ---------------------------------------------------------------------------
// 404 catch-all
// ---------------------------------------------------------------------------
app.notFound((c) => c.json({ success: false, message: 'Route not found' }, 404));

// ---------------------------------------------------------------------------
// Global error handler
// ---------------------------------------------------------------------------
app.onError((err, c) => {
  console.error('[unhandled error]', err);

  // Don't leak internal details in production
  const message =
    c.env.ENVIRONMENT === 'production'
      ? 'Internal server error'
      : err.message;

  return c.json({ success: false, message }, 500);
});

export default app;
