# Neos Platform Shared Infrastructure - Operations Runbook

This document provides step-by-step procedures for managing, debugging, and scaling the shared infrastructure.

## Platform Runbooks Index
- [Deployment and Rollback Runbook](file:///d:/Webapp/KVM2/neos-platform/docs/runbooks/deployment-rollback.md)
- [Docker Maintenance Runbook](file:///d:/Webapp/KVM2/neos-platform/docs/runbooks/docker-maintenance.md)
- [Troubleshooting Runbook](file:///d:/Webapp/KVM2/neos-platform/docs/runbooks/troubleshooting.md)

## Routine Maintenance

### 1. Check Container Status and Health
To view container health, uptime, and port mappings:
```bash
make ps
```

### 2. View Log Streams
All logs are shipped to Loki, but you can inspect raw logs using the Makefile:
- View Nginx logs:
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

### 2. Add an Nginx Reverse Proxy Subdomain
When routing a new application subdomain:
1. Create a configuration file in `configs/nginx/conf.d/newapp.conf`.
2. Model it after `configs/nginx/conf.d/apps.conf`.
3. Re-run Certbot to request the SSL certificate for the new subdomain:
   ```bash
   sudo certbot certonly --webroot -w /srv/neos/www -d payroll.neos-platform.local
   ```
4. Reload Nginx to activate changes:
   ```bash
   make reload-nginx
   ```

---

## Troubleshooting Certificates and SSL

### Let's Encrypt SSL Expiry Check
SSL certificates automatically renew if the cronjob created by `certbot` is active. To test if renewal works:
```bash
sudo certbot renew --dry-run
```

### Force Cert Reload
If you've updated certificates and Nginx is still serving old ones, force Nginx to reload:
```bash
make reload-nginx
```

---

## System resource checks

### Check Disk Space
To verify host and container volume sizes:
```bash
df -h
docker system df
```

### Clean unused Docker resource
To release disk space by deleting stopped containers, unused networks, and dangling build caches:
```bash
docker system prune -f
```
To prune volumes as well (WARNING: this deletes unused data volumes; make sure no production volume is temporarily stopped):
```bash
docker volume prune
```
