# VPS Staging Handoff Document

**Target VPS Node:** `200.97.161.179` (Hostinger VPS)  
**Staging Endpoint:** `https://test.neosfacility.com`  
**Repository Branch:** `feature/platform-dashboard`  
**Last Updated:** 2026-07-24  

---

## 1. Current Objective
Deploy, verify, and lock operational stability for the NEOS Platform multi-tenant SaaS shared infrastructure stack on the Hostinger VPS staging environment, ensuring full compatibility for frontend applications hosted at `https://test.neosfacility.com`.

---

## 2. Current Blockers
- **None (Critical)**: SSH, Traefik, PostgreSQL, GoTrue, and Kong CORS configurations are fully functional.
- **Minor / Administrative**: VPS `.env` file requires manual update with local secrets (Gemini API keys, Firebase configuration) before AI and push notification features can be executed on staging container restarts.

---

## 3. Current Readiness
- **Infrastructure**: 🟢 **100% Ready** (SSH, Firewall, Docker Compose, Traefik TLS termination operational).
- **Database Engine**: 🟢 **100% Ready** (PostgreSQL 15 running, Supabase role hierarchies initialized, PostGIS/vector extensions enabled).
- **Authentication**: 🟢 **100% Ready** (GoTrue auth service operational, CORS whitelist configured for `test.neosfacility.com`).
- **Database Schema**: 🟢 **100% Ready** (`public.client_profiles`, `public.profiles` view, `public.tasks`, RLS policies deployed).

---

## 4. Latest Deployment
- **Commit**: `cb1ea45d94dca22de74cad4d6d6e1b9d33055fe1` ("fix: add test.neosfacility.com to Kong CORS origins and GoTrue URI allow list").
- **Deployment Script**: `./scripts/deploy.sh`
- **Compose Files**: `docker-compose.yml`, `compose/compose.supabase.yml`

---

## 5. Environment Status
| Service | Container Status | Endpoint / Port | Health Verification |
|---|---|---|---|
| Traefik Gateway | Running | `:80`, `:443` | `HTTP 200` TLS certificate valid |
| Kong API Gateway | Running | `:8000`, `:8443` | CORS Headers active for `test.neosfacility.com` |
| PostgreSQL 15 | Running | `:5432` | DB accepting pooler & local connections |
| Supabase Auth (GoTrue) | Running | `/auth/v1` | `/auth/v1/health` returned `HTTP 200` |
| Redis Cache | Running | `:6379` | Memory & double-persistence active |
| MinIO Storage | Running | `:9000`, `:9001` | S3 API functional |
| Prometheus & Grafana | Running | `:9090`, `:3000` | Metric scraping active |

---

## 6. Verified Findings
1. **SSH Connectivity**: Systemd `ssh.socket` confirmed listening on `0.0.0.0:22` and accessible externally.
2. **CORS Headers**: Kong API gateway correctly appends Access-Control-Allow-Origin headers for `https://test.neosfacility.com`.
3. **Database Schema Compatibility**: The `public.profiles` view successfully resolves frontend Supabase queries without schema mismatch errors.
4. **User Auth Flow**: Supabase auth tokens issue successfully for seeded test users (34 existing active user records).

---

## 7. Pending Work
1. **VPS `.env` Secret Sync**: Copy runtime AI (`GEMINI_API_KEY`) and Firebase parameters to `/srv/neos/neos-platform/.env` on VPS.
2. **Container Restart & Sanity Check**: Run `docker compose --env-file .env -f compose/compose.supabase.yml restart` on VPS.
3. **Automated End-to-End Test Run**: Execute full browser regression suite on `https://test.neosfacility.com`.
