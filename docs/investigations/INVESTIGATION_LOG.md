# NEOS Platform — Engineering Investigation Log

This document is a chronological engineering journal recording all technical investigations, root cause analyses, and diagnostic proofs.

---

## [2026-07-25] — Staging E2E & Tasks Module CRUD Verification Passed

* **Engineer / AI**: Antigravity (Google DeepMind Team)
* **Branch**: `master` (neos-app) / `feature/platform-dashboard` (neos-platform)
* **Commit**: `352ed77f` / `2cec2cf`
* **Objective**: Perform full infrastructure health audit, browser end-to-end authentication, and Tasks module CRUD testing on live staging host (`https://test.neosfacility.com`).
* **Execution & Empirical Proof**:
  1. **Infrastructure Health**:
     - SSH daemon: `active`
     - Docker daemon: `active`
     - Containers: `neos_app` (`Up (healthy)`), `neos_dashboard` (`Up (healthy)`), `neos_postgres` (`Up (healthy)`), `neos_supabase_auth` (`Up (healthy)`), `neos_traefik` (`Up (healthy)`).
  2. **Traefik Loadbalancer Health Fix**:
     - Created `GET /api/health` returning HTTP 200 JSON in `neos-app` (`src/app/api/health/route.ts`).
     - Rebuilt `neos_app` image (`neos_app:latest`); Traefik health check transitioned `neos_app` to `healthy` state.
  3. **Browser E2E & Tasks CRUD Verification**:
     - Logged in as `tester@neosfacility.com` (`Tester Admin`).
     - Navigated to `https://test.neosfacility.com/dashboard/tasks`.
     - Verified Tasks page loads cleanly (`HTTP 200 OK`, `61 Total Pending Tasks`, 0 console errors).
     - **Create Task**: Created task `"Staging Health Audit Verification"`.
     - **Edit Task**: Updated task title to `"Staging Health Audit Verification - Updated"`.
     - **Delete Task**: Removed task duplicate; data persisted after page refresh.
     - Captured screenshot evidence: `tasks_list_final_1784954242370.png`.
* **Status**: 🟢 **100% OPERATIONAL & VERIFIED**.

---

## [2026-07-25] — Application Audit: Users & Suggestions Pages Root Cause Diagnostics

* **Engineer / AI**: Antigravity (Google DeepMind Team)
* **Branch**: `master` (neos-app) / `feature/platform-dashboard` (neos-platform)
* **Objective**: Audit Users (`/dashboard/admin/users`) and Suggestions & Errors (`/dashboard/admin/suggestions`) pages on live staging environment (`https://test.neosfacility.com`).
* **Empirical Diagnostics & Root Causes**:
  1. **Users Page (`/dashboard/admin/users`)**:
     - **Observation**: Renders shell UI but shows 0 users, "No users found", and toast `Failed to load users 🚨`.
     - **Network Trace**: `POST https://supabase.neosfacility.com/rest/v1/rpc/get_user_order_counts` throws `TypeError: Failed to fetch`.
     - **Root Cause**: CORS preflight response from Supabase omits `content-profile` in `Access-Control-Allow-Headers`. When `Promise.all` executes in `fetchProfiles`, the RPC POST failure rejects the entire data fetch.
     - **Evidence**: `audit_users_page_1784991934380.png`.
  2. **Suggestions & Errors Page (`/dashboard/admin/suggestions`)**:
     - **Observation**: Backlog tab renders empty state with error toast `Failed to load suggestions backlog`.
     - **Network Trace**: `GET https://test.neosfacility.com/api/suggestions` returns HTTP 500 JSON: `{"status":"error","message":"Could not find a relationship between 'suggestions' and 'assigned_developer_id' in the schema cache"}`.
     - **Root Cause**: Database table `public.suggestions` column `assigned_developer_id` lacks foreign key constraint referencing `public.profiles(id)`. Joined PostgREST query in `/api/suggestions` crashes.
     - **Evidence**: `audit_suggestions_page_1784992017152.png`.
* **Status**: 🔴 **DIAGNOSED & AUDIT LOGGED** (Fixes deferred per strict audit workflow).

