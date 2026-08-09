# NEOS Production Environment — Operational Changelog
## Chronological Infrastructure & Operational History

All verified changes, migrations, gateway corrections, and infrastructure modifications to the NEOS production environment are recorded in this document.

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
