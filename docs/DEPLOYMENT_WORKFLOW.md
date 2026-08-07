# NEOS App Production Deployment Workflow

This document describes the automated Continuous Deployment (CD) pipeline for the NEOS Application (`neos_app`) running on the Hostinger VPS.

## Repository Boundaries & Ownership

> [!IMPORTANT]
> **Repository Ownership & Scope:**
> - **This Repository (`neos-app`):** Owns ONLY the application codebase, `docker-compose.app.yml`, `.github/workflows/deploy.yml`, the `neos_app` container, and domain `webapp.neosfacility.com`.
> - **The Infrastructure Repository (`neos-platform`):** Owns ALL core infrastructure including `neos_dashboard`, Traefik reverse proxy configuration (`configs/traefik/*`), Supabase (GoTrue, PostgREST, Gateway), PostgreSQL, Redis, MinIO, Kong, and base compose files (`compose.base.yml`, `compose.dashboard.yml`, `compose.supabase.yml`).
>
> This repository **NEVER** modifies infrastructure files, Traefik routing, or other container definitions.

---

## 1. Scope & Domain Target

| Component / Target | Description | Upstream Container / Port |
| :--- | :--- | :--- |
| **Container Name** | `neos_app` | `neos_app:3000` |
| **Target Domain** | `webapp.neosfacility.com` | Traefik Router: `Host(webapp.neosfacility.com)` |
| **Compose File** | `docker-compose.app.yml` | Isolated standalone application compose definition |

---

## 2. GitHub Secrets Required

Configure the following secrets in GitHub (**Settings > Secrets and variables > Actions**):

| Secret Name | Requirement | Description | Example Value |
| :--- | :---: | :--- | :--- |
| `VPS_HOST` | **Required** | Hostinger VPS IP Address or Hostname | `185.228.83.136` |
| `VPS_USERNAME` | **Required** | SSH Username with Docker privileges | `nasim` or `root` |
| `VPS_SSH_PRIVATE_KEY` | **Required** | Private SSH Key matching `authorized_keys` | `-----BEGIN OPENSSH PRIVATE KEY-----` |
| `VPS_PORT` | *Optional* | SSH Port (defaults to `22` if omitted) | `22` |

---

## 3. In-Container Health Check (No Host Port Exposure)

> [!NOTE]
> To preserve container isolation and security, port `3000` is **NOT** exposed to the host interface.

Health checks execute entirely within the Docker container network:
- **Internal Endpoint Check:** `docker exec neos_app wget -qO- http://127.0.0.1:3000/api/health`
- **Docker Daemon Healthcheck:** Configured in `docker-compose.app.yml` via `wget --no-verbose --spider http://127.0.0.1:3000/api/health`.

---

## 4. Multi-Stage Verification Pipeline

The deployment sequence executes 7 automated stages on the VPS:

```mermaid
graph TD
    A[Push to master branch] --> B[GitHub Actions Trigger]
    B --> C[SSH into Hostinger VPS]
    C --> D[1. Fetch & Reset repo to origin/master]
    D --> E[2. Build neos_app container image]
    E --> F[3. Deploy neos_app container]
    F --> G[4. Wait for Docker container healthy status]
    G --> H[5. In-container HTTP /api/health verification]
    H --> I[6. In-container Supabase connectivity check]
    I --> J[7. Verify background job scheduler initialization]
    J --> K{All Checks Pass?}
    K -- Yes --> L[Report SUCCESS & Output Summary]
    K -- No --> M[Trigger Automated Safe Rollback]
    M --> N[Log diagnostics, git reset, restore previous container]
    N --> O[Exit code 1 & Report FAILED]
```

### Stage Breakdown

1. **Repository Synchronization:** `git fetch origin && git reset --hard origin/master`
2. **Container Build:** `docker compose -f docker-compose.app.yml build neos_app`
3. **Container Launch:** `docker compose -f docker-compose.app.yml up -d neos_app`
4. **Docker Health Status:** Poll `docker inspect` for `healthy` status (up to 120 seconds).
5. **Endpoint Health Check:** `docker exec neos_app wget -qO- http://127.0.0.1:3000/api/health`
6. **Supabase Connectivity:** Probe Supabase Auth gateway endpoint (`$SUPABASE_URL/auth/v1/health`) from inside container.
7. **Background Jobs Initialization:** Verify Next.js `SchedulerService` background snapshot loop initialized.

---

## 5. Automated Rollback & Recovery Mechanism

If any deployment or verification step fails:

1. **Stop Immediately:** Execution halts at the failing step (`set -e`, `script_stop_on_error: true`).
2. **Diagnostic Logs Captured:** The pipeline outputs the last 100 lines of container logs (`docker logs --tail 100 neos_app`).
3. **Git Codebase Reversion:** Automatically reverts the local repo to the previous commit (`git reset --hard $PREV_COMMIT_SHA`).
4. **Container State Restoration:** Re-builds and re-launches the previous working container image.
5. **Production Protection:** Production is never left in a broken or un-healthy state.
6. **Failure Reporting:** Output formatted failure summary and exit code 1 to alert maintainers.

---

## 6. Deployment Summary Format

Upon completion (success or failure), the workflow outputs a summary block:

```text
==========================================================================
                      DEPLOYMENT SUMMARY (SUCCESS)                        
==========================================================================
  Commit SHA      : eae1cd45b736b4129b09d05d7620ed772d5c3dfb
  Branch          : master
  Build Duration  : 42s
  Container Name  : neos_app
  Health Status   : PASSED
  Supabase Status : PASSED
  Final Result    : SUCCESS
==========================================================================
```
