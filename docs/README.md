# NEOS Platform Documentation Index

Welcome to the NEOS Platform shared infrastructure and operational documentation. This document serves as the primary entry point for architecture, deployment procedures, and environment configuration.

---

## 1. Architecture

### System Overview
NEOS Platform provides a unified, self-hosted backend infrastructure and gateway for multi-tenant SaaS applications (ERP, CRM, HRMS, Billing, and Inventory).

```
                      +-----------------------------+
                      |       Clients / Web         |
                      |   test.neosfacility.com     |
                      +--------------+--------------+
                                     |
                                  (HTTPS)
                                     v
                      +-----------------------------+
                      |        Traefik / Nginx       |
                      |    (Reverse Proxy & SSL)    |
                      +--------------+--------------+
                                     |
               +---------------------+---------------------+
               |                     |                     |
               v                     v                     v
      +-----------------+   +-----------------+   +-----------------+
      | PostgreSQL 15   |   |   Redis 7       |   | MinIO S3        |
      | (Supabase Db)   |   | (Cache/Session) |   | (Object Store)  |
      +-----------------+   +-----------------+   +-----------------+
               ^                     ^                     ^
               |                     |                     |
      +--------+---------------------+---------------------+--------+
      |               Supabase Service Stack                        |
      | (GoTrue Auth, PostgREST API, Realtime, Storage, Kong)       |
      +-------------------------------------------------------------+
```

### Key Components
1. **API Gateway / Edge Proxy (Kong & Traefik/Nginx)**: Handles TLS termination (Let's Encrypt), CORS policy enforcement, rate limiting, and request routing to internal services.
2. **Database Layer (PostgreSQL 15)**: Contains core application tables, `auth.users`, `public.client_profiles`, `public.profiles` view, `public.tasks`, `public.employees`, spatial indices, and Row Level Security (RLS) policies.
3. **Authentication Engine (Supabase GoTrue)**: Manages JWT lifecycle, user identity mappings (`auth.identities`), password hashing (Bcrypt/Argon2), and identity verification.
4. **Caching & Session Storage (Redis 7)**: Low-latency state caching and token revocation checks with AOF/RDB double persistence.
5. **Object Storage (MinIO)**: S3-compatible asset and file storage platform.
6. **Observability Stack**: Prometheus metrics collection, Grafana Loki log aggregation, Promtail shipping, and Grafana dashboard visualization.

---

## 2. Deployment

### Host VPS Environment
- **Provider**: Hostinger VPS
- **IP Address**: `200.97.161.179`
- **OS**: Ubuntu 24.04 LTS
- **Runtime**: Docker Engine 26+ & Docker Compose v2
- **Repo Location on VPS**: `/srv/neos/neos-platform` (or `/srv/neos-platform`)

### Deployment Procedure

#### Step 1: Provisioning & Code Sync
```bash
cd /srv/neos/neos-platform
git fetch origin
git checkout feature/platform-dashboard
git pull origin feature/platform-dashboard
```

#### Step 2: Environment File Verification
Ensure `/srv/neos/neos-platform/.env` contains all environment secrets (Gemini API keys, Firebase secrets, JWT secrets, Postgres credentials).

#### Step 3: Container Stack Launch
```bash
# Start infrastructure services
docker compose --env-file .env -f docker-compose.yml up -d

# Start Supabase services
docker compose --env-file .env -f compose/compose.supabase.yml up -d
```

#### Step 4: Database Schema Synchronization
```bash
# Run schema and role initialization
make fix-auth
make diagnose-auth
```

---

## 3. Environment

### Required Configuration Keys
Environment parameters are defined in `.env` (derived from `.env.example` and local `.env.local` synchronization):

| Variable Category | Key Names | Description |
|---|---|---|
| **Database** | `POSTGRES_PASSWORD`, `POSTGRES_DB`, `POSTGRES_PORT` | PostgreSQL credentials and connection target |
| **Auth & Security** | `JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY`, `SITE_URL` | Supabase GoTrue authentication & authorization tokens |
| **AI Integration** | `GEMINI_API_KEY` | Comma-separated Gemini API keys for dashboard AI features |
| **Push Notifications** | `NEXT_PUBLIC_FIREBASE_*`, `BIOMETRIC_SYNC_SECRET` | Firebase messaging credentials and automated sync secrets |
| **Integrations** | `WHATSAPP_VERIFY_TOKEN`, `AUTO_TASK_SYNC_SECRET` | Webhook verification and automated task sync secrets |
| **Domain Routing** | `DOMAIN`, `KONG_CORS_ORIGINS`, `GOTRUE_URI_ALLOW_LIST` | Allowed frontend domains (`https://test.neosfacility.com`) |

---

## 4. Operational Documentation Quick Links
- [Known Issues](file:///d:/WebApp/KVM2_HWB/docs/KNOWN_ISSUES.md)
- [Changelog](file:///d:/WebApp/KVM2_HWB/docs/CHANGELOG.md)
- [VPS Staging Handoff](file:///d:/WebApp/KVM2_HWB/docs/VPS_STAGING_HANDOFF.md)
- [Migration Plan](file:///d:/WebApp/KVM2_HWB/docs/MIGRATION_PLAN.md)
- [Investigations Directory](file:///d:/WebApp/KVM2_HWB/docs/investigations/)
- [Reports Directory](file:///d:/WebApp/KVM2_HWB/docs/reports/)
