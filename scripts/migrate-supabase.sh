#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - SUPABASE MIGRATION AUTOMATION SCRIPT
# ==============================================================================
# This script automates migrating databases and storage assets from hosted
# Supabase to the self-hosted NEOS Platform Compatibility Layer.
#
# Prerequisites:
#   1. Remote Supabase DB credentials and S3 credentials.
#   2. Local NEOS platform is bootstrapped and running.
#   3. 'mc' (MinIO client) is installed locally on the host.

set -e
set -o pipefail

# 1. Load local environment configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$REPO_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    source <(tr -d '\r' < "$ENV_FILE")
    set +a
else
    echo "ERROR: .env file not found at $ENV_FILE. Cannot run migration."
    exit 1
fi

# 2. Require input parameters
echo "=== NEOS Platform - Supabase Migration Utility ==="
read -p "Enter Remote Supabase DB Host (e.g. db.xxx.supabase.co): " REMOTE_HOST
read -p "Enter Remote Supabase DB Password: " -s REMOTE_PASS
echo
read -p "Enter Remote Supabase S3 Access Key ID: " REMOTE_S3_KEY
read -p "Enter Remote Supabase S3 Secret Access Key: " -s REMOTE_S3_SECRET
echo

if [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_PASS" ] || [ -z "$REMOTE_S3_KEY" ] || [ -z "$REMOTE_S3_SECRET" ]; then
    echo "ERROR: All parameters are required to proceed."
    exit 1
fi

TEMP_DIR="/tmp/supabase_migrate_$(date +%s)"
mkdir -p "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

# ------------------------------------------------------------------------------
# Phase A: Database Schema and Data Migration
# ------------------------------------------------------------------------------
echo "--- Step 1: Exporting Schema & Data from Remote Supabase ---"
# Dump remote database (Postgres schema and public content)
export PGPASSWORD="$REMOTE_PASS"
pg_dump -h "$REMOTE_HOST" -U postgres -d postgres \
  --clean --if-exists --no-owner --no-privileges \
  --exclude-schema="auth" --exclude-schema="storage" \
  | gzip > "$TEMP_DIR/supabase_db_dump.sql.gz"
echo "  [PASS] Remote database dumped successfully."

echo "--- Step 2: Preparing Local Database Targets ---"
# Ensure supabase compat SQL script was executed and roles/extensions are loaded
echo "  Provisions target local database tables..."
docker exec -t neos_postgres psql -U postgres -c "CREATE DATABASE neos_app OWNER neos_app_user;" || echo "neos_app DB already exists."

echo "--- Step 3: Importing Schema and Data into local PostgreSQL ---"
# Import schema into local database
gunzip -c "$TEMP_DIR/supabase_db_dump.sql.gz" \
  | docker exec -i neos_postgres psql -U postgres -d neos_app >/dev/null
echo "  [PASS] Database migration imported successfully."

# ------------------------------------------------------------------------------
# Phase B: Object Storage Migration
# ------------------------------------------------------------------------------
echo "--- Step 4: Mirroring File Assets to Local MinIO ---"

# Set up local MinIO client configurations
if ! command -v mc &> /dev/null; then
    echo "Warning: MinIO client 'mc' is not installed on the host. Downloading mc tool..."
    curl -s -o "$TEMP_DIR/mc" https://dl.min.dev/client/mc/release/linux-amd64/mc
    chmod +x "$TEMP_DIR/mc"
    MC_CMD="$TEMP_DIR/mc"
else
    MC_CMD="mc"
fi

# Configure MinIO CLI aliases
echo "  Configuring S3 aliases..."
$MC_CMD alias set remote_supabase "https://${REMOTE_HOST%%.*}.supabase.co/storage/v1/s3" "$REMOTE_S3_KEY" "$REMOTE_S3_SECRET" --api s3v4
$MC_CMD alias set local_minio "http://localhost:9000" neos_storage_admin "${MINIO_ROOT_PASSWORD}"

# Mirror remote buckets to local target
echo "  Mirroring file uploads (copying objects)..."
$MC_CMD mirror remote_supabase/supabase-bucket local_minio/supabase-storage

echo "=========================================================================="
echo ">>> [SUCCESS] Supabase Platform Migration completed successfully!"
echo "    Databases, schemas, and S3 file buckets are active on the private VPS."
echo "=========================================================================="
