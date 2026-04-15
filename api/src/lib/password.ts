/**
 * Password hashing using PBKDF2-SHA-256 via the Web Crypto API.
 *
 * Web Crypto is available in both Cloudflare Workers and modern browsers,
 * so this module has zero external dependencies.
 *
 * Format stored in DB:  pbkdf2$<iterations>$<hex-salt>$<hex-hash>
 */

const ITERATIONS = 200_000;
const HASH_BYTES = 32;   // 256 bits
const SALT_BYTES = 16;   // 128 bits

function buf2hex(buf: ArrayBuffer): string {
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

function hex2buf(hex: string): Uint8Array {
  const arr = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    arr[i / 2] = parseInt(hex.slice(i, i + 2), 16);
  }
  return arr;
}

async function deriveKey(password: string, salt: Uint8Array, iterations: number): Promise<ArrayBuffer> {
  const enc = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    enc.encode(password),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  return crypto.subtle.deriveBits(
    { name: 'PBKDF2', hash: 'SHA-256', salt, iterations },
    keyMaterial,
    HASH_BYTES * 8,
  );
}

/** Hash a plaintext password.  Returns a storable string. */
export async function hashPassword(password: string): Promise<string> {
  const salt = crypto.getRandomValues(new Uint8Array(SALT_BYTES));
  const hash = await deriveKey(password, salt, ITERATIONS);
  return `pbkdf2$${ITERATIONS}$${buf2hex(salt.buffer)}$${buf2hex(hash)}`;
}

/**
 * Verify a plaintext password against a stored hash string.
 * Uses a constant-time comparison to prevent timing attacks.
 */
export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const parts = stored.split('$');
  if (parts.length !== 4 || parts[0] !== 'pbkdf2') return false;

  const [, iterStr, saltHex, hashHex] = parts as [string, string, string, string];
  const iterations = parseInt(iterStr, 10);
  const salt = hex2buf(saltHex);
  const expected = hex2buf(hashHex);

  const derived = new Uint8Array(await deriveKey(password, salt, iterations));

  // Constant-time compare
  if (derived.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < derived.length; i++) {
    diff |= (derived[i] ?? 0) ^ (expected[i] ?? 0);
  }
  return diff === 0;
}
