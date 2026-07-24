# NEOS Platform — Engineering Investigation Log

This document is a chronological engineering journal recording all technical investigations, root cause analyses, and diagnostic proofs.

---

## [2026-07-24] — Running Web App Container Database Connection Probe

* **Engineer / AI**: Antigravity (Google DeepMind Team)
* **Branch**: `feature/platform-dashboard`
* **Commit**: `e7ee7bb`
* **Objective**: Prove which database the RUNNING web application container on `https://test.neosfacility.com` is connected to and resolve `404 Profile not found` on `/api/tasks`.
* **Symptoms**: Calling `GET /api/tasks` on `https://test.neosfacility.com` returned `HTTP 404 Profile not found`.
* **Evidence**:
  1. Direct PostgREST request to `https://supabase.neosfacility.com/rest/v1/profiles?id=eq.05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae` returned `HTTP 200 OK` with user record (`role: admin`, `linked_employee_id: C1134`).
  2. Next.js `/api/tasks` handler queried `supabaseAdmin` initialized with `NEXT_PUBLIC_SUPABASE_URL` pointing to Cloud Supabase (`epcbqpkosqucugfbmveo.supabase.co`).
  3. User `05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae` does not exist in Cloud Supabase, causing `profileError` and early exit with 404.
* **Commands Executed**:
  - `curl -sv "https://supabase.neosfacility.com/rest/v1/profiles?id=eq.05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae"` -> `HTTP 200 OK`
  - Node HTTP probe against `https://test.neosfacility.com/api/tasks` -> `HTTP 307` / `404`
* **Root Cause**: The web application Docker image contained baked-in build-time constants (`NEXT_PUBLIC_SUPABASE_URL`) pointing to Cloud Supabase. Restarting the container without `--no-cache` rebuild retained stale cloud endpoints.
* **Fix Applied**: Updated `.env.local` keys; created deployment runbook to rebuild container with `docker compose build --no-cache dashboard`.
* **Files Changed**:
  - `docs/investigations/2026-07-24-running-container-db-investigation.md`
  - `docs/investigations/2026-07-24-task-api-profile-not-found.md`
  - `docs/CHANGELOG.md`
  - `docs/INVESTIGATION_LOG.md`
* **Next Actions**: Rebuild container on VPS with `--no-cache` flag, verify `/api/tasks` HTTP 200, and execute Chrome end-to-end task CRUD suite.
* **Status**: 🟡 IN PROGRESS (Root Cause Proven; Rebuild Pending VPS Container Execution).

---

## [2026-07-24] — Kong API Gateway CORS & GoTrue Auth Investigation

* **Engineer / AI**: Principal SRE & Antigravity
* **Branch**: `feature/platform-dashboard`
* **Commit**: `cb1ea45`
* **Objective**: Resolve cross-origin resource sharing (CORS) blocks on authentication requests from `https://test.neosfacility.com`.
* **Symptoms**: Web app frontend authentication requests to `https://supabase.neosfacility.com/auth/v1` were blocked by browser CORS policy.
* **Root Cause**: Kong API Gateway lacked `https://test.neosfacility.com` in `KONG_CORS_ORIGINS` and GoTrue `GOTRUE_URI_ALLOW_LIST`.
* **Fix Applied**: Updated `configs/supabase/kong.yml` and `compose/compose.supabase.yml` to whitelist `https://test.neosfacility.com`.
* **Status**: 🟢 RESOLVED.
