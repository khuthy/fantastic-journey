#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# setup-r2.sh — provision Cloudflare R2 buckets and configure CORS + secrets
#
# Prerequisites:
#   • wrangler installed (npm i -g wrangler)
#   • Logged in: wrangler login
#   • A .dev.vars file with R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY
#
# Usage:
#   bash scripts/setup-r2.sh            # production bucket
#   bash scripts/setup-r2.sh --staging  # staging bucket
#   bash scripts/setup-r2.sh --dev      # dev bucket
# ---------------------------------------------------------------------------

set -euo pipefail

PROD_BUCKET="protea-glen-footage"
STAGING_BUCKET="protea-glen-footage-staging"
DEV_BUCKET="protea-glen-footage-dev"
CORS_FILE="$(dirname "$0")/../r2-cors.json"

ENV_FLAG="${1:-}"

# Determine target bucket
if [[ "$ENV_FLAG" == "--staging" ]]; then
  BUCKET="$STAGING_BUCKET"
  WORKER_ENV="--env staging"
  echo "▶ Target environment: staging"
elif [[ "$ENV_FLAG" == "--dev" ]]; then
  BUCKET="$DEV_BUCKET"
  WORKER_ENV="--env dev"
  echo "▶ Target environment: dev"
else
  BUCKET="$PROD_BUCKET"
  WORKER_ENV=""
  echo "▶ Target environment: production"
fi

# ---------------------------------------------------------------------------
# 1. Create R2 bucket (idempotent — wrangler r2 bucket create is safe to re-run)
# ---------------------------------------------------------------------------
echo ""
echo "1/4  Creating R2 bucket: $BUCKET"
wrangler r2 bucket create "$BUCKET" || echo "  (bucket may already exist — continuing)"

# ---------------------------------------------------------------------------
# 2. Apply CORS policy
# ---------------------------------------------------------------------------
echo ""
echo "2/4  Applying CORS policy from r2-cors.json"
wrangler r2 bucket cors put "$BUCKET" --rules "$(cat "$CORS_FILE")"

# ---------------------------------------------------------------------------
# 3. Create KV namespace for rate-limiting (if not done yet)
# ---------------------------------------------------------------------------
echo ""
echo "3/4  Creating KV namespace for rate-limiting"
echo "     (copy the output ID into wrangler.toml → kv_namespaces.id)"
wrangler kv namespace create "RATE_LIMIT_KV" $WORKER_ENV || echo "  (namespace may already exist)"

# ---------------------------------------------------------------------------
# 4. Push secrets to the Worker
# ---------------------------------------------------------------------------
echo ""
echo "4/4  Pushing Worker secrets"
echo "     You will be prompted for each value. Press Ctrl-C to skip any."
echo ""

for SECRET in \
  DATABASE_URL \
  JWT_SECRET \
  JWT_REFRESH_SECRET \
  R2_ACCESS_KEY_ID \
  R2_SECRET_ACCESS_KEY \
  R2_BUCKET_NAME \
  R2_ACCOUNT_ID
do
  echo -n "  $SECRET: "
  wrangler secret put "$SECRET" $WORKER_ENV
done

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "✓ Setup complete for bucket: $BUCKET"
echo ""
echo "Next steps:"
echo "  1. Update wrangler.toml → kv_namespaces.id with the KV namespace ID printed above"
echo "  2. Run the database migration: DATABASE_URL='...' node scripts/migrate.js"
echo "  3. Seed the first admin: DATABASE_URL='...' node scripts/seed-admin.js"
echo "  4. Deploy the Worker: wrangler deploy $WORKER_ENV"
