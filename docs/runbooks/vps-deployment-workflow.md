# VPS Deployment Workflow

This runbook documents the standard workflow for pushing changes from the Windows development laptop to GitHub and the Hostinger KVM2 VPS production host. Follow this every time — no need to ask or re-confirm steps.

---

## Environment Reference

| Item | Value |
|---|---|
| VPS IP | `200.97.161.179` |
| VPS SSH user | `root` |
| SSH key path | `C:\Users\nasim\.ssh\id_ed25519` |
| SSH client | `C:\Program Files\Git\usr\bin\ssh.exe` |
| Git SSH command | `core.sshCommand = C:/Program Files/Git/usr/bin/ssh.exe` |
| GitHub remote | `origin` → `git@github.com:nasimhwb/neos-platform.git` |
| VPS bare repo remote | `vps` → `ssh://200.97.161.179/srv/neos/neos-platform` |
| Active branch | `feature/platform-dashboard` |
| VPS source directory | `/srv/neos/neos-platform` |
| VPS active release | `/srv/neos/current` (symlink) |
| Releases directory | `/srv/neos/releases/` |

---

## Standard Push Workflow

### Step 1 — Commit all local changes
```powershell
git add -A
git commit -m "type: short description of change"
```

### Step 2 — Push to GitHub
```powershell
git push origin feature/platform-dashboard
```

### Step 3 — Push to VPS bare repo

The VPS bare repo rejects pushes when it has unstaged local changes. Always reset the working tree first, then push:

```powershell
& "C:\Program Files\Git\usr\bin\ssh.exe" -i C:\Users\nasim\.ssh\id_ed25519 root@200.97.161.179 "cd /srv/neos/neos-platform && git reset --hard HEAD && git clean -fd"
git push vps feature/platform-dashboard
```

> **Why reset first?** The VPS `/srv/neos/neos-platform` is a non-bare working repo used as a git remote. Docker containers or deploy scripts sometimes write/modify files in this directory, creating unstaged changes that block incoming pushes.

### Step 4 — Pull latest on VPS (if needed separately)
```powershell
& "C:\Program Files\Git\usr\bin\ssh.exe" -i C:\Users\nasim\.ssh\id_ed25519 root@200.97.161.179 "cd /srv/neos/neos-platform && git reset --hard HEAD && git pull"
```

---

## Deployment Commands (run on VPS)

All `make` targets should be run from `/srv/neos/neos-platform` (source repo) or `/srv/neos/current` (active release):

| Command | What it does |
|---|---|
| `make deploy-release` | Packages source into a versioned release dir, starts all containers in dependency order, runs smoke tests and backup validation, then atomically swaps the `/srv/neos/current` symlink. |
| `make rollback-release` | Finds the previous release dir, atomically swaps the symlink back, restarts containers, and runs smoke tests to confirm health. |
| `make up` | Starts all containers from the current working directory using the unified compose command. |
| `make down` | Stops all containers. |
| `make verify` | Runs the system readiness check (OS, CPU, RAM, disk, Docker, container health). |
| `make doctor` | Runs the in-depth diagnostic (ports, DNS, SSL, API endpoints). |
| `make smoke-tests` | Runs the functional smoke test suite against live running services. |
| `make validate-backups` | Triggers a full backup cycle + SHA256 verify + isolated DB restore test. |

**Run on VPS via SSH from Windows:**
```powershell
& "C:\Program Files\Git\usr\bin\ssh.exe" -i C:\Users\nasim\.ssh\id_ed25519 root@200.97.161.179 "cd /srv/neos/neos-platform && git reset --hard HEAD && make deploy-release"
```

---

## Unified Docker Compose Command

All deploy and rollback scripts use a single `$COMPOSE_CMD` variable that includes all split config files. Never run `docker compose` directly without this full set or services will be missing:

```bash
docker compose --env-file .env \
  -f compose/compose.base.yml \
  -f compose/compose.database.yml \
  -f compose/compose.storage.yml \
  -f compose/compose.monitoring.yml \
  -f compose/compose.proxy.yml \
  -f compose/compose.security.yml \
  -f compose/compose.dashboard.yml \
  up -d
```

---

## Service Name Reference

Compose service names (as defined in YAML, not container names) for use with `docker compose up -d <service>`:

| Container Name | Compose Service Name |
|---|---|
| `neos_postgres` | `db` |
| `neos_redis` | `cache` |
| `neos_minio` | `object-store` |
| `neos_minio_init` | `minio-init` |
| `neos_pgbouncer` | `pgbouncer` |
| `neos_traefik` | `reverse-proxy` |
| `neos_dashboard` | `dashboard` |

---

## Checking Active Release

```powershell
& "C:\Program Files\Git\usr\bin\ssh.exe" -i C:\Users\nasim\.ssh\id_ed25519 root@200.97.161.179 "ls -la /srv/neos/releases/ && readlink /srv/neos/current"
```

---

## Viewing Commit on GitHub

After pushing, get the commit URL with:
```powershell
git log --oneline -1
# Then visit: https://github.com/nasimhwb/neos-platform/commit/<SHA>
```

Or for a range:
```
https://github.com/nasimhwb/neos-platform/compare/<old-sha>...<new-sha>
```
