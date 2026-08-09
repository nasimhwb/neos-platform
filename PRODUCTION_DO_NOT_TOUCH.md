# PRODUCTION SAFETY RESTRICTIONS & "DO NOT TOUCH" DIRECTIVES
## NEOS Platform / NEOS App Production Environment

**Classification:** STRICT PRODUCTION SAFETY POLICY  
**Scope:** All Developers, DevOps Engineers, and AI Agents  
**Enforcement:** Mandatory / Zero-Tolerance  

---

## 1. Strictly Prohibited Operations (Explicit Approval Required)

The following actions and commands must **NEVER** be executed on the production server without explicit, written confirmation and approval from the project owner:

### 1.1 Docker & Volume Destruction
- 🛑 `docker compose down -v` (Destroys named and anonymous volumes)
- 🛑 `docker volume rm ...` / `docker volume prune`
- 🛑 `docker system prune --volumes` or `docker system prune -a --volumes`
- 🛑 Removing persistent Docker volumes: `neos_postgres_data`, `neos_minio_data`, `neos_redis_data`, `neos_uptime_kuma_data` (or legacy aliases)
- 🛑 Deleting or altering volume mount directories under `/srv/neos/shared/` or `/var/lib/docker/volumes/`
- 🛑 **Explicit Production Safety Rule:** Never create, rename, recreate, delete, prune, or migrate production data volumes based solely on a health-check failure. First inspect `docker inspect <container>` and verify the actual mounted volume.

### 1.2 Database Destructive Commands
- 🛑 `DROP DATABASE ...` (e.g. `DROP DATABASE postgres`, `DROP DATABASE neos_app`, `DROP DATABASE neos_erp`, etc.)
- 🛑 `DROP SCHEMA ... CASCADE` (e.g. `DROP SCHEMA auth CASCADE`, `DROP SCHEMA storage CASCADE`, `DROP SCHEMA public CASCADE`)
- 🛑 `TRUNCATE` operations on any production tables (e.g., `auth.users`, `public.orders`, `public.client_profiles`, `public.tasks`, `storage.objects`, `storage.buckets`)
- 🛑 `DELETE FROM ...` without explicit targeted WHERE conditions and owner signoff
- 🛑 `ALTER TABLE ... DROP COLUMN` on production schema tables
- 🛑 Overwriting database initialization scripts or database configurations without verified backups

### 1.3 Object Storage & MinIO Operations
- 🛑 **DO NOT DELETE LEGACY MINIO** (`neos_minio` container and `minio_data` volume). Legacy MinIO contains historical production object state.
- 🛑 **DO NOT DELETE EXISTING SUPABASE STORAGE DATA**. All migrated buckets (`gem-contracts`, `order-attachments`, `field-tracking`, `refundable-assets`) and underlying S3 object layouts must remain intact.
- 🛑 `mc rm --recursive --force ...` or any bulk object deletion commands against MinIO or Supabase storage buckets
- 🛑 Deleting buckets in MinIO or dropping rows in `storage.buckets` / `storage.objects`

### 1.4 Cryptographic & Authentication Secrets
- 🛑 Resetting or regenerating `JWT_SECRET` in `.env`, `docker-compose`, or GoTrue/PostgREST configuration. (Invalidates all active client sessions and tokens!)
- 🛑 Resetting or regenerating `SUPABASE_SERVICE_KEY` / `SUPABASE_SERVICE_ROLE_KEY` or `SUPABASE_ANON_KEY`. (Breaks Next.js server-side data loaders and client SDKs!)
- 🛑 Modifying `POSTGRES_SUPERUSER_PASSWORD`, `POSTGRES_SUPABASE_ADMIN_PASSWORD`, or `POSTGRES_AUTHENTICATOR_PASSWORD` without coordinated multi-service migration.
- 🛑 Changing `REALTIME_SECRET_KEY_BASE` or `REDIS_PASSWORD` on active services.

### 1.5 Edge, DNS & Networking
- 🛑 Replacing Traefik with another reverse proxy (Nginx, Caddy, HAProxy, Coolify proxy) without an approved migration plan.
- 🛑 Installing another reverse proxy that attempts to bind ports `80` or `443`.
- 🛑 Modifying DNS A-records or CNAMEs on Cloudflare / registrar for `neosfacility.com`, `webapp.neosfacility.com`, `supabase.neosfacility.com`, `test.neosfacility.com`.
- 🛑 Disconnecting Docker networks (`neos-public`, `neos-private`, `neos-database`, `neos-storage`, `neos-monitoring`) from running production containers.
- 🛑 Modifying Host UFW firewall rules or systemd network configurations without tested fallback access.

### 1.6 Release Directories & Deployment Stacks
- 🛑 **DO NOT ASSUME OLD RELEASE DIRECTORIES ARE UNUSED.** Directories under `/srv/neos/releases/` may contain active rollback targets or mounted assets.
- 🛑 Deleting release directories or switching symlinks (`/srv/neos/current`) manually without using tested release tools (`scripts/rollback.sh`).
- 🛑 Blindly wiping `/srv/neos/tmp/` or `/srv/neos/shared/` without inspecting contents.

---

## 2. General Safety Directives

1. **VERIFY BEFORE CLEANUP**: Before deleting any file, container, image, or directory to reclaim disk space, verify that:
   - It is not mounted by any running container (`docker inspect`).
   - It is not referenced in active compose files or symlinks.
   - It is not part of a rollback path.
2. **COORDINATED AUTH FIXES ONLY**: Do not execute ad-hoc key rotations or proxy rewrites to "fix" authentication issues. Follow the structured investigation protocol.
3. **READ-ONLY TRIAGE**: Troubleshooting production issues must use read-only diagnostic commands (`docker inspect`, `docker logs`, `curl -i`, `wget -qO-`, `pg_isready`).
