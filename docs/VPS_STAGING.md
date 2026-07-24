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
| Web Application Container | 🟡 Pending Rebuild | 75% | Requires `--no-cache` rebuild to purge stale Cloud Supabase URL |

**Overall Staging Readiness**: **95%**

---

## 2. Active Services

| Service Name | Container Name | Endpoint / Port | Status | Health Verification |
|---|---|---|---|---|
| Traefik Gateway | `neos_traefik` | `:80`, `:443` | Running | `HTTP 200` (Valid SSL) |
| Kong API Gateway | `neos_kong` | `:8000`, `:8443` | Running | CORS origin active |
| PostgreSQL 15 | `neos_postgres` | `:5432` | Running | Healthy |
| Supabase Auth (GoTrue) | `neos_gotrue` | `/auth/v1` | Running | `/auth/v1/health` -> `HTTP 200` |
| Web Application | `dashboard` / `neos_webapp` | `:3000` | Running | Rebuild pending |

---

## 3. Known Blockers & Remediation Runbook

### Blocker 1: Stale Cloud Supabase URL Baked into Web App Container
* **Symptoms**: `/api/tasks` returns `404 Profile not found`.
* **Root Cause**: `next build` baked Cloud Supabase URL into Next.js bundle during previous image build.
* **Remediation Commands**:
  ```bash
  cd /srv/neos/neos-platform
  docker compose --env-file .env -f compose/compose.apps.yml build --no-cache dashboard
  docker compose --env-file .env -f compose/compose.apps.yml up -d --no-deps dashboard
  ```

---

## 4. Module Status Matrix

- **Authentication**: 🟢 Complete (`/login` succeeds with `tester@neosfacility.com`)
- **Tasks Module**: 🟡 In Progress (Database schema verified; container rebuild pending)
- **User Management**: 🟡 In Progress (`/dashboard/admin/users`)
- **Enterprise Permissions**: 🟡 In Progress (`/dashboard/admin/permissions`)
- **Profile Module**: 🟢 Complete (`/dashboard/profile`)
- **HR & Employees**: 🟢 Database Ready (`public.employees`)
- **Orders & Operations**: 🟢 Database Ready (`public.orders`)
