// ---------------------------------------------------------------------------
// Cloudflare Worker environment bindings
// ---------------------------------------------------------------------------
export interface Env {
  // Secrets (set via wrangler secret put)
  DATABASE_URL: string;
  JWT_SECRET: string;
  JWT_REFRESH_SECRET: string;
  R2_ACCESS_KEY_ID: string;
  R2_SECRET_ACCESS_KEY: string;
  R2_BUCKET_NAME: string;
  R2_ACCOUNT_ID: string;

  // Vars (wrangler.toml)
  ENVIRONMENT: 'production' | 'staging' | 'development';
  CORS_ORIGIN: string;

  // KV namespace
  RATE_LIMIT_KV: KVNamespace;

  // R2 bucket binding (native — used for list / delete without HTTP overhead)
  FOOTAGE_BUCKET: R2Bucket;
}

// ---------------------------------------------------------------------------
// JWT payload shape
// ---------------------------------------------------------------------------
export interface JwtPayload {
  sub: string;       // user id
  email: string;
  role: UserRole;
  iat?: number;
  exp?: number;
}

// ---------------------------------------------------------------------------
// Domain types (mirror Flutter models)
// ---------------------------------------------------------------------------
export type UserRole = 'resident' | 'security' | 'admin';
export type PassType = 'qr' | 'otp';
export type PassStatus = 'active' | 'used' | 'expired' | 'revoked';
export type CameraStatus = 'online' | 'offline' | 'maintenance';
export type Priority = 'low' | 'medium' | 'high' | 'urgent';

export interface DbUser {
  id: string;
  email: string;
  password_hash: string;
  full_name: string;
  phone: string;
  role: UserRole;
  unit_number: string;
  id_number: string | null;
  vehicle_registration: string | null;
  avatar_url: string | null;
  is_verified: boolean;
  is_active: boolean;
  last_login_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface DbPass {
  id: string;
  resident_id: string;
  visitor_name: string;
  visitor_phone: string;
  pass_type: PassType;
  token: string;
  status: PassStatus;
  expires_at: string;
  vehicle_registration: string | null;
  purpose: string | null;
  max_uses: number;
  use_count: number;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

// ---------------------------------------------------------------------------
// Hono context variable type (set by auth middleware)
// ---------------------------------------------------------------------------
export interface Variables {
  user: JwtPayload;
}
