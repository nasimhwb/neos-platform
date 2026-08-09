# NEOS Production Environment — Operational Changelog
## Chronological Infrastructure & Operational History

All verified changes, migrations, gateway corrections, and infrastructure modifications to the NEOS production environment are recorded in this document.

## [2026-08-09] — Coolify Pre-Installation & Coexistence Technical Audit (Read-Only)

- **Change:** Conducted comprehensive read-only audit of VPS `200.97.161.179` to evaluate Coolify coexistence safety.
- **Audit Findings:**
  - Host OS: Ubuntu 24.04 LTS (x86_64, Linux 6.8).
  - Resources: 2 vCPUs, 8 GB RAM (~5.3 GB available), 100 GB NVMe (~65 GB free).
  - Port & Ingress Ownership: Ports 80 and 443 are exclusively owned by `neos_traefik`.
  - Coolify State: 0 Coolify containers, 0 networks, 0 directories exist.
- **Architectural Conclusion:** **Option B — SAFE ONLY WITH ISOLATED/CUSTOM CONFIGURATION**. Standard Coolify installation would attempt to bind ports 80/443 and collide with `neos_traefik`. Coexistence requires keeping `neos_traefik` as the master edge proxy with Coolify internal proxy disabled or remapped.
- **Safety Guarantee:** ZERO modifications to Docker, containers, volumes, proxy, firewall, or DNS. Coolify has NOT been installed.

---

## [2026-08-09] — Production Storage Audit & Health Check Docker Volume Name Correction

- **Change:** Completed live production storage audit on VPS `200.97.161.179` and corrected `scripts/production-health-check.sh` to check authoritative production Docker volume names:
  - `neos_postgres_data` (~695.5 MB PostgreSQL database files)
  - `neos_minio_data` (~258 MB MinIO object storage data)
  - `neos_redis_data` (~20 KB Redis persistence data)
- **Reason:** Docker Compose prefixes named volumes with the project prefix `neos_`. The legacy health check script checked for unprefixed volume names (`postgres_data`, `minio_data`, `redis_data`), creating false negative failure reports even though all three volumes exist and are actively mounted in healthy production containers (`neos_postgres`, `neos_minio`, `neos_redis`).
- **Repository Changes:**
  - `scripts/production-health-check.sh` (Updated `CRITICAL_VOLUMES` array to check `neos_postgres_data`, `neos_minio_data`, `neos_redis_data` and added safety comment header)
  - `PRODUCTION_STATE.md`, `PRODUCTION_CHANGELOG.md`, `docs/operations/KNOWN_ISSUES.md`, `docs/investigations/INVESTIGATION_LOG.md` (Documentation updated)
- **Explicit Safety Rule Recorded:**
  > "Never create, rename, recreate, delete, prune, or migrate production data volumes based solely on a health-check failure. First inspect `docker inspect <container>` and verify the actual mounted volume."
- **Data & Safety Verification:**
  - Zero changes to production Docker volumes, filesystem paths, or live containers.
  - Zero modifications to PostgreSQL, MinIO, Redis, Supabase, Traefik, or application secrets.
  - All volume checks report 🟢 PASS.
- **Rollback:** `git revert` this commit or restore previous `production-health-check.sh`.

---

## [2026-08-09] — Traefik v3 Dynamic Routing Host Rule Syntax Migration

- **Change:** Migrated 5 routers in `configs/traefik/dynamic.yml` from Traefik v2 comma-separated `Host()` syntax to Traefik v3-compliant boolean expressions:
  - `legacy-php-hostinger`: `(Host(`neosfacility.com`) || Host(`www.neosfacility.com`)) && PathPrefix(`/neos_admin`)`
  - `vps-dashboard-router`: `(Host(`neosfacility.com`) || Host(`www.neosfacility.com`)) && PathPrefix(`/dashboard`)`
  - `vps-api-router`: `(Host(`neosfacility.com`) || Host(`www.neosfacility.com`)) && PathPrefix(`/api`)`
  - `vps-supabase-auth-router`: `(Host(`neosfacility.com`) || Host(`www.neosfacility.com`)) && (PathPrefix(`/auth`) || PathPrefix(`/supabase`))`
  - `vps-main-app-router`: `Host(`neosfacility.com`) || Host(`www.neosfacility.com`)`
- **Reason:** Resolve Traefik v3 parser error `unexpected number of parameters; got 2, expected one of [1]`, which invalidated dynamic configuration reloads on the running Traefik v3 container.
- **Repository Changes:**
  - `configs/traefik/dynamic.yml` (Host rules updated to v3 syntax)
  - `configs/traefik/dynamic.yml.bak_20260809_1402` (Safety backup)
  - `PRODUCTION_STATE.md`, `PRODUCTION_CHANGELOG.md`, `docs/operations/KNOWN_ISSUES.md`, `docs/investigations/INVESTIGATION_LOG.md` (Documentation updated)
- **Data & Safety Verification:**
  - PostgreSQL databases, schemas, and tables: Untouched (0 modifications).
  - Supabase Auth/Storage/Realtime data & keys: Untouched (0 modifications).
  - MinIO persistent storage: Untouched (0 modifications).
  - Container reload behavior: Traefik dynamic file provider watches the inode bound at container startup. Rebinding requires `docker compose restart neos_traefik` (zero data loss, ~1s proxy reload).
- **Rollback:** `cp configs/traefik/dynamic.yml.bak_20260809_1402 configs/traefik/dynamic.yml`.


---

## [2026-08-09] — Supabase Subdomain Ingress Router Fix Implementation & Baseline Audit

- **Change:** Added `supabase-subdomain-router` to `configs/traefik/dynamic.yml` mapping `Host(`supabase.neosfacility.com`)` directly to `supabase-gateway-service` (`neos_supabase_gateway:8000`).
- **Reason:** Resolve Traefik HTTP 404 response on `https://supabase.neosfacility.com/auth/v1/*` which caused `@supabase/auth-js` SDK JSON parse crash at position 4.
- **Repository Changes:**
  - `configs/traefik/dynamic.yml` (Router added)
  - `configs/traefik/dynamic.yml.bak_20260809_1317` (Safety backup)
  - `PRODUCTION_STATE.md`, `PRODUCTION_CHANGELOG.md`, `docs/operations/KNOWN_ISSUES.md`, `docs/investigations/INVESTIGATION_LOG.md` (Updated)
  - `.github/workflows/deploy.yml` (Deployment runner resilience audit)
- **Verified Status:**
  - `https://webapp.neosfacility.com/api/health`: HTTP 200 OK (`{"status":"healthy","service":"neos-app"}`)
  - `https://webapp.neosfacility.com/login`: HTTP 200 OK (Next.js client shell renders)
  - Supabase Storage Version (via Kong `supabase.neos-platform.local`): HTTP 200 OK (`1.67.5`)
  - Live VPS execution requirement: `git pull --ff-only origin master` on VPS host terminal.
- **Containers Affected:** Traefik (Dynamic file reload via inotify; zero container restarts).
- **Rollback:** `cp configs/traefik/dynamic.yml.bak_20260809_1317 configs/traefik/dynamic.yml`.

---

## [2026-08-09] — Phase 2 Authentication Root-Cause Diagnostics Completed


- **Change:** Conducted exhaustive read-only network and proxy diagnostic traces for Supabase Authentication endpoint failure (`AuthUnknownError` at position 4 and `AuthRetryableFetchError 503`).
- **Reason:** Identify exact failure location along the path: Browser/Next.js -> neos_app -> Supabase URL -> Traefik -> Kong -> GoTrue Auth.
- **Empirical Diagnostics & Proof:**
  - Probed `https://supabase.neosfacility.com/auth/v1/health` -> HTTP 404 plaintext `404 page not found` (Traefik ingress rejection).
  - Probed direct IP `200.97.161.179` with `Host: supabase.neos-platform.local` -> HTTP 200 OK (`Via: kong/2.8.1`, `GoTrue` active and healthy).
  - Probed CORS preflight with `Origin: https://webapp.neosfacility.com` -> HTTP 200 OK on Kong.
  - Inspected client bundle `689202975a5cfc3c.js` -> `NEXT_PUBLIC_SUPABASE_URL=https://supabase.neosfacility.com` is baked at build time.
  - Root cause proven: Traefik reverse proxy router configuration lacked `Host(`supabase.neosfacility.com`)`. Client `JSON.parse("404 page not found")` encounters character `'p'` at index 4 and throws `Unexpected non-whitespace character after JSON at position 4`.
- **Files Modified:** `PRODUCTION_STATE.md`, `PRODUCTION_CHANGELOG.md`, `docs/operations/KNOWN_ISSUES.md`, `docs/investigations/INVESTIGATION_LOG.md`.
- **Containers Affected:** None (Read-only diagnostics).
- **Verification:** Empirically verified with HTTP/TLS diagnostic probes.
- **Rollback:** N/A (Read-only investigation).

---

## [2026-08-09] — Production Safety, Documentation & Baseline Establishment


- **Change:** Established permanent production safety baseline and created core documentation suite (`PRODUCTION_STATE.md`, `PRODUCTION_CHANGELOG.md`, `PRODUCTION_DO_NOT_TOUCH.md`, `AG_PRODUCTION_RULES.md`, `COOLIFY_MIGRATION_PLAN.md`).
- **Reason:** Prevent unauthorized or accidental modifications by automated agents and human operators; establish authoritative source-of-truth.
- **Files Created/Modified:**
  - `PRODUCTION_STATE.md`
  - `PRODUCTION_CHANGELOG.md`
  - `PRODUCTION_DO_NOT_TOUCH.md`
  - `AG_PRODUCTION_RULES.md`
  - `COOLIFY_MIGRATION_PLAN.md`
  - `scripts/production-health-check.sh`
  - `scripts/production-snapshot.sh`
- **Containers Affected:** None (Read-only documentation and diagnostic tooling).
- **Verification:** Read-only probes to public endpoints (`webapp.neosfacility.com/api/health` 200 OK, `test.neosfacility.com/api/health` 200 OK).
- **Rollback:** Delete or revert created markdown documents via git.

---

## [2026-07-25] — Application Authentication Investigation Recorded

- **Change:** Formally documented ongoing investigation regarding application authentication integration error (`AuthRetryableFetchError 503` and `AuthUnknownError: Unexpected non-whitespace character after JSON at position 4`).
- **Reason:** Prevent premature, destructive, or guessing-based configuration changes to JWT secrets, Traefik, or Supabase.
- **Files Changed:** `docs/operations/KNOWN_ISSUES.md`, `PRODUCTION_STATE.md`.
- **Containers Affected:** `neos_app`, `neos_supabase_gateway`, `neos_supabase_auth`.
- **Verification:** `neos_app` is healthy; `https://webapp.neosfacility.com` is reachable; `/api/health` returns HTTP 200 JSON; Supabase Auth itself is healthy and reachable from the gateway. Root cause under structured investigation.
- **Rollback:** N/A (Diagnostic status).

---

## [2026-07-25] — Storage Migration & Integrity Verification (1,178 Objects)

- **Change:** Migrated and verified 1,178 production objects from legacy MinIO layout into the Supabase Storage S3-compatible backend.
- **Reason:** Standardize storage backend on Supabase Storage engine with S3 persistence while maintaining 100% data integrity.
- **Files Changed:** `compose/compose.supabase.yml`, `compose/compose.storage.yml`.
- **Containers Affected:** `neos_minio`, `neos_supabase_storage`, `neos_postgres`.
- **Verification:**
  - Production DB storage records: **1,178**
  - Found in Storage Backend: **1,178**
  - Missing objects: **0**
  - Size mismatches: **0**
  - ETag mismatches: **0**
  - Fully verified: **1,178 / 1,178 (100%)**
  - Bucket breakdown: `gem-contracts` (201), `order-attachments` (635), `field-tracking` (335), `refundable-assets` (7).
- **Canary Verification:** 5-object canary migration executed and verified before full dataset synchronization.
- **Rollback / Safety Note:** Legacy MinIO container and `minio_data` volume retained untouched to allow instant fallback if needed.

---

## [2026-07-24] — Supabase Gateway Network Architecture Correction

- **Change:** Added `neos-database` network to `neos_supabase_gateway` service definition in `compose/compose.supabase.yml` and recreated the container.
- **Reason:** The Kong ingress gateway was previously attached only to `neos-public` and `neos-private`, causing DNS resolution and TCP routing failures when routing internal auth and REST traffic to services requiring database-tier connectivity.
- **Files Changed:** `compose/compose.supabase.yml`.
- **Containers Affected:** `neos_supabase_gateway`.
- **Verification:**
  - Gateway DNS resolution verified: `neos_supabase_gateway` successfully resolves hostname `supabase-auth`.
  - In-cluster HTTP probe verified: `curl http://supabase-auth:9999/health` from gateway returns HTTP 200 GoTrue JSON response.
  - Gateway routes `/auth/v1` traffic correctly to backend GoTrue container.
- **Rollback:** Revert `compose/compose.supabase.yml` network section and recreate gateway container.

---

## [2026-07-24] — Traefik Backend Eviction Fix & Application Health Endpoint

- **Change:** Implemented `GET /api/health` endpoint in `neos_app` returning JSON status payload and updated Traefik service health check configuration.
- **Reason:** Traefik load balancer was periodically evicting `neos_app` backends due to 404 responses on unmapped health check paths.
- **Files Changed:** `dashboard/app/api/health/route.ts` (in application codebase), `docker-compose.app.yml`.
- **Containers Affected:** `neos_app`, `neos_traefik`.
- **Verification:** `curl -i https://webapp.neosfacility.com/api/health` returns `HTTP/1.1 200 OK` with JSON `{"status":"healthy","service":"neos-app"}`. Traefik backend status remains continuously healthy.
- **Rollback:** Revert health route file and restart container.

---

## [2026-07-24] — Public Profiles Compatibility View Creation

- **Change:** Executed SQL migration creating `public.profiles` view aliasing `public.client_profiles`.
- **Reason:** Frontend application queries expected `public.profiles` while the underlying PostgreSQL migration created `public.client_profiles`.
- **Files Changed:** `configs/postgres/init-scripts/` (migration applied to database).
- **Containers Affected:** `neos_postgres`.
- **Verification:** Query `SELECT COUNT(*) FROM public.profiles;` executed cleanly and returned record count equal to `client_profiles`.
- **Rollback:** `DROP VIEW IF EXISTS public.profiles;`.

---

## [2026-07-22] — Production Infrastructure Provisioning & Staging Baseline

- **Change:** Initial deployment of multi-stack Docker Compose infrastructure on Hostinger KVM2 VPS (`200.97.161.179`).
- **Reason:** Establish unified self-hosted production platform for NEOS Platform and NEOS App suite.
- **Files Changed:** Entire initial repository configuration under `/srv/neos/neos-platform/`.
- **Containers Affected:** All platform containers (`neos_traefik`, `neos_postgres`, `neos_pgbouncer`, `neos_redis`, `neos_minio`, `neos_supabase_*`, `neos_uptime_kuma`).
- **Verification:** Completed system diagnostic script execution (`doctor.sh`).
- **Status:** *Historical detail verified against active running stack.*
