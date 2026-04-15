/**
 * Seed script — creates the initial admin account in Neon Postgres.
 *
 * Usage:
 *   DATABASE_URL="postgres://..." node scripts/seed-admin.js
 *
 * The script uses the same PBKDF2-SHA-256 implementation as the Worker so
 * passwords are stored in a compatible format.
 */

import { createRequire } from 'module';
import { webcrypto } from 'crypto';

// Node 18+ exposes globalThis.crypto; older versions need this shim.
if (!globalThis.crypto) {
  globalThis.crypto = webcrypto;
}

const require = createRequire(import.meta.url);
const { neon } = require('@neondatabase/serverless');

// ---------------------------------------------------------------------------
// PBKDF2 helper (same algorithm as src/lib/password.ts)
// ---------------------------------------------------------------------------
const ITERATIONS = 200_000;
const HASH_BYTES = 32;
const SALT_BYTES = 16;

function buf2hex(buf) {
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function hashPassword(password) {
  const salt = crypto.getRandomValues(new Uint8Array(SALT_BYTES));
  const enc = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey('raw', enc.encode(password), 'PBKDF2', false, ['deriveBits']);
  const hash = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt, iterations: ITERATIONS },
    keyMaterial,
    HASH_BYTES * 8,
  );
  return `pbkdf2$${ITERATIONS}$${buf2hex(salt.buffer)}$${buf2hex(hash)}`;
}

// ---------------------------------------------------------------------------
// Seed
// ---------------------------------------------------------------------------
const ADMIN_EMAIL    = process.env.ADMIN_EMAIL    ?? 'admin@proteaglen.com';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'ChangeMe@1234!';
const ADMIN_NAME     = process.env.ADMIN_NAME     ?? 'Estate Admin';
const ADMIN_PHONE    = process.env.ADMIN_PHONE    ?? '+27000000000';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL environment variable is required.');
  process.exit(1);
}

const sql = neon(process.env.DATABASE_URL);

async function main() {
  console.log(`Seeding admin account: ${ADMIN_EMAIL}`);

  const existing = await sql`SELECT id FROM users WHERE email = ${ADMIN_EMAIL}`;
  if (existing.length > 0) {
    console.log('Admin account already exists — skipping.');
    return;
  }

  const passwordHash = await hashPassword(ADMIN_PASSWORD);

  await sql`
    INSERT INTO users (email, password_hash, full_name, phone, role, unit_number, is_verified, is_active)
    VALUES (${ADMIN_EMAIL}, ${passwordHash}, ${ADMIN_NAME}, ${ADMIN_PHONE}, 'admin', 'ADMIN', TRUE, TRUE)
  `;

  console.log('✓ Admin account created.');
  console.log(`  Email:    ${ADMIN_EMAIL}`);
  console.log(`  Password: ${ADMIN_PASSWORD}`);
  console.log('  ⚠ Change this password immediately after first login!');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
