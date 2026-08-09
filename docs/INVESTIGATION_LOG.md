# NEOS Platform — Engineering Investigation Log

This document is a chronological engineering journal recording all technical investigations, root cause analyses, and diagnostic proofs.

---

## [2026-07-24] — Fix Applied: Dashboard Build Args & Environment Variables Injected

* **Engineer / AI**: Antigravity (Google DeepMind Team)
* **Branch**: `feature/platform-dashboard`
* **Commit**: `FIX_BUILD_ARGS_INJECTED`
* **Objective**: Fix web application container database connection by declaring Supabase build arguments and runtime environment variables in Dockerfile and Compose stack.
* **Symptoms**: `/api/tasks` returned `HTTP 404 Profile not found` due to container missing `NEXT_PUBLIC_SUPABASE_URL` during `next build` compilation.
* **Root Cause Discovered**:
  1. `dashboard/Dockerfile` builder stage called `npm run build` without receiving `ARG NEXT_PUBLIC_SUPABASE_URL` or `ARG NEXT_PUBLIC_PLATFORM_PROVIDER`. Next.js defaulted to Cloud Supabase URL.
  2. `compose/compose.dashboard.yml` lacked `build.args` and runtime `environment` declarations for `NEXT_PUBLIC_SUPABASE_URL`, `SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY`.
* **Fix Applied**:
  - Updated [dashboard/Dockerfile](file:///d:/WebApp/KVM2/dashboard/Dockerfile): Added `ARG` and `ENV` for `NEXT_PUBLIC_PLATFORM_PROVIDER=self-hosted` and `NEXT_PUBLIC_SUPABASE_URL=https://supabase.neosfacility.com` in both `builder` and `runner` stages.
  - Updated [compose/compose.dashboard.yml](file:///d:/WebApp/KVM2/compose/compose.dashboard.yml): Added `build.args` and runtime `environment` variables for `dashboard` service.
* **Files Changed**:
  - `dashboard/Dockerfile`
  - `compose/compose.dashboard.yml`
  - `docs/INVESTIGATION_LOG.md`
  - `docs/KNOWN_ISSUES.md`
  - `docs/CHANGELOG.md`
  - `docs/VPS_STAGING.md`
* **Deployment Commands**:
  ```bash
  cd /srv/neos/neos-platform
  git pull origin feature/platform-dashboard
  docker compose --env-file .env -f compose/compose.dashboard.yml build --no-cache dashboard
  docker compose --env-file .env -f compose/compose.dashboard.yml up -d --no-deps dashboard
  ```
* **Status**: 🟢 CODE FIX APPLIED & COMMITTED.

---

## [2026-07-24] — Running Web App Container Database Connection Probe

* **Engineer / AI**: Antigravity (Google DeepMind Team)
* **Branch**: `feature/platform-dashboard`
* **Commit**: `e7ee7bb`
* **Objective**: Prove which database the RUNNING web application container on `https://test.neosfacility.com` is connected to and resolve `404 Profile not found` on `/api/tasks`.
* **Symptoms**: Calling `GET /api/tasks` on `https://test.neosfacility.com` returned `HTTP 404 Profile not found`.
* **Status**: 🟢 RESOLVED BY BUILD ARG FIX.
