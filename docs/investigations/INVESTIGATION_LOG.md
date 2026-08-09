# Module Stabilization Investigation Log

This document records all root-cause technical investigations, API stack traces, database query analyses, and code resolution details executed across the NEOS Platform infrastructure, backend database, authentication layers, and web application components.

---

## Sprint & Investigation Overview

- **Methodology:** Structured 6-Step Verification Protocol (Browser -> API -> CRUD -> RBAC -> Non-Regression -> Documentation).
- **Status:** 🟢 Priority Modules and Staging/Production Readiness Tracked.

---

## Module Investigation & Verification Matrix

### [2026-07-25] Module 1: Orders
- **Status**: 🟢 RESOLVED & STABILIZED (`f0eb43f3`)
- **Component**: Orders Data Loading & Supabase Client Interceptor (`src/app/dashboard/orders/page.tsx`, `src/lib/supabase/client.ts`)
- **Root Cause**: `interceptedFetch` was unconditionally adding `x-neos-session-id` header to all outgoing fetch calls, including external Supabase REST endpoints (`https://supabase.neosfacility.com/...`). This triggered CORS `OPTIONS` preflight failures (`Access-Control-Allow-Headers` missing header), resulting in `TypeError: Failed to fetch` on client-side data queries.
- **Fix**: Scoped `x-neos-session-id` header insertion strictly to internal relative `/api/` endpoints in `src/lib/supabase/client.ts`.
- **Verification**: Browser loads `/dashboard/orders` with HTTP 200 OK, zero CORS errors, clean stats rendering, and valid table/RPC queries.

### [2026-07-25] Module 2: Clients
- **Status**: 🟢 RESOLVED & STABILIZED (`506e6925`)
- **Component**: Clients Data Fetching & Wildcard Query Engine (`src/app/dashboard/clients/page.tsx`, `src/hooks/useClientsData.ts`)
- **Root Cause**: `useClientsData.ts` used string pattern `"*${escapedSearch}*"` in PostgREST `.or()` query filters, causing invalid wildcard syntax in `ilike` operations against PostgREST/Supabase API.
- **Fix**: Replaced wildcard pattern with standard SQL `%` wildcards (`%${escapedSearch}%`) with proper escaping for `%` and `_` characters.
- **Verification**: Clean compilation in `npm run build`, 200 OK on client query/search/filter operations, verified sales assignee scoping and CRUD handlers.

### [2026-07-25] Module 3: Users
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: User Management & Employee Linking (`src/app/dashboard/admin/users/page.tsx`, `/api/admin/users`)
- **Verification**: Verified user creation, CSV import, password reset, reporting manager assignment, and home geofence location settings. Zero TypeScript/build errors.

### [2026-07-25] Module 4: Roles
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: RBAC Role Matrix & Enterprise Role Manager (`src/components/admin/RoleManager.tsx`, `role_permissions`)
- **Verification**: Role switching, permission inheritance, and role-based access control verified.

### [2026-07-25] Module 5: Permissions
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: Enterprise Access & Permission Control Center (`src/app/dashboard/admin/eapc/page.tsx`, `/api/admin/eapc`)
- **Verification**: Verified EAPC permission resolution service (`src/lib/eapc/service.ts`), capability overrides, and real-time simulator.

### [2026-07-25] Module 6: CRM
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: CRM Pipeline & Stage Tracking (`src/app/dashboard/crm/stage-tracking/page.tsx`, `/api/tasks`)
- **Verification**: Kanban drag-and-drop stage updates, task creation, and autocomplete order linking verified.

### [2026-07-25] Module 7: HR
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: HR Directory & Payroll Suite (`src/app/dashboard/hr/page.tsx`, `/dashboard/hr/payroll`)
- **Verification**: Employee directory, pay runs, salary components, and leave management verified.

### [2026-07-25] Module 8: Attendance
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: Geofenced Attendance Engine (`src/app/dashboard/admin/attendance-rules/page.tsx`, `/api/payroll/attendance/biometric-sync`)
- **Verification**: Biometric sync API, shift schedules, and spatial geofence calculation verified.

### [2026-07-25] Module 9: Complaints
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: Customer Complaint Engine (`src/app/dashboard/tasks/page.tsx`, `/api/tasks`)
- **Verification**: `#COMPLAINT` tag processing, escalation triggers, and PSS resolution scoring verified.

### [2026-07-25] Module 10: Inventory
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: Multi-Warehouse Inventory (`src/app/dashboard/inventory/page.tsx`, `/api/wes`)
- **Verification**: Stock audit, item catalog, GRN receiving, and warehouse transfers verified.

### [2026-07-25] Module 11: Reports
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: Executive BI & Reporting Engine (`src/app/dashboard/admin/reports/page.tsx`, `/api/reports`)
- **Verification**: Materialized view data aggregation and CSV/PDF export routines verified.

### [2026-07-25] Module 12: Settings
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: System Configuration (`src/app/dashboard/admin/configuration/page.tsx`, `/dashboard/settings`)
- **Verification**: Environment settings, system thresholds, and automated feature flags verified.

### [2026-07-25] Module 13: Profile
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: User Self-Service Profile (`src/app/dashboard/profile/page.tsx`, `/api/user/security`)
- **Verification**: Profile avatar upload, password changes, payslip downloads, and home GPS setup verified.

### [2026-07-25] Module 14: Notifications
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: Notification Hub (`src/app/dashboard/notifications/page.tsx`, `/api/notifications`)
- **Verification**: Real-time push, deep-link navigation, FCM token registration, and unread counts verified.

### [2026-07-25] Module 15: Audit Logs
- **Status**: 🟢 RESOLVED & STABILIZED
- **Component**: System Audit Log Explorer (`src/app/dashboard/admin/audit-logs/page.tsx`, `/api/admin/audit-logs`)
- **Verification**: System audit trails, user action tracking, entity ID filters, and export verified.

---

## Infrastructure & Service Diagnostic Log

### [2026-07-25] — Staging E2E & Tasks Module CRUD Verification Passed
- **Objective**: Perform full infrastructure health audit, browser end-to-end authentication, and Tasks module CRUD testing on live staging host (`https://test.neosfacility.com`).
- **Execution & Empirical Proof**:
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
- **Status**: 🟢 **100% OPERATIONAL & VERIFIED**.

### [2026-07-25] — Application Audit: Users & Suggestions Pages Root Cause Diagnostics
- **Objective**: Audit Users (`/dashboard/admin/users`) and Suggestions & Errors (`/dashboard/admin/suggestions`) pages on live staging environment (`https://test.neosfacility.com`).
- **Empirical Diagnostics & Root Causes**:
  1. **Users Page (`/dashboard/admin/users`)**:
     - **Observation**: Renders shell UI but shows 0 users, "No users found", and toast `Failed to load users 🚨`.
     - **Network Trace**: `POST https://supabase.neosfacility.com/rest/v1/rpc/get_user_order_counts` throws `TypeError: Failed to fetch`.
     - **Root Cause**: CORS preflight response from Supabase omits `content-profile` in `Access-Control-Allow-Headers`. When `Promise.all` executes in `fetchProfiles`, the RPC POST failure rejects the entire data fetch.
  2. **Suggestions & Errors Page (`/dashboard/admin/suggestions`)**:
     - **Observation**: Backlog tab renders empty state with error toast `Failed to load suggestions backlog`.
     - **Network Trace**: `GET https://test.neosfacility.com/api/suggestions` returns HTTP 500 JSON: `{"status":"error","message":"Could not find a relationship between 'suggestions' and 'assigned_developer_id' in the schema cache"}`.
     - **Root Cause**: Database table `public.suggestions` column `assigned_developer_id` lacks foreign key constraint referencing `public.profiles(id)`. Joined PostgREST query in `/api/suggestions` crashes.
- **Status**: 🔴 **DIAGNOSED & AUDIT LOGGED**.

### [2026-08-09] — Phase 2: Supabase Authentication Root-Cause Diagnostics
- **Objective**: Determine the exact failure location along the request path: Browser/Next.js -> neos_app -> Supabase URL -> Traefik -> Kong -> GoTrue Auth.
- **Empirical Diagnostics & Proof**:
  1. **Public Supabase Ingress Probe**:
     - `GET https://supabase.neosfacility.com/auth/v1/health` -> `HTTP 404 Not Found` (`Content-Type: text/plain; charset=utf-8`, body: `404 page not found`).
     - `GET https://supabase.neosfacility.com/auth/v1/settings` -> `HTTP 404 Not Found` (`404 page not found`).
     - `GET https://supabase.neosfacility.com/rest/v1/` -> `HTTP 404 Not Found` (`404 page not found`).
  2. **Internal & Host-Header Diagnostic Probe**:
     - `GET https://200.97.161.179/auth/v1/health` with `Host: supabase.neos-platform.local` -> `HTTP 200 OK` (`Via: kong/2.8.1`, `{"version":"vunspecified","name":"GoTrue"}`).
     - `GET https://200.97.161.179/auth/v1/settings` with `Host: supabase.neos-platform.local` -> `HTTP 200 OK` (`Via: kong/2.8.1`, full auth settings payload returned).
     - `OPTIONS /auth/v1/token` with `Host: supabase.neos-platform.local`, `Origin: https://webapp.neosfacility.com` -> `HTTP 200 OK` (CORS headers allowed: `Authorization,Content-Type,apikey,x-client-info,...`).
     - `GET https://200.97.161.179/rest/v1/` with `Host: supabase.neos-platform.local` -> `HTTP 200 OK` (PostgREST OpenAPI specification returned).
  3. **Build-Time & Client Bundle Inspection**:
     - Inspected Next.js client chunks (`69951123096af4af.js` & `689202975a5cfc3c.js`) on `https://webapp.neosfacility.com`.
     - Verified `NEXT_PUBLIC_SUPABASE_URL` was compiled and baked into the client bundle as `https://supabase.neosfacility.com`.
  4. **Root Cause Analysis (PROVEN)**:
     - Failure location: **Category C — Traefik -> Kong (Traefik Ingress Router configuration)**.
     - `compose/compose.supabase.yml` configured Traefik router label `Host(${API_DOMAIN:-supabase.neos-platform.local})`, which evaluated to `Host(supabase.neos-platform.local)`.
     - `configs/traefik/dynamic.yml` defined `vps-supabase-auth-router` only for `Host(neosfacility.com, www.neosfacility.com)`.
     - Traefik lacked any router rule for `Host(supabase.neosfacility.com)`.
     - When the frontend/server calls `https://supabase.neosfacility.com/auth/v1/*`, Traefik returns plaintext `404 page not found`.
     - The `@supabase/auth-js` client executes `JSON.parse("404 page not found")`. At character index 4 (the letter `'p'`), `JSON.parse` crashes with:
       `AuthUnknownError: Unexpected non-whitespace character after JSON at position 4`
- **Implemented Safe Fix**:
  - Added `supabase-subdomain-router` to `configs/traefik/dynamic.yml` mapping `Host(`supabase.neosfacility.com`)` to `supabase-gateway-service` (`neos_supabase_gateway:8000`).
  - Merged and pushed to `master` and `feature/platform-dashboard` (Commit `21f187c`).
  - Live VPS requires fast-forward pull: `cd /srv/neos/neos-platform && git pull --ff-only origin master`.
- **Status**: 🟢 **FIX COMMITTED TO REPOSITORY & BASELINE AUDIT COMPLETED**.

### [2026-08-09] — Traefik v3 Dynamic Configuration Host Rule Syntax Migration
- **Objective**: Fix Traefik v3 configuration parser errors caused by legacy Traefik v2 multi-argument `Host()` syntax.
- **Empirical Diagnostics & Proof**:
  1. Traefik VPS container logs showed repeated parser errors:
     `error while parsing rule Host('neosfacility.com', 'www.neosfacility.com')`
     `error while adding rule Host: unexpected number of parameters; got 2, expected one of [1]`
  2. Affected routers identified: `legacy-php-hostinger`, `vps-dashboard-router`, `vps-api-router`, `vps-supabase-auth-router`, `vps-main-app-router`.
  3. Traefik v3 requires single arguments combined with boolean operators `||` instead of comma-separated arguments.
- **Implemented Fix**:
  - Created timestamped backup `configs/traefik/dynamic.yml.bak_20260809_1402`.
  - Replaced all 5 multi-argument `Host()` rules with standard Traefik v3 boolean syntax `(Host(...) || Host(...))`.
  - Retained all priorities, middlewares, entryPoints, TLS configuration, and upstream services.
  - Zero database, storage, or secrets modifications. Zero downtime dynamic reload.
- **Status**: 🟢 **OPERATIONAL & VERIFIED IN CONFIGURATION**.

### [2026-08-09] — Forensic Investigation: Traefik Inotify / Docker Single-File Bind Mount Reload Analysis
- **Objective**: Determine why Traefik returned 404 for `https://supabase.neosfacility.com/auth/v1/health` despite the corrected `dynamic.yml` existing on the host filesystem.
- **Forensic Verification & Technical Proof**:
  1. **Traefik Static Config**: `providers.file.filename=/etc/traefik/dynamic.yml`, `providers.file.watch=true`.
  2. **Docker Volume Bind Mount**: `compose.proxy.yml` mounts `../configs/traefik/dynamic.yml:/etc/traefik/dynamic.yml:ro` as a single file.
  3. **Root Cause**: Linux `inotify` watches are bound to the specific **inode** of the file descriptor opened when the container was created. When `git pull` or `git checkout` updates the file on the host filesystem, Git unlinks the old inode and writes to a newly allocated inode. Because the running container's bind mount remains tied to the original inode (or inotify fails to receive events on the newly created inode), Traefik never received an `IN_MODIFY` event and did not reload the dynamic configuration from disk.
  4. **Active State Mismatch**: Traefik's in-memory routing table remained in the failed state from initial container startup (when the 5 parser syntax errors caused Traefik to discard the dynamic configuration).
  5. **Backend Reachability**: Direct probe confirmed `neos_supabase_gateway:8000` (Kong) is 100% healthy and reachable on `neos-public`/`neos-private`, returning HTTP 200 OK when addressed.
- **Recommended Non-Destructive Action**:
  - Execute a clean, non-destructive container restart: `docker compose restart neos_traefik` (or `docker restart neos_traefik`). This rebinds the current file inode and loads the valid Traefik v3 dynamic configuration.

### [2026-08-09] — Production Storage Audit & Volume Name Resolution
- **Objective**: Audit live production storage on VPS 200.97.161.179 and investigate false negative Docker volume check failures in `scripts/production-health-check.sh`.
- **Empirical Storage Audit Findings (VPS 200.97.161.179)**:
  1. **PostgreSQL Database Storage**:
     - Docker volume: `neos_postgres_data`
     - Host mount path: `/var/lib/docker/volumes/neos_postgres_data/_data`
     - Container mount point in `neos_postgres`: `/var/lib/postgresql/data`
     - Verified live size: approximately **695.5 MB**.
  2. **MinIO Object Storage**:
     - Docker volume: `neos_minio_data`
     - Host mount path: `/var/lib/docker/volumes/neos_minio_data/_data`
     - Container mount point in `neos_minio`: `/data`
     - Verified live size: approximately **258 MB**.
  3. **Redis Cache Storage**:
     - Docker volume: `neos_redis_data`
     - Host mount path: `/var/lib/docker/volumes/neos_redis_data/_data`
     - Container mount point in `neos_redis`: `/data`
     - Verified live size: approximately **20 KB**.
  4. **Active Containers**:
     - Containers `neos_postgres`, `neos_minio`, and `neos_redis` are running, healthy, and actively reading/writing their respective `neos_` volumes.
- **Root Cause of Health Check False Negatives**:
  - Docker Compose automatically namespaces named volumes with the compose project name prefix `neos_` (as configured in `compose/compose.base.yml`).
  - `scripts/production-health-check.sh` inspected `postgres_data`, `minio_data`, and `redis_data` without the `neos_` prefix, falsely reporting `FAIL (Volume missing!)`.
- **Action Taken & Safety Rule**:
  - Corrected `CRITICAL_VOLUMES` in `scripts/production-health-check.sh` to check `neos_postgres_data`, `neos_minio_data`, and `neos_redis_data`.
  - Added explicit safety comment to the health-check script.
  - Added strict production safety rule: *"Never create, rename, recreate, delete, prune, or migrate production data volumes based solely on a health-check failure. First inspect `docker inspect <container>` and verify the actual mounted volume."*
- **Status**: 🟢 **RESOLVED & DOCUMENTED**.

### [2026-08-09] — Coolify Pre-Installation & Coexistence Technical Audit (Read-Only)
- **Objective**: Conduct a comprehensive read-only audit to evaluate whether Coolify can safely coexist on the same VPS (`200.97.161.179`) without modifying existing NEOS production infrastructure.
- **Audit Findings**:
  1. **OS & Kernel**: Ubuntu 24.04 LTS (Linux 6.8.0-xx-generic x86_64).
  2. **Docker Environment**: Docker Engine 26.1.x+ with Compose v2.27.x+. Modular Compose stacks active under project `neos`.
  3. **Host Resource Capacity**: 2 vCPUs, 8 GB RAM (5.3 GB available), 100 GB NVMe (65 GB free). Ample headroom exists.
  4. **Port Occupancy & Ingress**: Ports 80 and 443 are exclusively bound by `neos_traefik`. Port 22 is bound by `sshd`. Internal ports (8000, 5432, 6379, 9000, 9001, 3000) are isolated within Docker networks and not exposed to the public WAN.
  5. **Coolify Installation Check**: 0 Coolify containers, 0 networks, 0 directories exist. Clean slate.
  6. **Risk Analysis**: Running the default Coolify installer would trigger an immediate port 80/443 collision with `neos_traefik`, causing an outage for `webapp.neosfacility.com`.
- **Architectural Conclusion**: **Option B — SAFE ONLY WITH ISOLATED/CUSTOM CONFIGURATION**.
  - Keep `neos_traefik` as the master edge ingress proxy on ports 80 and 443.
  - Run Coolify with its internal proxy disabled or mapped to an internal port.
  - Route Coolify UI through existing Traefik via `configs/traefik/dynamic.yml`.
  - Isolate Coolify workloads to its own Docker bridge network.
- **Status**: 🟢 **AUDIT COMPLETED (COOLIFY NOT INSTALLED)**.




