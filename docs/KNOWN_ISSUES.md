# Known Issues

This document tracks all identified, ongoing, and resolved issues across the NEOS Platform infrastructure, backend database, authentication layers, and web application components.

| Issue | Status | Evidence | Root Cause | Solution | Owner | Date |
|---|---|---|---|---|---|---|
| SSH Port 22 Unreachable on VPS | RESOLVED | `nc -zv 200.97.161.179 22` timed out | Systemd `ssh.socket` override bound port 6432 instead of 22 | Reconfigured `ssh.socket` to listen globally on `0.0.0.0:22` | SRE Team | 2026-07-24 |
| Frontend Auth CORS Failure on test.neosfacility.com | RESOLVED | Browser console origin blocked error during login | Kong and GoTrue allowed origin lists omitted `test.neosfacility.com` | Added `https://test.neosfacility.com` to `KONG_CORS_ORIGINS` and `GOTRUE_URI_ALLOW_LIST` | Backend Team | 2026-07-24 |
| Frontend `profiles` Query 404/Error | RESOLVED | Supabase query `.from('profiles')` returned relation missing | Migration script created `client_profiles` without `profiles` alias view | Created `public.profiles` view aliasing `public.client_profiles` | DB Team | 2026-07-22 |
| Gemini API Key missing in VPS runtime environment | PENDING VPS SYNC | AI features return HTTP 500 / key unconfigured error on VPS | `.env` on VPS was missing `GEMINI_API_KEY` configuration present in local `.env.local` | Update `/srv/neos/neos-platform/.env` on VPS and restart Supabase containers | DevOps Team | 2026-07-24 |
| SMTP Mailer Warning in Auth Diagnostics | DEFERRED / OPEN | `make diagnose-auth` outputs SMTP warn message | Production mailer credentials unconfigured in dev/staging compose stack | Configure production SMTP credentials in `.env` prior to final production cutover | SRE Team | 2026-07-24 |
