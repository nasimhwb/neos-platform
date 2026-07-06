# Neos Platform Shared Infrastructure - Disaster Recovery (DR) Plan

This document outlines the procedures for recovering the Neos Platform shared infrastructure in the event of data corruption, system failure, or total hardware loss.

## Recovery Objectives

- **Recovery Point Objective (RPO)**: 24 hours (maximum age of backup data to be lost under standard cron configurations).
- **Recovery Time Objective (RTO)**: 
  - Service/Container Crash: < 5 minutes.
  - Database Corruption: < 15 minutes.
  - Complete Host Loss: < 1 hour (assuming a clean VPS is provisioned).

---

## Scenario A: Database Corruption (PostgreSQL)

If a database (e.g. `neos_erp`) becomes corrupted or a bad migration is run, restore that specific database without disrupting others.

### Recovery Procedure
1. Locate the latest backup archive in `/srv/neos/backups/`.
2. Extract the archive in a temporary folder to locate the specific database file:
   ```bash
   tar -zxvf /srv/neos/backups/neos_backup_YYYY-MM-DD_HHMMSS.tar.gz -C /tmp/
   ```
3. Locate the target dump: `/tmp/backup_YYYY-MM-DD_HHMMSS/postgres_neos_erp.sql.gz`.
4. Stop active connections to the target database:
   ```bash
   docker exec -it neos_postgres psql -U postgres -c \
     "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'neos_erp' AND pid <> pg_backend_pid();"
   ```
5. Drop and recreate the database:
   ```bash
   docker exec -it neos_postgres psql -U postgres -c "DROP DATABASE neos_erp;"
   # The user owner is 'erp_user'
   docker exec -it neos_postgres psql -U postgres -c "CREATE DATABASE neos_erp OWNER erp_user;"
   ```
6. Restore the database dump:
   ```bash
   gunzip -c /tmp/backup_YYYY-MM-DD_HHMMSS/postgres_neos_erp.sql.gz | docker exec -i neos_postgres psql -U postgres -d neos_erp
   ```
7. Verify application connection and clean up `/tmp/` files.

---

## Scenario B: Cache Persistence Failure (Redis)

If the Redis dataset becomes corrupted and Redis fails to start or boots with corrupt state.

### Recovery Procedure
1. Stop the Redis container:
   ```bash
   make stop service=cache
   ```
2. Restore the `dump.rdb` file from the backup archive into the volume.
   We can do this using a temporary helper container to copy it safely:
   ```bash
   # Extract the archive
   tar -zxvf /srv/neos/backups/neos_backup_YYYY-MM-DD_HHMMSS.tar.gz -C /tmp/
   
   # Overwrite the volume file
   docker run --rm \
     -v neos_redis_data:/redis_data \
     -v /tmp/backup_YYYY-MM-DD_HHMMSS:/backup_src \
     alpine cp /backup_src/redis_dump.rdb /redis_data/dump.rdb
   ```
3. Start the Redis container:
   ```bash
   make start service=cache
   ```
4. Check Redis logs to ensure it loaded the snapshot:
   ```bash
   make logs service=cache
   ```

---

## Scenario C: Media/Object Storage Loss (MinIO)

If bucket objects are deleted or storage files become corrupted.

### Recovery Procedure
1. Stop MinIO:
   ```bash
   make stop service=object-store
   ```
2. Extract the MinIO backup archive:
   ```bash
   tar -zxvf /srv/neos/backups/neos_backup_YYYY-MM-DD_HHMMSS.tar.gz -C /tmp/
   ```
3. Wipe the corrupted volume and restore contents using an Alpine container:
   ```bash
   # Clean volume
   docker run --rm -v neos_minio_data:/minio_data alpine sh -c "rm -rf /minio_data/*"
   
   # Extract backup into volume
   docker run --rm \
     -v neos_minio_data:/minio_data \
     -v /tmp/backup_YYYY-MM-DD_HHMMSS:/backup_src \
     alpine tar -xzf /backup_src/minio_data.tar.gz -C /minio_data
   ```
4. Start MinIO:
   ```bash
   make start service=object-store
   ```

---

## Scenario D: Total VPS Loss (Bare-metal Recovery)

If the VPS host dies and needs to be rebuilt from scratch on a new Ubuntu 24.04 server.

### Rebuild Procedure

1. **Provision a new Ubuntu 24.04 VPS** and log in via SSH as root.
2. **Clone this repository** to the host:
   ```bash
   git clone https://github.com/nasimhwb/neos-platform.git /srv/neos-platform
   cd /srv/neos-platform
   ```
3. **Restore the `.env` file** containing secrets (from password manager or secure vault).
4. **Download the latest backup archive** from offsite cloud storage (e.g. Backblaze B2/S3) and place it under `/srv/neos/backups/`.
5. Run the provisioning script to configure Docker, Sysctl, firewall, and dummy SSL certs:
   ```bash
   chmod +x bootstrap/*.sh backups/*.sh
   sudo ./bootstrap/install.sh
   ```
6. **Run the full restoration script** (this will spin up containers, stop them, copy database dumps, write Redis files, restore object store folders, and restart services):
   ```bash
   ./backups/restore.sh /srv/neos/backups/neos_backup_YYYY-MM-DD_HHMMSS.tar.gz
   ```
7. Verify that all containers are healthy:
   ```bash
   make ps
   ```
8. **Request real Let's Encrypt certificates** to replace the dummy certs:
   ```bash
   # Extract domain from .env and run certbot command
   sudo certbot certonly --webroot -w /srv/neos/www -d neos-platform.local -d erp.neos-platform.local -d crm.neos-platform.local -d hrms.neos-platform.local -d billing.neos-platform.local -d inventory.neos-platform.local -d s3.neos-platform.local -d s3-console.neos-platform.local -d monitor.neos-platform.local
   ```
9. Reload Nginx reverse proxy to pick up the real SSL certificates:
   ```bash
   make reload-nginx
   ```
