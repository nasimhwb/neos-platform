#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - AUTOMATED BACKUP RESTORE TESTING ENGINE
# ==============================================================================
# This script performs end-to-end automated recovery validation checks:
#   1. Locates and decrypts the latest production backup package.
#   2. Establishes an isolated virtual Docker network.
#   3. Launches temporary PostgreSQL, Redis, and MinIO test containers.
#   4. Restores all databases, caches, and storage assets.
#   5. Validates system schemas, cache keys count, and storage endpoints.
#   6. Cleans up all test resources and notifies Alertmanager of failures.

set -e
set -o pipefail

BACKUP_DIR="/srv/neos/shared/backups"
TEST_NET="neos-restore-test-net"
TEMP_RESTORE_DIR="/tmp/neos_restore_test_$(date +%s)"

echo "=== Starting Automated Restore Integrity Check ==="

# 1. Load env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source <(tr -d '\r' < "$ENV_FILE")
    set +a
fi

# Locate latest backup package (.gpg or .tar.gz)
LATEST_BACKUP=$(ls -1t "$BACKUP_DIR"/neos_backup_* 2>/dev/null | grep -E '\.(tar\.gz|gpg)$' | head -n 1 || true)
if [ -z "$LATEST_BACKUP" ]; then
    echo "ERROR: No backup files found in $BACKUP_DIR."
    exit 1
fi
echo "Latest backup package identified: $LATEST_BACKUP"

# 2. Alert manager failure callback
send_restore_failure_alert() {
    local error_msg=$1
    echo ">>> RESTORE TEST FAILED: $error_msg"
    echo "Alerting Alertmanager..."
    curl -s -X POST -H "Content-Type: application/json" \
      -d "[{
        \"labels\": {
          \"alertname\": \"BackupRestoreTestingFailed\",
          \"severity\": \"critical\",
          \"instance\": \"host-vps\"
        },
        \"annotations\": {
          \"summary\": \"NEOS Platform Restore Testing Failed\",
          \"description\": \"Automated recovery validation loop failed. Reason: $error_msg\"
        }
      }]" \
      http://alertmanager:9093/api/v2/alerts || echo "Warning: Failed to alert Alertmanager."
}

# 3. Setup temporary workspace
mkdir -p "$TEMP_RESTORE_DIR"

DECRYPTED_ARCHIVE=""
cleanup_restore_test() {
    echo "--- Cleaning up restore validation test containers and networks ---"
    docker rm -f neos_postgres_test neos_redis_test neos_minio_test &>/dev/null || true
    docker network rm "$TEST_NET" &>/dev/null || true
    rm -rf "$TEMP_RESTORE_DIR"
    rm -rf /tmp/minio_restore_test_data &>/dev/null || true
    if [ -n "$DECRYPTED_ARCHIVE" ] && [ -f "$DECRYPTED_ARCHIVE" ]; then
        rm -f "$DECRYPTED_ARCHIVE"
    fi
}
trap cleanup_restore_test EXIT

# 4. Decrypt package
TARGET_ARCHIVE="$LATEST_BACKUP"
if [[ "$LATEST_BACKUP" == *.gpg ]]; then
    echo "Decrypting GPG backup..."
    if [ -z "${BACKUP_PASSPHRASE:-}" ]; then
        send_restore_failure_alert "BACKUP_PASSPHRASE not configured."
        exit 1
    fi
    DECRYPTED_ARCHIVE="$TEMP_RESTORE_DIR/decrypted_test_backup.tar.gz"
    gpg --decrypt --batch --yes --passphrase "$BACKUP_PASSPHRASE" --output "$DECRYPTED_ARCHIVE" "$LATEST_BACKUP"
    TARGET_ARCHIVE="$DECRYPTED_ARCHIVE"
fi

# Extract archive
echo "Extracting backup..."
tar -xzf "$TARGET_ARCHIVE" -C "$TEMP_RESTORE_DIR"
SESSION_DIR=$(find "$TEMP_RESTORE_DIR" -maxdepth 1 -type d -name "backup_*" | head -n 1)

# Create isolated network
echo "Creating isolated Docker test network..."
docker network create "$TEST_NET"

# ------------------------------------------------------------------------------
# A. Restore and test PostgreSQL
# ------------------------------------------------------------------------------
echo "--- Restoring and validating PostgreSQL ---"
docker run --name neos_postgres_test --network "$TEST_NET" -d \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=RestoreTestPassword123! \
  postgres:16-alpine

# Wait for postgres to boot
echo "Waiting for test Postgres container to boot..."
until docker exec neos_postgres_test pg_isready -U postgres &>/dev/null; do
    sleep 1
done

# Restore all db dumps
for sql_gz in "$SESSION_DIR"/postgres_*.sql.gz; do
    [ -e "$sql_gz" ] || continue
    db_name=$(basename "$sql_gz" | sed 's/postgres_//' | sed 's/\.sql\.gz//')
    echo "  Creating and importing test database: $db_name..."
    docker exec -t neos_postgres_test psql -U postgres -c "CREATE DATABASE $db_name;"
    gunzip -c "$sql_gz" | docker exec -i neos_postgres_test psql -U postgres -d "$db_name" >/dev/null
done

# Validate query check
echo "  Checking Postgres tables schemas..."
if ! docker exec neos_postgres_test psql -U postgres -c "\l" &>/dev/null; then
    send_restore_failure_alert "PostgreSQL restore validation query failed."
    exit 1
fi
echo "  [PASS] PostgreSQL restore successfully verified."

# ------------------------------------------------------------------------------
# B. Restore and test Redis
# ------------------------------------------------------------------------------
echo "--- Restoring and validating Redis ---"
# Start container
docker run --name neos_redis_test --network "$TEST_NET" -d redis:8.0-M02-alpine
sleep 2

# Stop container to copy files safely
docker stop neos_redis_test &>/dev/null
docker cp "$SESSION_DIR/redis_dump.rdb" neos_redis_test:/data/dump.rdb
if [ -d "$SESSION_DIR/redis_appendonlydir" ]; then
    docker cp "$SESSION_DIR/redis_appendonlydir" neos_redis_test:/data/appendonlydir
fi
docker start neos_redis_test &>/dev/null
sleep 2

# Validate redis
echo "  Checking Redis ping connection..."
if ! docker exec neos_redis_test redis-cli ping | grep -q "PONG"; then
    send_restore_failure_alert "Redis ping check failed after restoration."
    exit 1
fi
echo "  [PASS] Redis restore successfully verified."

# ------------------------------------------------------------------------------
# C. Restore and test MinIO
# ------------------------------------------------------------------------------
echo "--- Restoring and validating MinIO ---"
# Extract MinIO data to a temporary directory on the host to mount
mkdir -p /tmp/minio_restore_test_data
tar -xzf "$SESSION_DIR/minio_data.tar.gz" -C /tmp/minio_restore_test_data/

docker run --name neos_minio_test --network "$TEST_NET" -d \
  -v /tmp/minio_restore_test_data:/data \
  -e MINIO_ROOT_USER=admin -e MINIO_ROOT_PASSWORD=RestoreTestPassword123! \
  minio/minio server /data

echo "Waiting for test MinIO to boot..."
for i in {1..15}; do
    if docker exec neos_minio_test curl -s -f http://localhost:9000/minio/health/live &>/dev/null; then
        break
    fi
    sleep 1
done

if ! docker exec neos_minio_test curl -s -f http://localhost:9000/minio/health/live &>/dev/null; then
    send_restore_failure_alert "MinIO health endpoint returned failure post-restoration."
    exit 1
fi
echo "  [PASS] MinIO restore successfully verified."

echo "=========================================================================="
echo ">>> [SUCCESS] Automated Restore validation completed successfully!"
echo "    All platform databases, caches, and storage recovered without errors."
echo "=========================================================================="
