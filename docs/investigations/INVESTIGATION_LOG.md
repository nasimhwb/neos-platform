# NEOS Platform — Engineering Investigation Log

This document is a chronological engineering journal recording all technical investigations, root cause analyses, and diagnostic proofs.

---

## [2026-07-24] — VPS Staging Dashboard Container Deployment & Verification

* **Engineer / AI**: Antigravity (Google DeepMind Team)
* **Branch**: `feature/platform-dashboard`
* **Commit**: `5723f0d`
* **Objective**: Rebuild and redeploy `neos_dashboard` container on Hostinger VPS staging host (`https://test.neosfacility.com`) with clean build arguments and valid HMAC-SHA256 Supabase keys.
* **Execution & Verification**:
  1. Updated `/srv/neos/neos-platform/.env` on VPS to purge corrupted JWT headers.
  2. Executed clean build: `docker compose --env-file .env -f compose/compose.base.yml -f compose/compose.database.yml -f compose/compose.monitoring.yml -f compose/compose.dashboard.yml build --no-cache dashboard`.
  3. Recreated container: `docker compose ... up -d --force-recreate dashboard`.
  4. Verified environment inside running container:
     ```text
     docker exec neos_dashboard printenv | grep SUPABASE
     NEXT_PUBLIC_SUPABASE_URL=https://supabase.neosfacility.com
     SUPABASE_URL=https://supabase.neosfacility.com
     SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
     ```
* **Status**: 🟢 DEPLOYED & VERIFIED (Container running with self-hosted Supabase URL and valid service role keys).

---

## [2026-07-24] — Fix Applied: Dashboard Build Args & Environment Variables Injected

* **Engineer / AI**: Antigravity (Google DeepMind Team)
* **Branch**: `feature/platform-dashboard`
* **Commit**: `243b13a`
* **Objective**: Fix web application container database connection by declaring Supabase build arguments and runtime environment variables in Dockerfile and Compose stack.
* **Status**: 🟢 RESOLVED.
