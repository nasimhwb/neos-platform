# Known Issues

This document tracks all identified, ongoing, and resolved issues across the NEOS Platform infrastructure, backend database, authentication layers, and web application components.

| Issue | Status | Evidence | Root Cause | Solution | Owner | Date |
|---|---|---|---|---|---|---|
| Traefik returning `404 page not found` for `test.neosfacility.com` | RESOLVED | `docker ps` shows `neos_app Up (healthy)`; browser loads Tasks dashboard | Traefik `loadbalancer.healthcheck.path=/api/health` returned HTTP 404 because endpoint was unmapped in `neos-app` | Created `GET /api/health` in `neos-app`, rebuilt image, and restored Traefik backend routing | DevOps / App Team | 2026-07-25 |
| `/api/tasks` returns `404 Profile not found` | RESOLVED & VERIFIED | Browser E2E test loads 61 tasks; CRUD operations pass | Corrupted `SUPABASE_SERVICE_ROLE_KEY` in `/srv/neos/neos-app/.env` caused PostgREST to return PGRST301 JWT decode error | Purged corrupted key in `/srv/neos/neos-app/.env`, rebuilt `neos_app`, added FK constraints to `task_assignees` | App Team | 2026-07-25 |
| PostgREST missing relationship `tasks` to `task_assignees` | RESOLVED | PostgREST schema error resolved; 200 OK returned | Missing Foreign Key constraints `fk_task_assignees_tasks` and `fk_task_assignees_profiles` | Added FK constraints in PostgreSQL and sent `NOTIFY pgrst, 'reload schema'` | DB Team | 2026-07-25 |
| VPS `.env` JWT Key Corruption | RESOLVED | PostgREST returned `500 JWTClaimsSetDecodeError` | `SUPABASE_SERVICE_ROLE_KEY` contained corrupted header bytes (`IkJXVCJ9`) | Purged corrupted header and updated `.env` files with valid HMAC-SHA256 service key | DevOps Team | 2026-07-24 |
