# Changelog

All meaningful changes to the NEOS Platform shared infrastructure repository are documented in this file.

## [2026-07-24]

### Added
- **Production Migration Checklist**: Created `PRODUCTION_MIGRATION_CHECKLIST.md` documenting infrastructure readiness (SSH, Docker, Traefik, UFW, PostgreSQL 15, GoTrue Auth).
- **Mandatory Documentation Framework**: Created standardized operational documentation (`docs/README.md`, `docs/KNOWN_ISSUES.md`, `docs/CHANGELOG.md`, `docs/VPS_STAGING_HANDOFF.md`, `docs/MIGRATION_PLAN.md`, `docs/investigations/`, `docs/reports/`).

### Fixed
- **Kong CORS & GoTrue URI Whitelist** (`cb1ea45d94dca22de74cad4d6d6e1b9d33055fe1`): Added `https://test.neosfacility.com` to `KONG_CORS_ORIGINS` and `GOTRUE_URI_ALLOW_LIST` in compose and environment configs to unblock staging frontend authentication requests.
  - *Reason*: Cross-origin requests from `test.neosfacility.com` were blocked by Kong API Gateway.
  - *Impact*: Restored webapp authentication capability on staging endpoint.

---

## [2026-07-22]

### Fixed
- **Auth Schema & Profiles View** (`063a40d52ef22336ed91aa30af27417f355231a6`):
  - Created `public.profiles` view aliasing `public.client_profiles`.
  - Added backfill script for missing `auth.identities` records.
  - Normalized `auth.users` raw metadata to align user profile syncing.
  - Added RLS rules and grants for `tasks`, `suggestions`, `error_logs`, and HR tables.
  - *Reason*: Frontend query failures when accessing profile and task data.
  - *Impact*: Unblocked 300+ frontend `.from('profiles')` queries.

### Documentation
- **Production Recovery Handoff Report** (`f04e7f2e9d4ea008d31ed89272529e4161c63059`): Added step-by-step resume guide for VPS staging deployments (`docs/HANDOFF_REPORT.md`).
- **Environment Key Sync Status** (`ba1d3c5d01400c12fe9c4ed83a62238faa20b064`): Added environment variable mapping documentation across local development and VPS staging environments.
