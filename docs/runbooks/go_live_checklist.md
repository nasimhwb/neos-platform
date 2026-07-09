# NEOS Platform - Production Go-Live Checklist & Hardening Report

This document compiles the SRE hardening report, operational checklist, disaster recovery verification steps, and provider adapter specifications to prepare the NEOS Platform for production go-live.

---

## 1. Production Hardening Report

The shared infrastructure has been successfully hardened and audited for production deployment. The table below details the improvements implemented:

| Category | Hardening Measure | Implementation Detail | Status |
| :--- | :--- | :--- | :---: |
| **Execution Safety** | Cron Overlap Prevention | Upgraded [backups/backup.sh](file:///d:/Webapp/KVM2_SWB/backups/backup.sh) to use kernel-level `flock` on file descriptor `9`. Prevents race conditions and is fully reboot-safe (locks are automatically released by the kernel). | **PASS** |
| **Upload Integrity** | Checksum Verification | [backups/offsite_sync.sh](file:///d:/Webapp/KVM2_SWB/backups/offsite_sync.sh) calculates SHA256 hashes locally and verifies remote integrity via `rclone hash sha256` after upload. Falls back to size-based verification if unsupported. | **PASS** |
| **System Stability** | Storage Leak Prevention | If the backup or offsite sync fails, a safe cleanup handler immediately unlinks partial local archives (`/srv/neos/shared/backups/tmp`) and remote invalid files. | **PASS** |
| **Host Sustainability** | Log Rotation & Retention | Configured host log rotation under `/etc/logrotate.d/neos-platform` to daily rotate backup/system logs under `/srv/neos/shared/logs/**/*.log` with 14-day retention and gzip compression. | **PASS** |
| **Visibility** | Execution Metadata Report | Generates SRE metadata JSON (`/srv/neos/shared/reports/latest_backup.json`) tracking start time, end time, duration, status, archive size, checksum status, and offsite status. | **PASS** |
| **Visibility** | Dashboard Integration | Exposes the latest run metadata via `/api/backups/health` and displays real-time backup system status on the main dashboard Landing Page. | **PASS** |
| **Alerting** | Granular failure alerts | Direct HTTP hooks to Alertmanager report: `BackupLockStale` (lock age > 4h), `BackupSystemFailed` (execution errors), `BackupTimeout` (command timeout), and `BackupChecksumMismatch`/`BackupSizeMismatch` (sync failures). | **PASS** |
| **Code Hygiene** | Path Consistency | Removed all local IDE hardcoded paths (`C:/Users/Admin/...`) from execution scripts, replacing them with standard VPS folders (`/srv/neos/shared/reports/`) and environment-aware overrides. | **PASS** |

---

## 2. Master Go-Live Operational Checklist

Follow these steps on the host VPS prior to traffic routing:

### Step 1: Environmental Credentials Audit
- [ ] Verify that the production `.env` configuration file exists at `/srv/neos/shared/.env`.
- [ ] Confirm that `POSTGRES_SUPERUSER_PASSWORD` and `REDIS_PASSWORD` are changed from default values to cryptographically random passwords.
- [ ] Confirm that `BACKUP_PASSPHRASE` is set to a secure symmetric encryption key for GnuPG.
- [ ] Verify that `RCLONE_REMOTE_NAME` and `RCLONE_BUCKET_NAME` match the configured offsite backup destination.

### Step 2: Offsite Storage Target Setup
- [ ] Run the interactive config tool on the host to authenticate rclone:
  ```bash
  rclone config
  ```
- [ ] Test communication with the remote bucket:
  ```bash
  rclone lsd ${RCLONE_REMOTE_NAME}:
  ```

### Step 3: Platform Bootstrap & Health Check
- [ ] Run the bootstrap master initializer to register cron jobs, configure log rotation, and establish host firewalls:
  ```bash
  make bootstrap
  ```
- [ ] Deploy the core container stacks:
  ```bash
  make up
  ```
- [ ] Execute the diagnostic engine to confirm all services (database, cache, ingress proxy, storage, monitoring) are running within limits:
  ```bash
  make doctor
  ```

---

## 3. Disaster Recovery & Restoration Verification Checklist

To verify that the disaster recovery runbooks are functional, execute the following drills:

### Drill 1: Automated Verification Loop
Run the validation engine on the host VPS:
```bash
make validate-backups
```
- [ ] Confirm that `backups/backup.sh` successfully creates an encrypted archive.
- [ ] Confirm that `backups/verify-backup.sh` reports `[SUCCESS] Backup integrity and structure successfully verified!`.
- [ ] Confirm that `backups/test-restore.sh` successfully spins up test containers on `neos-restore-test-net` and restores/queries Postgres, Redis, and MinIO databases.
- [ ] Confirm that a markdown report is successfully generated at `/srv/neos/shared/reports/backup_verification_report.md`.

### Drill 2: Manual Single Database Recovery Drill
To test manual selective restore (Scenario B in DR Runbook):
- [ ] Obtain the latest GPG encrypted archive name from `/srv/neos/shared/backups/`.
- [ ] Decrypt the package:
  ```bash
  gpg --decrypt --batch --yes --passphrase "$BACKUP_PASSPHRASE" --output /tmp/test_backup.tar.gz /srv/neos/shared/backups/neos_backup_XXXX.tar.gz.gpg
  ```
- [ ] Extract the target Postgres dump file:
  ```bash
  tar -xzf /tmp/test_backup.tar.gz -C /tmp/ --strip-components=1
  ```
- [ ] Confirm that the `.sql.gz` dump can be decompressed and examined.

---

## 4. Cloud Provider Interface & Swap Guidelines

To ensure the storage sync engine remains provider-agnostic, the pipeline delegates offsite uploads to `backups/offsite_sync.sh` (which wraps `rclone`).

### 4.1 Interface Specification
Any offsite sync script must adhere to this interface contract:
1. **Source**: Must locate the newest archive matching `/srv/neos/shared/backups/neos_backup_*` (either `.tar.gz` or `.tar.gz.gpg`).
2. **Transfer**: Must push both the archive and the `.sha256` checksum file to the cloud target.
3. **Audit**: Must verify remote file integrity against the local hash using the cloud provider's API.
4. **Cleanup**: On mismatch, must delete the corrupted file from the cloud target and exit with code `1`.
5. **Success**: On success, must exit with code `0`.

### 4.2 Swapping Cloud Storage Targets
To switch to a different cloud provider (e.g. WASABI, AWS S3, Cloudflare R2):
- Set up a new remote in `rclone` (`rclone config`).
- Update `RCLONE_REMOTE_NAME` and `RCLONE_BUCKET_NAME` in `/srv/neos/shared/.env`.
- No code changes are required in the backup scripts.

### 4.3 Swapping Sync Utilities
To replace `rclone` with a custom CLI tool (such as `aws s3` CLI or `azcopy`):
- Author a script (e.g., `backups/custom_sync.sh`) implementing the contract in **Section 4.1**.
- Replace the execution call in [backups/backup.sh](file:///d:/Webapp/KVM2_SWB/backups/backup.sh) (line 230) to point to the new custom sync script.
