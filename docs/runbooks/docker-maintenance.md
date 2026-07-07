# Docker Daemon Production Operations & Maintenance Runbook

This document describes the operational procedures for managing, auditing, and upgrading the Docker Engine and Docker Compose stacks on the NEOS Platform VPS.

---

## 1. Production Configuration Reference

The Docker daemon is configured at `/etc/docker/daemon.json` with the following parameters:
- **`storage-driver`**: `overlay2` (default, highly optimized filesystem driver for modern Linux kernels).
- **`log-driver`**: `json-file` (preserves docker CLI logs capability).
- **`log-opts`**: Limit file sizes (`max-size: "50m"`, `max-file: "3"`) to prevent disk leaks.
- **`live-restore`**: `true` (enables upgrading or restarting the Docker daemon without shutting down or restarting active container workloads).
- **`userland-proxy`**: `false` (disables the userland routing proxy, passing packet routing directly to iptables to reduce memory usage and increase network throughput).
- **`no-new-privileges`**: `true` (restricts container processes from gaining new privileges via SUID binaries).
- **`fixed-cidr-v6`**: `fd00::/80` (configured dynamically if host VPS supports IPv6 routing).

---

## 2. Operations and Maintenance Tasks

### Task A: Auditing Log Rotation
To verify that container logs are adhering to log rotation constraints and not leaking space:
1. Identify the log path of a container:
   ```bash
   docker inspect --format='{{.LogPath}}' <container_name>
   ```
2. Verify that log files do not exceed the `50MB` threshold:
   ```bash
   ls -lh $(docker inspect --format='{{.LogPath}}' <container_name>)
   ```

### Task B: Storage Cleanup (Pruning)
Over time, unused images, build caches, and volumes consume disk space.
1. Run a quick storage audit:
   ```bash
   docker system df
   ```
2. Reclaim space by pruning dangling images and build cache:
   ```bash
   make clean
   ```
   *Note: This targets untagged builder caches and stopped containers safely.*

### Task C: Safe Docker Upgrades (`live-restore`)
Because `live-restore` is enabled in `daemon.json`, upgrading the Docker Engine package does not cause container downtime.
To upgrade Docker packages safely:
1. Run package updates:
   ```bash
   sudo apt-get update
   sudo apt-get install --only-upgrade -y docker-ce docker-ce-cli containerd.io
   ```
2. Check container status to ensure they remained online during the daemon reload:
   ```bash
   docker ps
   ```

### Task D: Verifying Network Boundaries
To check which containers are attached to a specific isolated network:
1. Inspect the target network (e.g. `neos-database`):
   ```bash
   docker network inspect neos-database
   ```
2. Confirm that only the allowed containers (like `neos_postgres`, `neos_redis`) are bound under the `Containers` section.
