# NEOS Platform — Live Production Cutover Migration Checklist

**Date:** 2026-08-02  
**Target Host:** Hostinger VPS (`200.97.161.179`)  
**Domain:** `https://webapp.neosfacility.com`  

---

## Pre-Cutover Verification (T-60 Minutes)

- [x] **Repository Sync**: Verify `neos-platform` (`feature/platform-dashboard`) and `neos-app` (`master`) local and VPS git HEADs match.
- [x] **Container Health**: Verify `neos_app`, `neos_postgres`, `neos_supabase_auth`, `neos_supabase_gateway`, `neos_traefik` containers are `running (healthy)`.
- [x] **Schema Integrity**: Verify `public.profiles` view, `get_user_order_counts()` RPC, `fk_suggestions_assigned_developer` FK, and PostgREST schema cache are reloaded.
- [x] **CORS Configuration**: Verify Kong `configs/supabase/kong.yml` permits `content-profile`, `x-neos-session-id`, `authorization`, `accept-profile`.
- [x] **Traefik Routing**: Verify `test-staging-router` and `vps-main-app-router` rules in `configs/traefik/dynamic.yml`.

---

## Execution Phase (Cutover Window: 5 Minutes)

1. **Step 1 — Database Data Sync Catch-up** (T-15 Min):
   ```bash
   # Run pg_dump export from Supabase Cloud and apply delta to neos_postgres on VPS
   pg_dump "postgres://..." --data-only --table=public.orders --table=public.tasks > /tmp/delta.sql
   docker exec -i neos_postgres psql -U postgres -d postgres < /tmp/delta.sql
   ```
2. **Step 2 — Storage Buckets Sync** (T-10 Min):
   ```bash
   # Sync S3 assets from Supabase Cloud to MinIO neos-storage
   mc mirror supabase-cloud/storage-bucket minio-vps/supabase-storage
   ```
3. **Step 3 — DNS Cutover (Cloudflare)** (T-0 Min):
   * Update Cloudflare CNAME record for `webapp.neosfacility.com`:
     * **Old Value:** `cname.vercel-dns.com`
     * **New Value:** `200.97.161.179` (or `test.neosfacility.com` A record)
   * Set TTL to `Auto` / `120s`.

---

## Post-Cutover Validation (T+15 Minutes)

- [ ] Verify `https://webapp.neosfacility.com/login` loads HTML 200 OK.
- [ ] Log in as `tester@neosfacility.com` and `admin@neosfacility.com`.
- [ ] Verify Dashboard, Tasks, Orders, Users, Suggestions, HR, and Reports pages.
- [ ] Verify no CORS preflight blocks or PostgREST 500 errors in browser network panel.
- [ ] Confirm Uptime Kuma and Grafana alerting metrics are green.
