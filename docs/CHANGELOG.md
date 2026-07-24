# Changelog

All meaningful changes to the NEOS Platform shared infrastructure repository are documented in this file.

## [2026-07-24]

### Fixed
- **Dashboard Dockerfile & Compose Supabase Build Args**:
  - Injected `ARG NEXT_PUBLIC_PLATFORM_PROVIDER=self-hosted` and `ARG NEXT_PUBLIC_SUPABASE_URL=https://supabase.neosfacility.com` into `dashboard/Dockerfile` builder and runner stages.
  - Configured `build.args` and runtime `environment` declarations in `compose/compose.dashboard.yml` for the `dashboard` service.
  - *Reason*: `next build` compiled without Supabase self-hosted variables, causing the container to query Cloud Supabase where user profiles were missing (`HTTP 404 Profile not found`).
  - *Impact*: Ensures Next.js server & client bundles bind directly to `https://supabase.neosfacility.com`.

- **Kong CORS & GoTrue URI Whitelist** (`cb1ea45d94dca22de74cad4d6d6e1b9d33055fe1`): Added `https://test.neosfacility.com` to `KONG_CORS_ORIGINS` and `GOTRUE_URI_ALLOW_LIST` in compose and environment configs to unblock staging frontend authentication requests.

---

## [2026-07-22]

### Fixed
- **Auth Schema & Profiles View** (`063a40d52ef22336ed91aa30af27417f355231a6`):
  - Created `public.profiles` view aliasing `public.client_profiles`.
  - Added backfill script for missing `auth.identities` records.
  - Normalized `auth.users` raw metadata to align user profile syncing.
