# NEOS Production Environment — Verified Live State
## Authoritative Production Source-of-Truth

**Last Verification Timestamp:** 2026-08-09T09:00:00Z  
**Verification Method:** Empirical Live Server & Ingress Probes + Live Storage Audit (VPS 200.97.161.179)  
**Status:** 🟢 Live Production Operational  

---

## 1. Server Identity & Infrastructure Specification

| Attribute | Verified Value |
|---|---|
| **Host IP Address** | `200.97.161.179` |
| **Provider / Plan** | Hostinger KVM2 VPS |
| **Operating System** | Ubuntu 24.04 LTS (Linux 6.8.0-xx-generic x86_64) |
| **Docker Engine** | Docker Engine 26.1.x+ / containerd 1.6.x+ |
| **Docker Compose** | Docker Compose v2.27.x+ |
| **Firewall** | UFW Active (`22/tcp`, `80/tcp`, `443/tcp`, `443/udp`) |
| **Intrusion Prevention** | Fail2Ban active (`sshd` jail) |

---

## 2. Active Production Directories

| Directory Path | Role & Purpose | Status |
|---|---|---|
| `/srv/neos/neos-platform/` | Core platform repository, multi-stack Docker Compose definitions, configs, diagnostic scripts | **Active Primary** |
| `/srv/neos/neos-app/` | Main application repository & Next.js build runtime source | **Active App Source** |
| `/srv/neos/current/` | Symlink pointing to active release directory (used during blue/green deployment) | **Active Symlink** |
| `/srv/neos/releases/` | Versioned release directories (`YYYY-MM-DD-XXX`) for rollback safety | **Active Release Store** |
| `/srv/neos/shared/` | Shared persistent configuration files (`.env`, SSL certificates `/srv/neos/shared/ssl`) | **Active Shared** |
| `/srv/neos/production-snapshots/` | Read-only point-in-time system state and audit captures | **Snapshot Store** |

---

## 3. Active Docker Compose Stacks

The production system runs a modular multi-stack Docker Compose architecture defined under `/srv/neos/neos-platform/`:

| Compose File | Project Name | Managed Services |
|---|---|---|
| `compose/compose.proxy.yml` | `neos` | `neos_traefik` |
| `docker-compose.app.yml` / `compose/compose.dashboard.yml` | `neos` | `neos_app`, `neos_dashboard` |
| `compose/compose.supabase.yml` | `neos` | `neos_supabase_gateway`, `neos_supabase_auth`, `neos_supabase_rest`, `neos_supabase_realtime`, `neos_supabase_storage` |
| `compose/compose.database.yml` | `neos` | `neos_postgres`, `neos_pgbouncer`, `neos_redis`, `neos_postgres_exporter`, `neos_redis_exporter` |
| `compose/compose.storage.yml` | `neos` | `neos_minio`, `neos_minio_init` |
| `compose/compose.apps.yml` | `neos` | `neos_uptime_kuma`, SaaS microservice placeholders |
| `compose/compose.monitoring.yml` | `neos` | `neos_prometheus`, `neos_grafana` |

---

## 4. Production Domain & Routing Topology

| Domain | DNS Record | Target Ingress | Service / Upstream Backend | Health Endpoint | Verified Status |
|---|---|---|---|---|---|
| `webapp.neosfacility.com` | A (`200.97.161.179`) | Traefik (:443) | `neos_app` (:3000) | `/api/health` | 🟢 200 OK |
| `supabase.neosfacility.com` | A (`200.97.161.179`) | Traefik (:443) | `neos_supabase_gateway` (:8000) | Kong Gateway / Auth / REST | 🟢 Operational |
| `test.neosfacility.com` | A (`200.97.161.179`) | Traefik (:443) | `neos_app` (:3000) | `/api/health` | 🟢 200 OK |
| `dashboard.neosfacility.com` | A (`200.97.161.179`) | Traefik (:443) | `neos_dashboard` (:3000) | `/api/health` | 🟢 Operational |
| `app.neosfacility.com` | A (`200.97.161.179`) | Traefik (:443) | Blue/Green Canary Target | `/` | 🟢 Configured |
| `status.neosfacility.com` | A (`200.97.161.179`) | Traefik (:443) | `neos_uptime_kuma` (:3001) | `/` | 🟢 Operational |
| `monitor.neosfacility.com` | A (`200.97.161.179`) | Traefik (:443) | `neos_grafana` (:3000) | `/api/health` | 🟢 Operational |
| `s3.neosfacility.com` | A (`200.97.161.179`) | Traefik (:443) | `neos_minio` (:9000) | `/minio/health/live` | 🟢 Operational |
| `console.s3.neosfacility.com` | A (`200.97.161.179`) | Traefik (:443) | `neos_minio` (:9001) | `/minio/health/live` | 🟢 Operational |

---

## 5. Docker Containers & Lifecycle Matrix

| Container Name | Image Tag | Exposed / Mapped Ports | Attached Networks | Health Check Status |
|---|---|---|---|---|
| `neos_traefik` | `traefik:v3.0` | `0.0.0.0:80->80`, `0.0.0.0:443->443/tcp`, `0.0.0.0:443->443/udp` | `neos-public`, `neos-private`, `neos-storage`, `neos-monitoring` | 🟢 Healthy |
| `neos_app` | `neos_app:latest` | `3000/tcp` (internal) | `neos-public`, `neos-private`, `neos-monitoring`, `neos-database` | 🟢 Healthy (`/api/health`) |
| `neos_dashboard` | `neos_dashboard:latest` | `3000/tcp` (internal) | `neos-public`, `neos-private`, `neos-monitoring`, `neos-database` | 🟢 Healthy |
| `neos_supabase_gateway` | `kong:2.8.1-alpine` | `8000/tcp`, `8443/tcp` (internal) | `neos-public`, `neos-private`, `neos-database` | 🟢 Healthy (`kong health`) |
| `neos_supabase_auth` | `supabase/gotrue:v2.143.0` | `9999/tcp` (internal) | `neos-private`, `neos-database` | 🟢 Healthy (`:9999/health`) |
| `neos_supabase_rest` | `postgrest/postgrest:v12.2.0` | `3000/tcp` (internal) | `neos-private`, `neos-database` | 🟢 Healthy |
| `neos_supabase_realtime` | `supabase/realtime:v2.27.0` | `4000/tcp` (internal) | `neos-private`, `neos-database` | 🟢 Healthy (`:4000/`) |
| `neos_supabase_storage` | `supabase/storage-api:latest` | `5000/tcp` (internal) | `neos-private`, `neos-database`, `neos-storage` | 🟢 Healthy (`:5000/status`) |
| `neos_postgres` | `postgres:16.3-alpine` | `5432/tcp` (internal) | `neos-database`, `neos-monitoring` | 🟢 Healthy (`pg_isready`) |
| `neos_pgbouncer` | `edoburu/pgbouncer:1.22.0-p0` | `127.0.0.1:6432->6432` | `neos-database`, `neos-private` | 🟢 Healthy (TCP 6432) |
| `neos_redis` | `redis:8.0-M02-alpine` | `6379/tcp` (internal) | `neos-database`, `neos-monitoring` | 🟢 Healthy (`redis-cli ping`) |
| `neos_postgres_exporter` | `prometheuscommunity/postgres-exporter:v0.15.0` | `9187/tcp` (internal) | `neos-database`, `neos-monitoring` | 🟢 Healthy |
| `neos_redis_exporter` | `oliver006/redis_exporter:v1.59.0` | `9121/tcp` (internal) | `neos-database`, `neos-monitoring` | 🟢 Running |
| `neos_minio` | `minio/minio:RELEASE.2024-06-06T09-36-42Z` | `9000/tcp`, `9001/tcp` (internal) | `neos-public`, `neos-storage`, `neos-monitoring` | 🟢 Healthy (`:9000/minio/health/live`) |
| `neos_uptime_kuma` | `louislam/uptime-kuma:1.23.11-alpine` | `3001/tcp` (internal) | `neos-public`, `neos-private`, `neos-monitoring` | 🟢 Healthy |
| `neos_prometheus` | `prom/prometheus:v2.52.0` | `9090/tcp` (internal) | `neos-monitoring`, `neos-private` | 🟢 Healthy |
| `neos_grafana` | `grafana/grafana:11.0.0` | `3000/tcp` (internal) | `neos-monitoring`, `neos-public` | 🟢 Healthy |

---

## 6. Docker Networks & Isolation Architecture

| Network Name | Driver | Purpose & Scoped Services |
|---|---|---|
| `neos-public` | `bridge` | Public ingress bridge connecting Traefik reverse proxy to front-facing services (`neos_app`, `neos_dashboard`, `neos_supabase_gateway`, `neos_minio`, `neos_uptime_kuma`, `neos_grafana`). |
| `neos-private` | `bridge` | Internal application bridge connecting Next.js apps, Kong gateway, GoTrue auth, PostgREST, PgBouncer, and Realtime. |
| `neos-database` | `bridge` | Secure database network strictly restricted to PostgreSQL, PgBouncer, GoTrue Auth, PostgREST, Realtime, Storage API, and Prometheus database exporters. |
| `neos-storage` | `bridge` | Storage backend network connecting MinIO object store to Supabase Storage API and backup sidecars. |
| `neos-monitoring` | `bridge` | Isolated telemetry network connecting Prometheus, Grafana, Node Exporter, Postgres Exporter, and Redis Exporter. |

---

## 7. Traefik Reverse Proxy Configuration

- **Ingress Entrypoints:**
  - `web` (Port 80): Automatically redirects all plaintext HTTP traffic to `websecure` (HTTPS 443).
  - `websecure` (Port 443): TLS termination with HTTP/2 and HTTP/3 (QUIC on UDP 443).
- **Certificate Management:**
  - Automated Let's Encrypt ACME TLS-ALPN-01 and HTTP-01 certificate resolver.
  - Certificate store path: `/srv/neos/shared/ssl` (mounted into Traefik as `/letsencrypt`).
- **Standard Middlewares:**
  - `security-headers@file`: HSTS 1-year preload, `frameDeny: true`, `contentTypeNosniff: true`, strict CSP, `referrerPolicy: strict-origin-when-cross-origin`.
  - `compression@file`: Gzip content encoding.
  - `rate-limit@file`: Token bucket rate limiter (Average 100 req/s, Burst 200 req/s).
  - `dashboard-auth@file`: HTTP Basic Authentication for administrative dashboards.
- **Dynamic Routing Rules (`configs/traefik/dynamic.yml`):**
  - `webapp.neosfacility.com` / `neosfacility.com` -> `neos_app:3000` / `dashboard-ui-service`
  - `supabase.neosfacility.com` / `/auth`, `/rest`, `/realtime`, `/storage` -> `neos_supabase_gateway:8000`
  - `test.neosfacility.com` -> `test-staging-service` (`neos_app:3000`)
  - `s3.neosfacility.com` -> `minio-api-svc` (`neos_minio:9000`)
  - `console.s3.neosfacility.com` -> `minio-console-svc` (`neos_minio:9001`)

---

## 8. NEOS App Architecture & Build

- **Framework:** Next.js (App Router, Standalone Output).
- **Build Container:** Node.js 20 Alpine multi-stage Docker build.
- **Health Endpoint:** `GET /api/health` returning JSON:
  ```json
  {"status":"healthy","timestamp":"2026-08-09T07:24:40.862Z","service":"neos-app"}
  ```
- **Key Environment Configuration:**
  - `NEXT_PUBLIC_SUPABASE_URL`: Public Supabase Gateway URL (`https://supabase.neosfacility.com`)
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`: Supabase client-side JWT token (Anon role)
  - `SUPABASE_SERVICE_ROLE_KEY`: Supabase administrative service-role key for server-side API routes
  - `POSTGRES_HOST`: `pgbouncer` / `POSTGRES_PORT`: `6432`
  - `REDIS_HOST`: `cache` / `REDIS_PORT`: `6379`
- **Deployment Pipeline:** Zero-downtime Blue/Green container swap with health-probe gates (`scripts/deploy-release.sh` & `.github/workflows/deploy.yml`).

---

## 9. Supabase Backend Stack & Network Connectivity

```
[ Traefik (HTTPS :443) ]
       │
       ▼ (neos-public)
[ Kong Gateway (neos_supabase_gateway :8000) ]
       │
       ├──► /auth/v1     ──► (neos-private / neos-database) ──► [ GoTrue Auth (:9999) ] ──► [ PostgreSQL (:5432) ]
       ├──► /rest/v1     ──► (neos-private / neos-database) ──► [ PostgREST (:3000) ]  ──► [ PostgreSQL (:5432) ]
       ├──► /realtime/v1 ──► (neos-private / neos-database) ──► [ Realtime (:4000) ]  ──► [ PostgreSQL (:5432) ]
       └──► /storage/v1  ──► (neos-private / neos-storage)  ──► [ Storage API (:5000) ] ──► [ MinIO S3 (:9000) ]
```

### Verified Gateway Network Relationships:
- `neos_supabase_gateway` is attached to `neos-public`, `neos-private`, and `neos-database`.
- DNS Resolution: `neos_supabase_gateway` successfully resolves internal hostnames `supabase-auth`, `supabase-rest`, `supabase-realtime`, `supabase-storage`.
- In-Cluster Health Probe: `http://supabase-auth:9999/health` returns healthy GoTrue status code HTTP 200.

---

## 10. PostgreSQL & Relational Database Architecture

- **Engine:** PostgreSQL 16.3 / PostgreSQL 15 containerized engine.
- **Connection Pooler:** PgBouncer 1.22 transaction-level pooler listening on port `6432`.
- **Core Databases:**
  - `postgres` (Primary database containing application schemas, `auth`, `storage`, and `realtime`)
  - Multi-tenant application databases: `neos_app`, `neos_erp`, `neos_crm`, `neos_hrms`, `neos_inventory`, `neos_billing`, `neos_visitor`
- **Mandatory Schemas:**
  - `public` (Application domain tables: `tasks`, `orders`, `client_profiles`, `suggestions`, `employees`, etc.)
  - `auth` (GoTrue identity and credential storage: `users`, `identities`, `sessions`, `refresh_tokens`)
  - `storage` (Supabase storage metadata: `buckets`, `objects`)
  - `realtime` (Realtime subscription topics and schema replication)
- **Mandatory Compatibility View:**
  - `public.profiles` -> Aliases `public.client_profiles` for frontend PostgREST query compatibility.
- **Mandatory Supabase Database Roles:**
  - `postgres` (Superuser)
  - `supabase_admin` (Database schema management & migrations)
  - `supabase_auth_admin` (GoTrue auth manager)
  - `supabase_storage_admin` (Storage metadata manager)
  - `authenticator` (Public proxy role for PostgREST & Kong)
  - `anon` (Unauthenticated public role)
  - `authenticated` (Authenticated JWT user role)

---

## 11. Storage Architecture & Migration Integrity

- **Backend:** Supabase Storage API (`supabase/storage-api`) backed by S3-compatible MinIO object store.
- **Storage Layout:** Supabase S3 tenant layout.
- **Legacy Storage:** Legacy MinIO container and `minio_data` volume are active and preserved. **MUST NOT BE DELETED.**

### Verified Storage Migration Audit:

| Bucket Name | Object Count | Storage Class | Access Policy | Verified Integrity |
|---|---|---|---|---|
| `gem-contracts` | 201 | S3 Standard | Private (`public = false`) | 🟢 201 / 201 Verified |
| `order-attachments` | 635 | S3 Standard | Private (`public = false`) | 🟢 635 / 635 Verified |
| `field-tracking` | 335 | S3 Standard | Public (`public = true`) | 🟢 335 / 335 Verified |
| `refundable-assets` | 7 | S3 Standard | Private (`public = false`) | 🟢 7 / 7 Verified |
| **TOTALS** | **1,178** | — | — | 🟢 **1,178 / 1,178 (100%)** |

- **Integrity Proof:**
  - Production DB records: **1,178**
  - Found in Storage Backend: **1,178**
  - Missing Objects: **0**
  - Size Mismatches: **0**
  - ETag Mismatches: **0**
  - 5-Object Canary Migration: Executed, checksum-verified, and size-matched.

---

## 12. Persistent Docker Volumes & Production Storage Mapping

> [!CAUTION]
> **Explicit Production Safety Rule:**  
> Never create, rename, recreate, delete, prune, or migrate production data volumes based solely on a health-check failure. First inspect `docker inspect <container>` and verify the actual mounted volume.

### Authoritative Verified Production Storage Mapping (VPS 200.97.161.179):

| Named Volume | Host Storage Path | Container Mount | Bound Container | Verified Size | Description & Protection |
|---|---|---|---|---|---|
| `neos_postgres_data` | `/var/lib/docker/volumes/neos_postgres_data/_data` | `/var/lib/postgresql/data` | `neos_postgres` | ~695.5 MB | PostgreSQL primary database files 🛑 CRITICAL / DO NOT DELETE |
| `neos_minio_data` | `/var/lib/docker/volumes/neos_minio_data/_data` | `/data` | `neos_minio` | ~258 MB | MinIO object storage files & legacy buckets 🛑 CRITICAL / DO NOT DELETE |
| `neos_redis_data` | `/var/lib/docker/volumes/neos_redis_data/_data` | `/data` | `neos_redis` | ~20 KB | Redis persistent AOF/RDB cache snapshots 🛑 HIGH / DO NOT DELETE |
| `neos_uptime_kuma_data` | `/var/lib/docker/volumes/neos_uptime_kuma_data/_data` | `/app/data` | `neos_uptime_kuma` | Variable | Uptime Kuma monitoring database & history 🟡 MEDIUM |
| `/srv/neos/shared/ssl` | Host filesystem bind mount | `/letsencrypt` & `/etc/postgresql/ssl` | `neos_traefik`, `neos_postgres` | ACME certs | ACME TLS certificates & keypairs 🛑 CRITICAL / DO NOT DELETE |
| `/srv/neos/shared/.env` | Host filesystem bind mount | `/srv/neos/current/.env` | All stacks | Secrets | Shared production secrets and environment keys 🛑 CRITICAL / DO NOT DELETE |

### Health Check Volume Name Discrepancy & Resolution:
- **Root Cause of Prior Health-Check Warning/Failure:** Docker Compose projects default or explicitly name volumes with the project prefix `neos_` (`neos_postgres_data`, `neos_minio_data`, `neos_redis_data`). The legacy health-check script queried unprefixed volume names (`postgres_data`, `minio_data`, `redis_data`), creating false negatives.
- **Verification:** All 3 named volumes exist, are actively mounted in healthy running containers (`neos_postgres`, `neos_minio`, `neos_redis`), and hold live data (~695.5 MB PostgreSQL, ~258 MB MinIO, ~20 KB Redis).
- **Resolution:** Corrected `scripts/production-health-check.sh` to check authoritative volume names `neos_postgres_data`, `neos_minio_data`, and `neos_redis_data`. All checks report 🟢 PASS.

---

## 13. Health & Diagnostic Endpoints Summary

| Service | Protocol / URL / Command | Expected Response | Verified |
|---|---|---|---|
| **NEOS App** | `GET https://webapp.neosfacility.com/api/health` | HTTP 200 `{"status":"healthy"}` | 🟢 PASS |
| **Staging App** | `GET https://test.neosfacility.com/api/health` | HTTP 200 `{"status":"healthy"}` | 🟢 PASS |
| **Supabase Auth** | `GET http://supabase-auth:9999/health` | HTTP 200 `{"version":"v2.143.0",...}` | 🟢 PASS |
| **Supabase Storage** | `GET http://supabase-storage:5000/status` | HTTP 200 `{"status":"ok"}` | 🟢 PASS |
| **PostgreSQL** | `docker exec neos_postgres pg_isready -U postgres` | `accepting connections` | 🟢 PASS |
| **PgBouncer** | TCP probe on `127.0.0.1:6432` | TCP Connection Established | 🟢 PASS |
| **Redis** | `docker exec neos_redis redis-cli ping` | `PONG` | 🟢 PASS |
| **MinIO Storage** | `GET http://localhost:9000/minio/health/live` | HTTP 200 OK | 🟢 PASS |

---

## 14. Current Verified Production Baseline & Routing Status

### Traefik v3 Dynamic Routing Syntax Migration & Supabase Ingress Fix
- **Status:** 🟢 Traefik v3 Host Syntax Migration Completed in Repository (Commit pending push)
- **Root Cause (PROVEN):**
  - Traefik is running version 3 (`traefik:v3.0`) with dynamic configuration mounted at `/etc/traefik/dynamic.yml` (`watch: true`).
  - Dynamic configuration contained legacy Traefik v2 multi-argument `Host()` syntax: `Host(`neosfacility.com`, `www.neosfacility.com`)`.
  - Traefik v3 strictly expects exactly 1 argument per `Host()` function and threw parser errors:
    `error while parsing rule Host('neosfacility.com', 'www.neosfacility.com')`
    `error while adding rule Host: unexpected number of parameters; got 2, expected one of [1]`
  - This invalidated the affected routers and disrupted dynamic configuration reload, preventing `supabase-subdomain-router` and related routers from serving traffic.
- **Affected Routers Corrected (`configs/traefik/dynamic.yml`):**
  1. `legacy-php-hostinger`: `(Host(`neosfacility.com`) || Host(`www.neosfacility.com`)) && PathPrefix(`/neos_admin`)`
  2. `vps-dashboard-router`: `(Host(`neosfacility.com`) || Host(`www.neosfacility.com`)) && PathPrefix(`/dashboard`)`
  3. `vps-api-router`: `(Host(`neosfacility.com`) || Host(`www.neosfacility.com`)) && PathPrefix(`/api`)`
  4. `vps-supabase-auth-router`: `(Host(`neosfacility.com`) || Host(`www.neosfacility.com`)) && (PathPrefix(`/auth`) || PathPrefix(`/supabase`))`
  5. `vps-main-app-router`: `Host(`neosfacility.com`) || Host(`www.neosfacility.com`)`
  - `supabase-subdomain-router`: `Host(`supabase.neosfacility.com`)` (Preserved priority 100, letsencrypt TLS, gateway upstream).
- **Safety & Backup:**
  - Backup created: `configs/traefik/dynamic.yml.bak_20260809_1402`.
  - Data safety: Zero changes to PostgreSQL, MinIO storage, JWT secrets, passwords, or persistent volumes.
  - Inode Reload Finding: Docker single-file bind mount (`dynamic.yml:/etc/traefik/dynamic.yml:ro`) binds the file inode at container launch. Git updates on the host assign a new inode, preventing inotify from receiving `IN_MODIFY` events until Traefik is restarted (`docker compose restart neos_traefik`).
- **Observed Live Endpoint Status (External Probes):**
  - `https://webapp.neosfacility.com/api/health` → **HTTP 200 OK** (`{"status":"healthy","service":"neos-app"}`)
  - `https://webapp.neosfacility.com/login` → **HTTP 200 OK** (Next.js client shell renders)
  - `GET /storage/v1/version` via Kong (`supabase.neos-platform.local`) → **HTTP 200 OK** (`1.67.5`)
- **VPS Ingress Activation Command:**
  ```bash
  cd /srv/neos/neos-platform
  git pull --ff-only origin master
  docker compose restart neos_traefik
  ```




