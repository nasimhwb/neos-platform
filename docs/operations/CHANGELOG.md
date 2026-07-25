# Operational Changelog

All meaningful changes to the NEOS Platform codebase, API endpoints, database schemas, and documentation are tracked in this file.

---

## [2026-07-25] Module-by-Module Stabilization Sprint Completed

### Fixed
- **Orders Module (`f0eb43f3`)**: Restricted `x-neos-session-id` header in `src/lib/supabase/client.ts` strictly to internal relative `/api/` endpoints, eliminating CORS `OPTIONS` preflight failures on external Supabase API requests.
- **Clients Module (`506e6925`)**: Corrected invalid string wildcard pattern `"*${escapedSearch}*"` in `src/hooks/useClientsData.ts` to use standard SQL `%` wildcards (`%${escapedSearch}%`) for PostgREST `ilike` operations.
- **Users & Employee Sync**: Validated user creation, CSV bulk importer, geofence home coordinate settings, reporting manager assignments, and employee directory linking.
- **Roles & EAPC Framework**: Verified Enterprise Access & Permission Control Center, predefined role templates, and real-time permission simulator.
- **CRM, HR, Attendance & Complaints**: Verified Kanban stage tracking, biometric sync endpoints, `#COMPLAINT` handling, and PSS resolution metrics.
- **Inventory, Reports, Settings, Profile, Notifications & Audit Logs**: Confirmed multi-warehouse inventory stock audits, materialized view reporting aggregations, self-service profile updates, notification hub deep links, and audit log tracking.

---

## [2026-07-24] Tasks Module Stabilization & Infrastructure Prep

### Fixed
- **Tasks Module Optimization**: Implemented progressive loading and persistent localStorage caching (`6496d84a`).
- **Gateway & CORS**: Added white-list entry for `https://test.neosfacility.com` in Kong API Gateway and GoTrue auth service (`cb1ea45d`).
- **Infrastructure Docs**: Added `PRODUCTION_MIGRATION_CHECKLIST.md` and updated operational runbooks.
