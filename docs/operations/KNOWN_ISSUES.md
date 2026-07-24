# Known Issues

This document tracks all identified, ongoing, and resolved issues across the NEOS Platform infrastructure, backend database, authentication layers, and web application components.

| Issue | Status | Evidence | Root Cause | Solution | Owner | Date |
|---|---|---|---|---|---|---|
| `/api/tasks` returns `404 Profile not found` | RESOLVED & DEPLOYED | Container printenv verifies `NEXT_PUBLIC_SUPABASE_URL=https://supabase.neosfacility.com` | `dashboard/Dockerfile` lacked `ARG NEXT_PUBLIC_SUPABASE_URL` during `next build` | Injected build ARGs & env vars into `dashboard/Dockerfile` and `compose.dashboard.yml`; rebuilt on VPS | DevOps / App Team | 2026-07-24 |
| VPS `.env` JWT Key Corruption | RESOLVED | PostgREST returned `500 JWTClaimsSetDecodeError` | `SUPABASE_SERVICE_ROLE_KEY` in `.env` contained corrupted header bytes (`IkJXVCJ9`) | Purged corrupted header and updated `.env` with valid HMAC-SHA256 service key | DevOps Team | 2026-07-24 |
| SSH Port 22 Timeout over IPv4 | RESOLVED (WORKAROUND) | SSH over IPv4 timed out; SSH over IPv6 (`root@[64:ff9b::c861:a1b3]`) connected | ISP / network IPv4 routing filter on port 22 | Use IPv6 target `root@[64:ff9b::c861:a1b3]` for SSH automated deployments | SRE Team | 2026-07-24 |
| Frontend Auth CORS Failure on test.neosfacility.com | RESOLVED | Browser console origin blocked error during login | Kong and GoTrue allowed origin lists omitted `test.neosfacility.com` | Added `https://test.neosfacility.com` to `KONG_CORS_ORIGINS` and `GOTRUE_URI_ALLOW_LIST` | Backend Team | 2026-07-24 |
| Frontend `profiles` Query 404/Error | RESOLVED | Supabase query `.from('profiles')` returned relation missing | Migration script created `client_profiles` without `profiles` alias view | Created `public.profiles` view aliasing `public.client_profiles` | DB Team | 2026-07-22 |
