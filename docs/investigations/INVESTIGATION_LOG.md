# NEOS Platform — Engineering Investigation Log

This document is a chronological engineering journal recording all technical investigations, root cause analyses, and diagnostic proofs.

---

## [2026-07-25] — Live /api/tasks Request Trace & PostgREST FK Resolution

* **Engineer / AI**: Antigravity (Google DeepMind Team)
* **Branch**: `master` (neos-app) / `feature/platform-dashboard` (neos-platform)
* **Commit**: `91a2f71d` / `26e114b`
* **Objective**: Prove the exact live request path from browser to database and resolve PostgREST schema cache error.
* **Empirical Trace Evidence**:
  1. Inspected server logs on VPS container `neos_app`: `src/app/api/tasks/route.ts` executed and attempted profile query via `supabaseAdmin`.
  2. PostgREST returned `PGRST301`: `JWTClaimsSetDecodeError "Error in $: Failed reading: satisfy. Expecting ',' or '}' at '\\178\\&004'"`.
  3. Identified root cause: `/srv/neos/neos-app/.env` (used by `neos_app` container) contained corrupted `SUPABASE_SERVICE_ROLE_KEY` bytes (`IkJXVCJ9` / `BWT`).
  4. Updated `/srv/neos/neos-app/.env` with valid HMAC-SHA256 key (`IkpXVCJ9` / `JWT`) and rebuilt `neos_app`.
  5. Next query failed with `PGRST301`: `"Could not find a relationship between 'tasks' and 'task_assignees' in the schema cache"`.
  6. Added missing Foreign Key constraints:
     ```sql
     ALTER TABLE public.task_assignees ADD CONSTRAINT fk_task_assignees_tasks FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;
     ALTER TABLE public.task_assignees ADD CONSTRAINT fk_task_assignees_profiles FOREIGN KEY (profile_id) REFERENCES public.client_profiles(id) ON DELETE CASCADE;
     NOTIFY pgrst, 'reload schema';
     ```
  7. Re-tested `GET /api/tasks?userId=05a7cbdc-a7e3-47aa-afd5-fcc57461f3ae`: **`HTTP 200 OK`**, returned **59 active tasks**!
* **Status**: 🟢 RESOLVED & VERIFIED (HTTP 200 OK, 59 tasks returned).

---

## [2026-07-24] — VPS Staging Dashboard Container Deployment & Verification

* **Engineer / AI**: Antigravity (Google DeepMind Team)
* **Branch**: `feature/platform-dashboard`
* **Commit**: `5723f0d`
* **Objective**: Rebuild and redeploy `neos_dashboard` container on Hostinger VPS staging host.
* **Status**: 🟢 RESOLVED.
