# Changelog

All notable changes to the NEOS Platform codebase, infrastructure, and deployment configurations are documented in this file.

## [Unreleased] - 2026-07-25

### Fixed
- **Traefik Health Check Endpoint**: Added `GET /api/health` returning HTTP 200 status in `neos-app` (`src/app/api/health/route.ts`) to fix Traefik backend load balancer eviction.
- **Tasks Module PostgREST Relationship**: Added foreign key constraints `fk_task_assignees_tasks` and `fk_task_assignees_profiles` to `public.task_assignees` table in PostgreSQL and issued `NOTIFY pgrst, 'reload schema'`.
- **JWT Key Header Corruption**: Replaced corrupted service key in `/srv/neos/neos-app/.env` with valid HMAC-SHA256 token signed with `ChangeThisToASuperSecureJWTSecretKey123!`.

### Verified
- **Staging End-to-End Tasks CRUD**: Verified browser login as `tester@neosfacility.com`, task creation, editing, deletion, searching, and persistence on `https://test.neosfacility.com/dashboard/tasks`.
- **Users & Suggestions Application Audit**: Audited Users (`/dashboard/admin/users`) and Suggestions & Errors (`/dashboard/admin/suggestions`) pages on live staging environment, captured screenshot evidence, console/network traces, and diagnosed root causes in `APPLICATION_AUDIT.md`.

