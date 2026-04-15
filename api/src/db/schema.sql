-- =============================================================================
-- Protea Glen Gate Access — Neon Postgres Schema
-- Run this against your Neon project via the Neon console SQL editor or psql.
-- =============================================================================

-- Enable pgcrypto for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =============================================================================
-- USERS
-- =============================================================================
CREATE TABLE IF NOT EXISTS users (
  id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  email               VARCHAR(255) UNIQUE NOT NULL,
  password_hash       TEXT         NOT NULL,
  full_name           VARCHAR(255) NOT NULL,
  phone               VARCHAR(50)  NOT NULL,
  role                VARCHAR(20)  NOT NULL DEFAULT 'resident'
                        CHECK (role IN ('resident', 'security', 'admin')),
  unit_number         VARCHAR(50)  NOT NULL,
  id_number           VARCHAR(50),
  vehicle_registration VARCHAR(50),
  avatar_url          TEXT,
  is_verified         BOOLEAN      NOT NULL DEFAULT FALSE,
  is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
  last_login_at       TIMESTAMPTZ,
  created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_users_role  ON users (role);

-- =============================================================================
-- REFRESH TOKENS
-- =============================================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  token_hash TEXT        NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens (user_id);

-- Auto-delete expired tokens (Neon supports pg_cron or you can run a cleanup job)
-- Example: DELETE FROM refresh_tokens WHERE expires_at < NOW();

-- =============================================================================
-- VISITOR PASSES
-- =============================================================================
CREATE TABLE IF NOT EXISTS visitor_passes (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  resident_id          UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  visitor_name         VARCHAR(255) NOT NULL,
  visitor_phone        VARCHAR(50)  NOT NULL,
  pass_type            VARCHAR(10)  NOT NULL CHECK (pass_type IN ('qr', 'otp')),
  token                TEXT        NOT NULL UNIQUE,
  -- token is the QR payload (UUID) or the 6-digit OTP
  status               VARCHAR(20) NOT NULL DEFAULT 'active'
                         CHECK (status IN ('active', 'used', 'expired', 'revoked')),
  expires_at           TIMESTAMPTZ NOT NULL,
  vehicle_registration VARCHAR(50),
  purpose              TEXT,
  max_uses             INTEGER     NOT NULL DEFAULT 1 CHECK (max_uses BETWEEN 1 AND 10),
  use_count            INTEGER     NOT NULL DEFAULT 0,
  notes                TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_passes_resident_id ON visitor_passes (resident_id);
CREATE INDEX IF NOT EXISTS idx_passes_token       ON visitor_passes (token);
CREATE INDEX IF NOT EXISTS idx_passes_status      ON visitor_passes (status);
CREATE INDEX IF NOT EXISTS idx_passes_expires_at  ON visitor_passes (expires_at);

-- =============================================================================
-- ENTRY LOG
-- =============================================================================
CREATE TABLE IF NOT EXISTS entry_log (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  pass_id              UUID        REFERENCES visitor_passes (id) ON DELETE SET NULL,
  visitor_name         VARCHAR(255) NOT NULL,
  visitor_phone        VARCHAR(50),
  resident_id          UUID        REFERENCES users (id) ON DELETE SET NULL,
  resident_unit        VARCHAR(50),
  guard_id             UUID        REFERENCES users (id) ON DELETE SET NULL,
  vehicle_registration VARCHAR(50),
  pass_type            VARCHAR(10),
  success              BOOLEAN     NOT NULL DEFAULT TRUE,
  failure_reason       TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_entry_log_created_at   ON entry_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_entry_log_resident_id  ON entry_log (resident_id);
CREATE INDEX IF NOT EXISTS idx_entry_log_pass_id      ON entry_log (pass_id);

-- =============================================================================
-- ANNOUNCEMENTS
-- =============================================================================
CREATE TABLE IF NOT EXISTS announcements (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title        VARCHAR(255) NOT NULL,
  body         TEXT        NOT NULL,
  author_id    UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  author_name  VARCHAR(255) NOT NULL,
  priority     VARCHAR(20) NOT NULL DEFAULT 'medium'
                 CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  expires_at   TIMESTAMPTZ,
  image_url    TEXT,
  is_pinned    BOOLEAN     NOT NULL DEFAULT FALSE,
  target_roles TEXT[],     -- NULL = all roles; e.g. ARRAY['resident','security']
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON announcements (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_is_pinned  ON announcements (is_pinned);

-- =============================================================================
-- CAMERAS
-- =============================================================================
CREATE TABLE IF NOT EXISTS cameras (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name             VARCHAR(255) NOT NULL,
  location         VARCHAR(50)  NOT NULL,
  stream_url       TEXT        NOT NULL,
  status           VARCHAR(20) NOT NULL DEFAULT 'online'
                     CHECK (status IN ('online', 'offline', 'maintenance')),
  thumbnail_url    TEXT,
  last_footage_key TEXT,             -- Most recent R2 object key
  last_online_at   TIMESTAMPTZ,
  ip_address       VARCHAR(50),
  model            VARCHAR(100),
  is_recording     BOOLEAN     NOT NULL DEFAULT FALSE,
  r2_bucket_path   TEXT,
  installed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- FOOTAGE RECORDS
-- =============================================================================
CREATE TABLE IF NOT EXISTS footage_records (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  camera_id        UUID        NOT NULL REFERENCES cameras (id) ON DELETE CASCADE,
  r2_key           TEXT        NOT NULL UNIQUE,   -- e.g. cameras/cam1/2024-01-01/120000.mp4
  start_time       TIMESTAMPTZ NOT NULL,
  end_time         TIMESTAMPTZ NOT NULL,
  file_size_bytes  BIGINT      NOT NULL DEFAULT 0,
  thumbnail_key    TEXT,
  duration_seconds INTEGER,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_footage_camera_id   ON footage_records (camera_id);
CREATE INDEX IF NOT EXISTS idx_footage_start_time  ON footage_records (start_time DESC);

-- =============================================================================
-- HELPER FUNCTION: update updated_at on every mutation
-- =============================================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Attach trigger to each table that has updated_at
DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['users','visitor_passes','announcements','cameras']
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_set_updated_at ON %I;
       CREATE TRIGGER trg_set_updated_at
         BEFORE UPDATE ON %I
         FOR EACH ROW EXECUTE FUNCTION set_updated_at();',
      t, t
    );
  END LOOP;
END;
$$;

-- =============================================================================
-- SEED: default admin account
-- Password: Admin@12345  (change immediately after first login)
-- The hash below is PBKDF2-SHA256, 100 000 iterations, generated by the API.
-- Replace with a real hash from POST /auth/register or the seed script.
-- =============================================================================
-- INSERT INTO users (email, password_hash, full_name, phone, role, unit_number, is_verified)
-- VALUES (
--   'admin@proteaglen.com',
--   '<run_seed_script_to_get_real_hash>',
--   'Estate Admin',
--   '+27000000000',
--   'admin',
--   'ADMIN',
--   TRUE
-- );
