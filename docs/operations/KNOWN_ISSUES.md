# Known Operations & Technical Issues

This document tracks identified, ongoing, and resolved technical issues across all 15 NEOS Platform application modules and shared infrastructure services.

---

| ID | Module / Service | Issue Description | Status | Root Cause | Resolution / Action Taken | Date |
|---|---|---|---|---|---|---|
| ISSUE-001 | Infrastructure | SSH Port 22 Unreachable on VPS | RESOLVED | Systemd `ssh.socket` override bound port 6432 instead of 22 | Reconfigured `ssh.socket` to listen globally on `0.0.0.0:22` | 2026-07-24 |
| ISSUE-002 | Auth / Gateway | CORS Failure on test.neosfacility.com | RESOLVED | Gateway allowed origin list omitted domain | Added origin to `KONG_CORS_ORIGINS` & `GOTRUE_URI_ALLOW_LIST` | 2026-07-24 |
| ISSUE-003 | Auth / Database | Missing `profiles` schema relation | RESOLVED | Database migration omitted `profiles` alias | Created `public.profiles` view aliasing `client_profiles` | 2026-07-22 |
| ISSUE-004 | Tasks | Tasks page initial render delay | RESOLVED | Synchronous heavy RPC calls during page mount | Implemented progressive loading and persistent localStorage cache | 2026-07-24 |
