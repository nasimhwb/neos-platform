#!/bin/bash
# ==============================================================================
# NEOS PLATFORM - BACKUP INTEGRITY VERIFICATION TOOL
# ==============================================================================
# Finds the latest backup file and tests its structural validity.
# Usage: ./verify-backup.sh [path_to_backup_archive.tar.gz]

set -e
set -o pipefail

BACKUP_DIR="/srv/neos/shared/backups"
TARGET_ARCHIVE=""

# 1. Determine target archive
if [ $# -eq 1 ]; then
    TARGET_ARCHIVE="$1"
else
    echo "No backup archive specified. Searching for latest backup in $BACKUP_DIR..."
    TARGET_ARCHIVE=$(ls -1t "$BACKUP_DIR"/neos_backup_*.tar.gz 2>/dev/null | head -n 1 || true)
fi

if [ -z "$TARGET_ARCHIVE" ] || [ ! -f "$TARGET_ARCHIVE" ]; then
    echo "ERROR: No backup archive file found to verify."
    exit 1
fi

echo "=========================================================================="
echo "Verifying backup archive: $TARGET_ARCHIVE"
echo "File Size: $(du -sh "$TARGET_ARCHIVE" | awk '{print $1}')"
echo "=========================================================================="

# 2. Check tar integrity
echo "1. Checking archive compression structural integrity..."
if ! tar -tzf "$TARGET_ARCHIVE" &>/dev/null; then
    echo ">>> ERROR: Backup archive is corrupted or invalid."
    exit 1
fi
echo "   [PASS] Archive is structurally valid."

# 3. Create temp workspace for inspection
TEMP_WORK_DIR="/tmp/verify_backup_$(date +%s)"
mkdir -p "$TEMP_WORK_DIR"
trap 'rm -rf "$TEMP_WORK_DIR"' EXIT

# Extract archive
echo "2. Unpacking archive contents to workspace..."
tar -xzf "$TARGET_ARCHIVE" -C "$TEMP_WORK_DIR" --strip-components=1

# Get inside the session directory name (e.g. backup_2026-07-06_203810)
SESSION_DIR=$(find "$TEMP_WORK_DIR" -maxdepth 1 -type d -name "backup_*" | head -n 1)

if [ -z "$SESSION_DIR" ]; then
    echo ">>> ERROR: Extracted contents are missing standard 'backup_YYYY-MM-DD_HHMMSS' session root."
    exit 1
fi

# 4. Verify presence of required assets
echo "3. Auditing nested components..."

FAILED=0

# Verify Postgres Dumps
PG_DUMPS=$(find "$SESSION_DIR" -name "postgres_*.sql.gz" | wc -l)
if [ "$PG_DUMPS" -eq 0 ]; then
    echo "   [FAIL] PostgreSQL database dumps are missing!"
    FAILED=1
else
    echo "   [PASS] PostgreSQL database dumps: $PG_DUMPS file(s) found."
fi

# Verify Redis Snapshot (RDB)
if [ ! -f "$SESSION_DIR/redis_dump.rdb" ]; then
    echo "   [FAIL] Redis cache 'redis_dump.rdb' is missing!"
    FAILED=1
else
    echo "   [PASS] Redis state 'redis_dump.rdb' found."
fi

# Verify Redis Journaling (AOF)
if [ ! -d "$SESSION_DIR/redis_appendonlydir" ]; then
    echo "   [WARN] Redis journaling 'redis_appendonlydir' is missing (AOF was disabled or empty)."
else
    echo "   [PASS] Redis journaling 'redis_appendonlydir' found."
fi

# Verify MinIO Storage Tarball
if [ ! -f "$SESSION_DIR/minio_data.tar.gz" ]; then
    echo "   [FAIL] MinIO object storage 'minio_data.tar.gz' is missing!"
    FAILED=1
else
    echo "   [PASS] MinIO object storage 'minio_data.tar.gz' found."
fi

# Verify Configuration files
if [ ! -f "$SESSION_DIR/configs.tar.gz" ]; then
    echo "   [FAIL] Repository configurations 'configs.tar.gz' is missing!"
    FAILED=1
else
    echo "   [PASS] Repository configurations 'configs.tar.gz' found."
fi

# Verify SSL Certificates
if [ ! -f "$SESSION_DIR/ssl_certs.tar.gz" ]; then
    echo "   [WARN] SSL certificates 'ssl_certs.tar.gz' is missing."
else
    echo "   [PASS] SSL certificates 'ssl_certs.tar.gz' found."
fi

# 5. Output Verification report
echo "=========================================================================="
if [ "$FAILED" -eq 1 ]; then
    echo ">>> [FAILURE] Backup verification failed. Some critical assets are missing."
    exit 1
else
    echo ">>> [SUCCESS] Backup integrity and structure successfully verified!"
    echo "    Archive is ready and complete for recovery operations."
fi
echo "=========================================================================="
