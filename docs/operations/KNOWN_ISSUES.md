# Known Operations & Technical Issues

This document tracks all identified, ongoing, and resolved technical issues across all NEOS Platform application modules, backend database, authentication layers, and shared infrastructure services.

---

| ID / Issue | Module / Service | Status | Evidence | Root Cause | Resolution / Action Taken | Owner | Date |
|---|---|---|---|---|---|---|---|
| ISSUE-001 | Infrastructure | SSH Port 22 Unreachable on VPS | RESOLVED | `ssh.socket` logs | Systemd `ssh.socket` override bound port 6432 instead of 22 | Reconfigured `ssh.socket` to listen globally on `0.0.0.0:22` | DevOps | 2026-07-24 |
| ISSUE-002 | Auth / Gateway | CORS Failure on test.neosfacility.com | RESOLVED | Browser network preflight error | Gateway allowed origin list omitted domain | Added origin to `KONG_CORS_ORIGINS` & `GOTRUE_URI_ALLOW_LIST` | DevOps | 2026-07-24 |
| ISSUE-003 | Auth / Database | Missing `profiles` schema relation | RESOLVED | Supabase query error | Database migration omitted `profiles` alias | Created `public.profiles` view aliasing `client_profiles` | DB Team | 2026-07-22 |
| ISSUE-004 | Tasks | Tasks page initial render delay | RESOLVED | DevTools timing | Synchronous heavy RPC calls during page mount | Implemented progressive loading and persistent localStorage cache | App Team | 2026-07-24 |
| ISSUE-005 | Traefik | Traefik returning `404 page not found` for `test.neosfacility.com` | RESOLVED | `docker ps` shows `neos_app Up (healthy)`; browser loads Tasks dashboard | Traefik `loadbalancer.healthcheck.path=/api/health` returned HTTP 404 because endpoint was unmapped in `neos-app` | Created `GET /api/health` in `neos-app`, rebuilt image, and restored Traefik backend routing | DevOps / App Team | 2026-07-25 |
| ISSUE-006 | Tasks / Auth | `/api/tasks` returns `404 Profile not found` | RESOLVED & VERIFIED | Browser E2E test loads 61 tasks; CRUD operations pass | Corrupted `SUPABASE_SERVICE_ROLE_KEY` in `/srv/neos/neos-app/.env` caused PostgREST to return PGRST301 JWT decode error | Purged corrupted key in `/srv/neos/neos-app/.env`, rebuilt `neos_app`, added FK constraints to `task_assignees` | App Team | 2026-07-25 |
| ISSUE-007 | PostgREST / DB | PostgREST missing relationship `tasks` to `task_assignees` | RESOLVED | PostgREST schema error resolved; 200 OK returned | Missing Foreign Key constraints `fk_task_assignees_tasks` and `fk_task_assignees_profiles` | Added FK constraints in PostgreSQL and sent `NOTIFY pgrst, 'reload schema'` | DB Team | 2026-07-25 |
| ISSUE-008 | Security / Auth | VPS `.env` JWT Key Corruption | RESOLVED | PostgREST returned `500 JWTClaimsSetDecodeError` | `SUPABASE_SERVICE_ROLE_KEY` contained corrupted header bytes (`IkJXVCJ9`) | Purged corrupted header and updated `.env` files with valid HMAC-SHA256 service key | DevOps Team | 2026-07-24 |
