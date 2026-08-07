# NEOS Application Automatic Deployment Workflow

This document describes the automated Continuous Deployment (CD) pipeline for the NEOS Application (`neos_app`) running on the Hostinger VPS.

## Overview

The deployment pipeline is powered by GitHub Actions. Every push to the `master` branch triggers an automated SSH workflow that builds and updates only the application container (`neos_app`).

> [!IMPORTANT]
> **Isolated Scope:** The deployment workflow strictly isolates application deployment. Stateful and core infrastructure services—including **PostgreSQL**, **Supabase**, **Kong**, **Traefik**, **Redis**, and **MinIO**—are never restarted, rebuilt, or altered by this pipeline.

---

## 1. GitHub Secrets Required

To enable the GitHub Actions workflow to establish a secure SSH connection to the Hostinger VPS, the following secrets must be configured in your GitHub repository (**Settings > Secrets and variables > Actions**):

| Secret Name | Description | Example Value |
| :--- | :--- | :--- |
| `VPS_HOST` | IP address or domain name of the Hostinger VPS | `185.228.83.136` |
| `VPS_USERNAME` | SSH username with permission to run Docker commands | `nasim` or `root` |
| `VPS_SSH_PRIVATE_KEY` | Private SSH key (PEM / OpenSSH format) matching `authorized_keys` | `-----BEGIN OPENSSH PRIVATE KEY----- ...` |
| `VPS_PORT` | *(Optional)* SSH port (defaults to `22` if omitted) | `22` |

---

## 2. SSH Key Setup

Follow these steps to generate and authorize an SSH key pair dedicated to GitHub Actions deployment:

### Step 1: Generate an SSH Key Pair locally
```bash
ssh-keygen -t ed25519 -C "github-actions-deploy@neosfacility.com" -f ./id_ed25519_deploy -N ""
```

### Step 2: Copy the Public Key to the VPS
Append the contents of `id_ed25519_deploy.pub` to the authorized keys file on the VPS:
```bash
# On the VPS server:
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat >> ~/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... github-actions-deploy@neosfacility.com
EOF
chmod 600 ~/.ssh/authorized_keys
```

### Step 3: Add Private Key to GitHub Secrets
Copy the entire contents of `id_ed25519_deploy` into the GitHub Secret `VPS_SSH_PRIVATE_KEY`.

---

## 3. VPS Prerequisites

Before running the workflow for the first time, ensure the Hostinger VPS satisfies these prerequisites:

1. **Repository Path:** The Git repository must be cloned at `/srv/neos/neos-platform`.
   ```bash
   sudo mkdir -p /srv/neos
   cd /srv/neos
   git clone https://github.com/nasimhwb/neos-platform.git
   ```
2. **Environment File:** A valid `.env` file must exist at `/srv/neos/neos-platform/.env` containing production secrets and environment variables.
3. **Docker Networks:** The external Docker networks (`neos-public`, `neos-private`, `neos-monitoring`, `neos-database`) must exist.
   ```bash
   docker network create neos-public || true
   docker network create neos-private || true
   docker network create neos-monitoring || true
   docker network create neos-database || true
   ```
4. **User Permissions:** The SSH user specified in `VPS_USERNAME` must belong to the `docker` group or have permission to run `docker compose`.

---

## 4. Deployment Sequence

When a push event occurs on the `master` branch:

```mermaid
graph TD
    A[Push to master branch] --> B[GitHub Actions Trigger]
    B --> C[SSH into Hostinger VPS]
    C --> D["cd /srv/neos/neos-platform"]
    D --> E[git fetch origin]
    E --> F[git reset --hard origin/master]
    F --> G[docker compose -f docker-compose.app.yml build neos_app]
    G --> H[docker compose -f docker-compose.app.yml up -d neos_app]
    H --> I[Poll Docker Health Check status]
    I --> J{Container Healthy?}
    J -- Yes --> K[Perform HTTP Health Check on localhost:3000]
    J -- No / Timeout --> L[Log errors & Stop immediately]
    K --> M{HTTP 200 OK?}
    M -- Yes --> N[Deployment Success]
    M -- No --> L
```

### Command Flow

1. **Navigate to directory:**
   ```bash
   cd /srv/neos/neos-platform
   ```
2. **Synchronize repository state:**
   ```bash
   git fetch origin
   git reset --hard origin/master
   ```
3. **Build target container image:**
   ```bash
   docker compose -f docker-compose.app.yml build neos_app
   ```
4. **Recreate application container:**
   ```bash
   docker compose -f docker-compose.app.yml up -d neos_app
   ```
5. **Poll container health status:**
   Checks `docker inspect --format='{{json .State.Health.Status}}' neos_app` until status is `healthy` (up to 120 seconds).
6. **Execute HTTP endpoint check:**
   Verifies response from `http://localhost:3000/api/health` returns HTTP status code 200-399.

---

## 5. Recovery Procedure & Troubleshooting

If a deployment step fails:

1. **Immediate Exit:** The workflow sets `script_stop_on_error: true` and `set -e`. Any command failure immediately aborts the deployment without affecting other running services.
2. **Inspect Container Logs:**
   Connect to the VPS via SSH and view the application logs:
   ```bash
   docker logs --tail 100 neos_app
   ```
3. **Manual Rollback Procedure:**
   To revert `neos_app` to a previous git commit or working release:
   ```bash
   cd /srv/neos/neos-platform
   git reset --hard <PREVIOUS_WORKING_COMMIT_SHA>
   docker compose -f docker-compose.app.yml build neos_app
   docker compose -f docker-compose.app.yml up -d neos_app
   ```
4. **Idempotency Guarantee:**
   The deployment workflow is fully idempotent. Running `git fetch origin && git reset --hard origin/master` and `docker compose -f docker-compose.app.yml up -d neos_app` multiple times produces a consistent, safe state.
