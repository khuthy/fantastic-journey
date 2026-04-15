import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
  DeleteObjectCommand,
  ListObjectsV2Command,
  type ListObjectsV2CommandInput,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import type { Env } from '../types';

/** R2 exposes an S3-compatible API at this endpoint. */
function r2Endpoint(accountId: string): string {
  return `https://${accountId}.r2.cloudflarestorage.com`;
}

function buildClient(env: Env): S3Client {
  return new S3Client({
    region: 'auto',
    endpoint: r2Endpoint(env.R2_ACCOUNT_ID),
    credentials: {
      accessKeyId: env.R2_ACCESS_KEY_ID,
      secretAccessKey: env.R2_SECRET_ACCESS_KEY,
    },
  });
}

// ---------------------------------------------------------------------------
// Presigned URLs
// ---------------------------------------------------------------------------

export async function presignDownload(
  env: Env,
  key: string,
  expiresInSeconds = 7_200, // 2 hours
): Promise<string> {
  const client = buildClient(env);
  const command = new GetObjectCommand({
    Bucket: env.R2_BUCKET_NAME,
    Key: key,
  });
  return getSignedUrl(client, command, { expiresIn: expiresInSeconds });
}

export async function presignUpload(
  env: Env,
  key: string,
  contentType: string,
  expiresInSeconds = 3_600, // 1 hour
): Promise<string> {
  const client = buildClient(env);
  const command = new PutObjectCommand({
    Bucket: env.R2_BUCKET_NAME,
    Key: key,
    ContentType: contentType,
  });
  return getSignedUrl(client, command, { expiresIn: expiresInSeconds });
}

// ---------------------------------------------------------------------------
// Object management
// ---------------------------------------------------------------------------

export async function deleteObject(env: Env, key: string): Promise<void> {
  const client = buildClient(env);
  await client.send(
    new DeleteObjectCommand({ Bucket: env.R2_BUCKET_NAME, Key: key }),
  );
}

export interface R2Object {
  key: string;
  size: number;
  lastModified: Date | undefined;
}

export async function listObjects(
  env: Env,
  prefix: string,
  maxKeys = 200,
  continuationToken?: string,
): Promise<{ objects: R2Object[]; nextToken?: string }> {
  const client = buildClient(env);
  const input: ListObjectsV2CommandInput = {
    Bucket: env.R2_BUCKET_NAME,
    Prefix: prefix,
    MaxKeys: maxKeys,
    ContinuationToken: continuationToken,
  };
  const result = await client.send(new ListObjectsV2Command(input));
  return {
    objects: (result.Contents ?? []).map((o) => ({
      key: o.Key ?? '',
      size: o.Size ?? 0,
      lastModified: o.LastModified,
    })),
    nextToken: result.NextContinuationToken,
  };
}

// ---------------------------------------------------------------------------
// Key builder (mirrors the Flutter service)
// ---------------------------------------------------------------------------
export function footageKey(cameraId: string, recordedAt: Date, ext = 'mp4'): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  const date = `${recordedAt.getFullYear()}-${pad(recordedAt.getMonth() + 1)}-${pad(recordedAt.getDate())}`;
  const time = `${pad(recordedAt.getHours())}${pad(recordedAt.getMinutes())}${pad(recordedAt.getSeconds())}`;
  return `cameras/${cameraId}/${date}/${time}.${ext}`;
}
