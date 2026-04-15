/**
 * R2 helpers — zero-dependency AWS SigV4 presigner + native R2Bucket binding.
 *
 * Presigned URLs (upload / download):
 *   Built with Web Crypto HMAC-SHA256 — no external SDK, works in any edge
 *   runtime (Cloudflare Workers, Deno, Bun …).
 *
 * List / delete:
 *   Uses the native `FOOTAGE_BUCKET` R2Bucket Worker binding, which is faster,
 *   free of egress charges, and avoids an extra HTTP round-trip.
 */

import type { Env } from '../types';

// ---------------------------------------------------------------------------
// Web-Crypto helpers
// ---------------------------------------------------------------------------

const enc = (s: string): Uint8Array => new TextEncoder().encode(s);

function hex(buf: ArrayBuffer): string {
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

async function sha256Hex(data: string): Promise<string> {
  return hex(await crypto.subtle.digest('SHA-256', enc(data)));
}

async function hmacSha256(key: ArrayBuffer | Uint8Array, data: string): Promise<ArrayBuffer> {
  const k = await crypto.subtle.importKey(
    'raw',
    key,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  return crypto.subtle.sign('HMAC', k, enc(data));
}

/** Derive the SigV4 signing key: kDate → kRegion → kService → kSigning */
async function deriveSigningKey(
  secret: string,
  date: string,
  region: string,
  service: string,
): Promise<ArrayBuffer> {
  const kDate    = await hmacSha256(enc(`AWS4${secret}`), date);
  const kRegion  = await hmacSha256(kDate, region);
  const kService = await hmacSha256(kRegion, service);
  return hmacSha256(kService, 'aws4_request');
}

// ---------------------------------------------------------------------------
// Core SigV4 presigner
// ---------------------------------------------------------------------------

/**
 * Build an AWS SigV4 presigned URL for an R2 object.
 *
 * R2 uses path-style addressing:
 *   https://<accountId>.r2.cloudflarestorage.com/<bucket>/<key>
 */
async function presign(
  method: 'GET' | 'PUT',
  env: Env,
  key: string,
  expiresInSeconds: number,
): Promise<string> {
  const now = new Date();

  // "20240101T120000Z" — AWS datetime format
  const datetime = now
    .toISOString()
    .replace(/[:-]/g, '')
    .replace(/\.\d{3}Z$/, 'Z');
  const date = datetime.slice(0, 8);

  const region  = 'auto';
  const service = 's3';
  const host    = `${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;

  // Path-style: /<bucket>/<key>  — each path segment is individually encoded
  const encodedPath =
    `/${env.R2_BUCKET_NAME}/` + key.split('/').map(encodeURIComponent).join('/');

  const credential    = `${env.R2_ACCESS_KEY_ID}/${date}/${region}/${service}/aws4_request`;
  const signedHeaders = 'host';

  // Query params must be sorted lexicographically (X-Amz-Signature excluded)
  const qps: Array<[string, string]> = [
    ['X-Amz-Algorithm',    'AWS4-HMAC-SHA256'],
    ['X-Amz-Credential',   credential],
    ['X-Amz-Date',         datetime],
    ['X-Amz-Expires',      String(expiresInSeconds)],
    ['X-Amz-SignedHeaders', signedHeaders],
  ];
  qps.sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));

  const canonicalQS = qps
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join('&');

  // Canonical request — body is unsigned for presigned URLs
  const canonicalRequest = [
    method,
    encodedPath,
    canonicalQS,
    `host:${host}\n`,   // canonical headers block (trailing \n required)
    signedHeaders,
    'UNSIGNED-PAYLOAD',
  ].join('\n');

  const stringToSign = [
    'AWS4-HMAC-SHA256',
    datetime,
    `${date}/${region}/${service}/aws4_request`,
    await sha256Hex(canonicalRequest),
  ].join('\n');

  const kSigning  = await deriveSigningKey(env.R2_SECRET_ACCESS_KEY, date, region, service);
  const signature = hex(await hmacSha256(kSigning, stringToSign));

  return `https://${host}${encodedPath}?${canonicalQS}&X-Amz-Signature=${signature}`;
}

// ---------------------------------------------------------------------------
// Presigned URLs (public)
// ---------------------------------------------------------------------------

/**
 * Generate a presigned GET URL for downloading an R2 object.
 * Default expiry: 2 hours (sufficient for HLS/MP4 streaming sessions).
 */
export async function presignDownload(
  env: Env,
  key: string,
  expiresInSeconds = 7_200,
): Promise<string> {
  return presign('GET', env, key, expiresInSeconds);
}

/**
 * Generate a presigned PUT URL for uploading to R2.
 * `contentType` is accepted for API compatibility but not signed, so the
 * client may send any content-type without the URL becoming invalid.
 * Default expiry: 1 hour.
 */
export async function presignUpload(
  env: Env,
  key: string,
  _contentType: string,
  expiresInSeconds = 3_600,
): Promise<string> {
  return presign('PUT', env, key, expiresInSeconds);
}

// ---------------------------------------------------------------------------
// Native R2 binding — list / delete (public)
// ---------------------------------------------------------------------------

export interface R2Object {
  key: string;
  size: number;
  lastModified: Date;
}

/**
 * List objects in the R2 bucket using the native Worker binding.
 * Returns at most `maxKeys` results and a cursor for the next page.
 */
export async function listObjects(
  env: Env,
  prefix: string,
  maxKeys = 200,
  cursor?: string,
): Promise<{ objects: R2Object[]; nextToken?: string }> {
  const result = await env.FOOTAGE_BUCKET.list({
    prefix,
    limit: maxKeys,
    ...(cursor ? { cursor } : {}),
  });

  return {
    objects: result.objects.map((o) => ({
      key:          o.key,
      size:         o.size,
      lastModified: o.uploaded,
    })),
    nextToken: result.truncated ? result.cursor : undefined,
  };
}

/**
 * Delete a single object from R2 using the native Worker binding.
 */
export async function deleteObject(env: Env, key: string): Promise<void> {
  await env.FOOTAGE_BUCKET.delete(key);
}

// ---------------------------------------------------------------------------
// Key builder (mirrors r2_storage_service.dart on the Flutter side)
// ---------------------------------------------------------------------------

export function footageKey(cameraId: string, recordedAt: Date, ext = 'mp4'): string {
  const pad  = (n: number) => String(n).padStart(2, '0');
  const d    = recordedAt;
  const date = `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
  const time = `${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
  return `cameras/${cameraId}/${date}/${time}.${ext}`;
}
