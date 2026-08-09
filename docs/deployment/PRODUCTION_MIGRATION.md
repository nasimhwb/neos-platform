# Production Migration & Cutover Plan

**Project:** NEOS Platform Shared Infrastructure Migration  
**Target Environment:** Hostinger VPS (`200.97.161.179`)  
**Domain Endpoint:** `https://test.neosfacility.com` (Staging) / `https://neosfacility.com` (Production)  

---

## 1. Migration Strategy
- **Architecture Type**: Self-hosted Docker Compose stack featuring PostgreSQL 15, Supabase GoTrue Auth, Kong API Gateway, Traefik Reverse Proxy, MinIO, and Redis.
- **Approach**: Blue/Green operational deployment pattern. The target VPS infrastructure was provisioned side-by-side with existing systems. Schema, roles, and user data are restored and validated prior to switching DNS cutover.

---

## 2. Backup Plan
- **Pre-Cutover Backup**:
  - Run database dump script: `./backups/backup.sh` to capture full PostgreSQL logical dump including `auth` and `public` schemas.
  - Save environment configuration backup: `cp /srv/neos/neos-platform/.env /srv/neos/backups/env.backup.$(date +%F)`.
  - Save MinIO storage volumes snapshot.
- **Storage Location**: Store encrypted backups both locally on VPS (`/srv/neos/backups/`) and off-site.

---

## 3. Data Sync Plan
1. **User Identity Sync**:
   - Dump `auth.users` and `auth.identities` from source database.
   - Execute metadata normalization query to align JSON user metadata formats.
   - Insert missing identity records using `02-supabase-compat.sql`.
2. **Profile & Module Table Sync**:
   - Populate `public.client_profiles` and refresh the `public.profiles` alias view.
   - Seed `public.tasks`, `public.task_assignees`, `public.suggestions`, and HR module tables (`public.employees`).
   - Run RLS policy migration scripts to apply table security policies and role permissions.

---

## 4. Cutover Plan
1. **Freeze Source Write Operations**: Set source database to read-only mode or disable write APIs during final sync window.
2. **Final Data Delta Sync**: Execute delta sync script to copy any remaining user signups or updated records.
3. **DNS Switching**:
   - Update A records for `test.neosfacility.com` and `*.neosfacility.com` to point to VPS IP (`200.97.161.179`).
   - TTL reduced to 300 seconds prior to cutover.
4. **Traefik ACME Certificate Issuance**:
   - Traefik automatically requests Let's Encrypt certificates upon first HTTP challenge on port 80.
5. **Health Verification**: Verify response status across all endpoints.

---

## 5. Rollback Plan
In the event of a critical failure during cutover:
1. **DNS Reversion**: Point DNS A records back to legacy server IP addresses immediately.
2. **Container Suspension**: Run `docker compose down` on VPS to pause ingress traffic.
3. **Data Integrity Check**: Verify legacy database state remains unmodified.
4. **Post-Mortem**: Log incident details in `docs/investigations/` and `docs/KNOWN_ISSUES.md`.

---

## 6. Verification Checklist
- [x] **SSH Port 22 Accessibility**: Verified global listening on host.
- [x] **PostgreSQL 15 Cluster**: Roles, schemas, and extensions initialized.
- [x] **Supabase Auth (GoTrue)**: Token generation and password verification tested.
- [x] **Kong CORS Policy**: `https://test.neosfacility.com` white-listed in CORS origins.
- [x] **Traefik TLS / SSL**: ACME Let's Encrypt certificate automation verified.
- [x] **Database Views**: `public.profiles` view operational for legacy query compatibility.
- [ ] **VPS Secrets Sync**: Final check of production API keys in `/srv/neos/neos-platform/.env`.
- [ ] **End-to-End User Flow**: Full login and dashboard navigation verified on `test.neosfacility.com`.
