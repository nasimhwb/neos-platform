# NEOS Platform — Coolify Migration Assessment & Architectural Plan

**Status:** 🟡 PROPOSED / PREPARATION PHASE ONLY (DO NOT INSTALL YET)  
**Classification:** Infrastructure Architecture Assessment  
**Author:** Antigravity (Google DeepMind Team)  
**Target Environment:** Hostinger KVM2 VPS (`200.97.161.179`)  

---

## 1. Executive Summary

This document evaluates the architectural requirements, risks, network dependencies, and step-by-step procedures required to safely integrate or migrate the NEOS Platform infrastructure to Coolify.

> [!CAUTION]
> **DO NOT INSTALL COOLIFY AT THIS STAGE.**  
> Coolify binds ingress ports (`80`, `443`, `8000`) and provisions its own Traefik reverse proxy by default. Attempting an uncontrolled installation on the live server will immediately conflict with the active production Traefik proxy and cause downtime for `webapp.neosfacility.com`.

---

## 2. Existing Production Baseline Analysis

### 2.1 Existing Ingress & Proxy Ownership
* **Current Proxy:** Traefik v3.0 (`neos_traefik`) running in Docker.
* **Port Bindings:**
  * `0.0.0.0:80` (HTTP -> HTTPS redirect)
  * `0.0.0.0:443/tcp` (HTTPS TLS termination)
  * `0.0.0.0:443/udp` (HTTP/3 QUIC)
* **Configuration:** Docker socket label discovery combined with dynamic YAML file provider (`configs/traefik/dynamic.yml`).
* **TLS Certificate Ownership:** Traefik ACME HTTP-01/TLS-ALPN-01 resolver saving certificates to `/srv/neos/shared/ssl/` (mounted as `/letsencrypt`).

### 2.2 Existing Docker Network Architecture
* **`neos-public`**: Connects Traefik to public edge services (`neos_app`, `neos_supabase_gateway`, `neos_minio`, `neos_uptime_kuma`).
* **`neos-private`**: Inter-service communication between apps, Kong gateway, GoTrue auth, PostgREST, PgBouncer, Realtime.
* **`neos-database`**: Isolated network for PostgreSQL, PgBouncer, GoTrue, PostgREST, Realtime, Storage API, Prometheus Exporters.
* **`neos-storage`**: MinIO and Supabase Storage backend connectivity.
* **`neos-monitoring`**: Prometheus, Grafana, Node/DB/Redis Exporters.

### 2.3 Existing Production Domains
* `webapp.neosfacility.com` (Main production application)
* `supabase.neosfacility.com` (Supabase Kong Gateway API / Auth / REST / Realtime / Storage)
* `test.neosfacility.com` (Staging environment)
* `dashboard.neosfacility.com` (Control Center)
* `app.neosfacility.com` (Blue/Green canary target)
* `status.neosfacility.com` (Uptime Kuma)
* `monitor.neosfacility.com` (Grafana)
* `s3.neosfacility.com` & `console.s3.neosfacility.com` (MinIO S3 API & Console)

### 2.4 Existing Application & Service Deployments
* **NEOS App (`neos_app`)**: Next.js standalone container deployed via zero-downtime blue/green runner (`scripts/deploy-release.sh`) and GitHub Actions (`.github/workflows/deploy.yml`).
* **Supabase Suite**: Kong API Gateway (`neos_supabase_gateway`), GoTrue Auth (`neos_supabase_auth`), PostgREST (`neos_supabase_rest`), Realtime (`neos_supabase_realtime`), Storage API (`neos_supabase_storage`).
* **Database & Caching**: PostgreSQL 16/15 (`neos_postgres`), PgBouncer connection pooler (`neos_pgbouncer`), Redis 8 (`neos_redis`).
* **Storage Engine**: MinIO S3 object store (`neos_minio`) with persistent volume `minio_data`.
* **Legacy Storage**: Legacy MinIO container and buckets preserved.

---

## 3. Coolify Coexistence & Proxy Strategy

Coolify utilizes Traefik as its default ingress proxy. Two distinct migration architectural models exist:

### Model A: Coexistence with Shared Docker Networks (Recommended Initial Phase)
- Coolify is installed with its default proxy disabled or reconfigured to not conflict with ports `80/443`.
- Alternatively, Coolify's Traefik instance is integrated into the existing `neos-public` network.
- **Advantages:** Zero disruption to live production traffic, lets existing Compose stacks continue running uninterrupted.
- **Disadvantages:** Requires custom Coolify port overrides during initial bootstrapping.

### Model B: Full Coolify Ingress Takeover (Final Phase)
- Coolify takes ownership of ports `80` and `443`.
- Existing Traefik routing rules (`configs/traefik/dynamic.yml`) are translated into Coolify UI service definitions or Coolify Traefik custom configuration.
- **Requirements:**
  1. All services must be attached to Coolify's overlay/bridge network (e.g. `coolify`).
  2. All environment variables, secrets, and database credentials must be migrated into Coolify's encrypted PostgreSQL vault.
  3. ACME certificate paths must be migrated to avoid Let's Encrypt rate-limiting.

---

## 4. Prerequisites & Pre-Migration Backups

Before initiating any Coolify setup, the following backups must be generated and verified:

1. **PostgreSQL Database Dump:**
   ```bash
   docker exec neos_postgres pg_dumpall -U postgres | gzip > /srv/neos/backups/pg_dumpall_pre_coolify_$(date +%F).sql.gz
   ```
2. **MinIO / Storage Volume Snapshot:**
   ```bash
   tar -czvf /srv/neos/backups/minio_data_pre_coolify_$(date +%F).tar.gz -C /var/lib/docker/volumes/minio_data/_data .
   ```
3. **Configuration & Shared Asset Archive:**
   ```bash
   tar -czvf /srv/neos/backups/configs_pre_coolify_$(date +%F).tar.gz /srv/neos/shared /srv/neos/neos-platform/configs
   ```
4. **Read-Only Snapshot Execution:**
   ```bash
   /srv/neos/neos-platform/scripts/production-snapshot.sh
   ```

---

## 5. Phased Migration Runbook

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 1: Baseline Verification & Backup (CURRENT PHASE)                     │
│ - Finalize PRODUCTION_STATE.md and AG_PRODUCTION_RULES.md                   │
│ - Validate health-check and snapshot scripts                                │
│ - Verify 100% data and volume backups                                       │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 2: Coolify Staging Provisioning on Test Host / Isolated Port          │
│ - Deploy Coolify on isolated test port (e.g. 8000 / 3000)                   │
│ - Connect Coolify to GitHub repository `nasimhwb/neos-platform`              │
│ - Verify Coolify UI and secret management                                   │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 3: Service-by-Service Shadow Deployment                               │
│ - Deploy Next.js App (`neos_app`) inside Coolify on `test.neosfacility.com` │
│ - Validate environment variables, Supabase connection, and health probes     │
│ - Verify zero regressions across all 15 application modules                 │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ PHASE 4: Production Cutover & Ingress Handover                               │
│ - Scheduled maintenance window                                              │
│ - Update Traefik routing / DNS to route `webapp.neosfacility.com` to Coolify│
│ - Monitor real-time logs, error rates, and database connections             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Comprehensive Rollback Plan

If unexpected failures occur during Coolify staging or cutover:

1. **Immediate Ingress Reversion:**
   - Restore `/srv/neos/neos-platform/configs/traefik/dynamic.yml` from pre-migration backup.
   - Restart `neos_traefik` container: `docker compose -f compose/compose.proxy.yml up -d --force-recreate`.
2. **Container Stack Restoration:**
   - Run `docker compose -f docker-compose.app.yml up -d` to guarantee `neos_app` is active on port `3000`.
3. **Database Integrity Verification:**
   - Execute `/srv/neos/neos-platform/scripts/production-health-check.sh` to confirm all 17 services pass health checks.
4. **Verification Gate:**
   - Check `curl -i https://webapp.neosfacility.com/api/health` returns HTTP 200 OK.
