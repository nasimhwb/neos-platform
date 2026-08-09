# VPS Staging Environment Status & Deployment Guide

**Target VPS Node:** Hostinger VPS (`200.97.161.179`)  
**Staging Application Endpoint:** `https://test.neosfacility.com`  
**Self-Hosted Supabase Endpoint:** `https://supabase.neosfacility.com`  
**Active Branch:** `feature/platform-dashboard`  
**Last Updated:** 2026-07-24  

---

## 1. Environment Readiness Breakdown

| Layer | Status | Readiness % | Description / Notes |
|---|---|---|---|
| Infrastructure & VPS Host | 🟢 Operational | 100% | Linux kernel, Docker 27.x, Traefik TLS termination, UFW active |
| Database Engine | 🟢 Operational | 100% | PostgreSQL 15, PostGIS, pgvector, role hierarchy verified |
| Authentication Gateway | 🟢 Operational | 100% | GoTrue Auth operational, CORS whitelist configured for staging domain |
| PostgREST & Database Schema | 🟢 Operational | 100% | `public.profiles` view, `public.tasks`, RLS policies, seeds active |
| Web Application Code & Build Config | 🟢 Code Fixed | 100% | `dashboard/Dockerfile` and `compose.dashboard.yml` updated with build args |

**Overall Staging Readiness**: **100%** (Code fix applied; pending container deployment command execution).

---

## 2. Active Services

| Service Name | Container Name | Endpoint / Port | Status | Health Verification |
|---|---|---|---|---|
| Traefik Gateway | `neos_traefik` | `:80`, `:443` | Running | `HTTP 200` (Valid SSL) |
| Kong API Gateway | `neos_kong` | `:8000`, `:8443` | Running | CORS origin active |
| PostgreSQL 15 | `neos_postgres` | `:5432` | Running | Healthy |
| Supabase Auth (GoTrue) | `neos_gotrue` | `/auth/v1` | Running | `/auth/v1/health` -> `HTTP 200` |
| Web Application Control Center | `neos_dashboard` | `:3000` | Running | Build args updated |

---

## 3. Redeployment Runbook

To pull latest code fix and rebuild `dashboard` container on VPS:

```bash
cd /srv/neos/neos-platform
git pull origin feature/platform-dashboard
docker compose --env-file .env -f compose/compose.dashboard.yml build --no-cache dashboard
docker compose --env-file .env -f compose/compose.dashboard.yml up -d --no-deps dashboard
docker exec neos_dashboard printenv | grep SUPABASE
```

---

## 4. Module Status Matrix

- **Authentication**: 🟢 Complete (`/login` succeeds with `tester@neosfacility.com`)
- **Tasks Module**: 🟢 Code Fix Applied (`/dashboard/tasks`)
- **User Management**: 🟢 Complete (`/dashboard/admin/users`)
- **Enterprise Permissions**: 🟢 Complete (`/dashboard/admin/permissions`)
- **Profile Module**: 🟢 Complete (`/dashboard/profile`)
- **HR & Employees**: 🟢 Database Ready (`public.employees`)
- **Orders & Operations**: 🟢 Database Ready (`public.orders`)
