# Deployment & Rollback Runbook

This document details the release-based deployment lifecycle, the atomic folder structures, and the manual and automated rollback procedures.

---

## 1. Directory Structure

Deployments are organized using a Capistrano-style directory structure under `/srv/neos/` to ensure atomic updates and safe rollbacks:

```
/srv/neos/
├── current -> /srv/neos/releases/2026-07-06-001   # Symlink to the active release
├── releases/                                       # Holds last 5 deployed releases
│   ├── 2026-07-05-001/
│   ├── 2026-07-05-002/
│   └── 2026-07-06-001/
├── shared/                                         # Shared data, persistents, logs across releases
│   ├── .env                                        # Environment file
│   ├── backups/                                    # Backup dumps directory
│   ├── data/                                       # Database and cache persistent volumes
│   ├── logs/                                       # Collected logs (Nginx, Postgres, Redis)
│   ├── ssl/                                        # SSL certificates
│   └── www/                                        # Acme validation webroot
└── tmp/
    └── deploy-src/                                 # GitHub Actions upload staging directory
```

---

## 2. Deployment Lifecycle

The deployment process from GitHub Actions to the target VPS is fully automated:

1. **Staging Upload**: GitHub Actions rsyncs the repository assets to the staging path `/srv/neos/tmp/deploy-src/` over SSH as user `nasim`.
2. **Release Creation**: GHA executes `/srv/neos/tmp/deploy-src/scripts/deploy-release.sh`.
   - Generates release ID (e.g. `2026-07-06-002`).
   - Copies files from staging `/srv/neos/tmp/deploy-src/` to `/srv/neos/releases/2026-07-06-002/`.
   - Symlinks `/srv/neos/shared/.env` to the release root.
3. **Validation**: Config check runs compose test checks inside the new release directory.
4. **Service Update**: Runs `make up-apps` to boot/update the containers using the new configurations.
5. **Symlink Swapping**: Swaps `/srv/neos/current` to point to `/srv/neos/releases/2026-07-06-002/` atomically.
6. **Cleanup**: Wipes staging directory and prunes old release folders, keeping the latest 5.

---

## 3. Rollback Procedures

If a deployment fails, Nginx routing breaks, or a database configuration is incorrect, you must roll back immediately.

### Option A: Automated Rollback via GitHub Actions
1. Go to the GitHub repository **Actions** tab.
2. Select the **Manual Rollback Release** workflow.
3. Click **Run workflow** and select the target branch.
4. This connects to the VPS and triggers `/srv/neos/current/scripts/rollback.sh`.

### Option B: Manual Rollback via VPS CLI
1. Log in to the VPS via SSH as the user `nasim`.
2. Navigate to the current directory:
   ```bash
   cd /srv/neos/current
   ```
3. Execute the rollback script:
   ```bash
   ./scripts/rollback.sh
   ```
4. Confirm the prompt. The script will:
   - Identify the previous release folder.
   - Atomic-revert `/srv/neos/current` to point to the previous directory.
   - Restart the containers using the healthy configurations of that previous directory.
