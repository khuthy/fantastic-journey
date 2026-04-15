/**
 * Cryptographic helpers — all use Web Crypto, zero dependencies.
 */

/** Generate a cryptographically secure random hex string of `bytes` length. */
export function randomHex(bytes = 32): string {
  const buf = crypto.getRandomValues(new Uint8Array(bytes));
  return [...buf].map((b) => b.toString(16).padStart(2, '0')).join('');
}

/** Generate a random UUID v4. */
export function randomUUID(): string {
  return crypto.randomUUID();
}

/** Generate a 6-digit numeric OTP. */
export function generateOtp(): string {
  // Use getRandomValues for uniform distribution within [0, 900000)
  const buf = new Uint32Array(1);
  crypto.getRandomValues(buf);
  const otp = 100_000 + ((buf[0] ?? 0) % 900_000);
  return otp.toString();
}

/** Generate a QR payload token (URL-safe base64url, 32 bytes of randomness). */
export function generateQrToken(): string {
  const buf = crypto.getRandomValues(new Uint8Array(32));
  // base64url encode (no padding, URL-safe chars)
  return btoa(String.fromCharCode(...buf))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

/**
 * SHA-256 hash a string — used for storing refresh tokens in the DB
 * so the raw token value is never persisted.
 */
export async function sha256(value: string): Promise<string> {
  const buf = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}
