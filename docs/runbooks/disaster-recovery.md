# Disaster Recovery & Rollback Operations Runbook

This document details the step-by-step procedures for disaster recovery, data decryption, manual database restorations, and application rollback management on the NEOS Platform.

---

## 1. Disaster Recovery Scenarios

### Scenario A: Complete Host Node VPS Loss
If the KVM2 VPS experiences complete hardware failure:
1. Provision a new Ubuntu 24.04 LTS VPS instance.
2. Clone the single source of truth repository:
   ```bash
   git clone https://github.com/nasimhwb/neos-platform.git /srv/neos/neos-platform
   ```
3. Run the bootstrap scripts to install Docker, establish firewalls, and create directories:
   ```bash
   cd /srv/neos/neos-platform/bootstrap
   ./install.sh
   ```
4. Restore repository configurations and `.env` credentials file from offsite backups.
5. Fetch the latest encrypted backup package (`neos_backup_*.tar.gz.gpg`) and download it to `/srv/neos/shared/backups/`.
6. Run the restoration engine (this decrypts, unpacks, and restores PostgreSQL, Redis, and MinIO storage volumes):
   ```bash
   cd /srv/neos/neos-platform/backups
   ./restore.sh --force /srv/neos/shared/backups/neos_backup_latest.tar.gz.gpg
   ```
7. Start all application stacks:
   ```bash
   make up
   ```

### Scenario B: Database Corruptions / Data Loss
If a specific database schema becomes corrupted (e.g. `neos_erp`):
1. Locate the latest backup file `/srv/neos/shared/backups/neos_backup_YYYY-MM-DD_HHMMSS.tar.gz.gpg`.
2. Extract and decrypt the individual database file manually:
   ```bash
   # Decrypt package
   gpg --decrypt --batch --yes --passphrase "$BACKUP_PASSPHRASE" --output /tmp/backup.tar.gz /srv/neos/shared/backups/neos_backup_XXXX.tar.gz.gpg
   
   # Extract individual postgres dump
   tar -xzf /tmp/backup.tar.gz -C /tmp/ --strip-components=1
   ```
3. Re-import only the target database:
   ```bash
   # Terminate database connections
   docker exec -t neos_postgres psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'neos_erp' AND pid <> pg_backend_pid();"
   
   # Recreate database
   docker exec -t neos_postgres psql -U postgres -c "DROP DATABASE IF EXISTS neos_erp;"
   docker exec -t neos_postgres psql -U postgres -c "CREATE DATABASE neos_erp OWNER erp_user;"
   
   # Import sql dump
   gunzip -c /tmp/backup_*/postgres_neos_erp.sql.gz | docker exec -i neos_postgres psql -U postgres -d neos_erp
   ```

---

## 2. Application & Database Rollbacks

### Step 1: Code and Stack Rollback
If an application deployment (e.g. ERP v2.0) introduces bugs, roll back the code stack:
1. Revert to a stable git revision:
   ```bash
   # Find stable commit hash in Git history
   git log --oneline
   
   # Check out stable commit
   git checkout <stable_commit_hash>
   ```
2. Pull images and restart the stack:
   ```bash
   make down
   make up
   ```

### Step 2: Database State Rollback
If the database schema was migrated and needs to be rolled back to match the older application code:
1. Locate the backup package generated *immediately prior* to the deployment.
2. Execute the targeted database restore steps described in **Section 1 (Scenario B)** above.
3. Validate database compatibility by checking application health:
   ```bash
   curl -f https://erp.neos-platform.local/health
   ```
4. Verify that caching engines (Redis) are synchronized:
   * If Redis contains obsolete cached objects from the corrupted release, flush the cache:
     ```bash
     docker exec -it neos_redis redis-cli -a "$REDIS_PASSWORD" FLUSHALL
     ```
