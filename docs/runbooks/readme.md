# Neos Platform Shared Infrastructure - Operations Runbook

This document provides step-by-step procedures for managing, debugging, and scaling the shared infrastructure.

## Platform Runbooks Index
- [Backup & Recovery Operations Runbook](backup-and-recovery.md)
- [Deployment and Rollback Runbook](deployment-rollback.md)
- [Disaster Recovery & Rollback Operations Runbook](disaster-recovery.md)
- [Docker Maintenance Runbook](docker-maintenance.md)
- [Production Go-Live Checklist & Hardening Report](go_live_checklist.md)
- [Monitoring & Alerting Operations Runbook](monitoring-maintenance.md)
- [Neos-App Migration Plan & Blue-Green Operations Guide](neos-app-migration.md)
- [PostgreSQL Maintenance Runbook](postgres-maintenance.md)
- [MinIO Object Storage Maintenance Runbook](minio-maintenance.md)
- [Redis Cache Maintenance Runbook](redis-maintenance.md)
- [Supabase Compatibility Layer Runbook](supabase-compatibility.md)
- [Traefik Ingress Maintenance Runbook](traefik-maintenance.md)
- [Troubleshooting Runbook](troubleshooting.md)

---

## Routine Maintenance

### 1. Check Container Status and Health
To view container health, uptime, and port mappings:
```bash
make ps
```

### 2. View Log Streams
All logs are shipped to Loki, but you can inspect raw logs using the Makefile:
- View Ingress Proxy logs:
  ```bash
  make logs service=reverse-proxy
  ```
- View PostgreSQL query logs:
  ```bash
  make logs service=db
  ```
- View Redis cache logs:
  ```bash
  make logs service=cache
  ```

---

## Modifying Applications and Databases

### 1. Adding a Database for a New SaaS App
If you are deploying a new application (e.g. `neos_payroll`) and need a new database and user:

1. Open `.env` in the root repository folder.
2. Locate `POSTGRES_MULTIPLE_DATABASES`.
3. Append your new application in the format: `,db_name:db_user:db_password`
   - Example:
     ```env
     POSTGRES_MULTIPLE_DATABASES=neos_erp:erp_user:erp_pass,...,neos_payroll:payroll_user:payroll_secure_pass
     ```
4. Run the database initialization:
   *Note: The init script only runs automatically when the database data directory is completely empty. If Postgres is already running, run the following manually:*
   ```bash
   docker exec -it neos_postgres psql -U postgres -c "CREATE USER payroll_user WITH PASSWORD 'payroll_secure_pass';"
   docker exec -it neos_postgres psql -U postgres -c "CREATE DATABASE neos_payroll OWNER payroll_user;"
   docker exec -it neos_postgres psql -U postgres -d neos_payroll -c "GRANT ALL ON SCHEMA public TO payroll_user;"
   ```

### 2. Adding a new Subdomain for an App (Traefik v3)
Because the platform uses Traefik with dynamic Docker service discovery, you do NOT need to write any web server configurations. 
To route traffic to a new container:
1. Attach the following labels to the service in your Docker Compose file:
   ```yaml
   labels:
     - "traefik.enable=true"
     - "traefik.http.routers.newapp.rule=Host(`newapp.${BASE_DOMAIN:-neos-platform.local}`)"
     - "traefik.http.routers.newapp.entrypoints=websecure"
     - "traefik.http.routers.newapp.tls=true"
     - "traefik.http.routers.newapp.middlewares=security-headers@file,compression@file,rate-limit@file"
     - "traefik.http.services.newapp.loadbalancer.server.port=80" # Target container port
   ```
2. Redeploy the stack. Traefik will automatically detect the new labels, request an SSL certificate from Let's Encrypt, and start routing HTTPS traffic.

---

## System Resource Checks

### Check Disk Space
To verify host and container volume sizes:
```bash
df -h
docker system df
```

### Clean Unused Docker Resources
To release disk space by deleting stopped containers, unused networks, and dangling build caches:
```bash
make clean
```
