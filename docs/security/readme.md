# Neos Platform Shared Infrastructure - Security Documentation

This document describes the security policies, hardening controls, and access boundaries configured for the Neos Platform shared infrastructure.

## System Hardening Controls

### 1. Host Firewall (UFW)
The Host system blocks all incoming networking ports by default. The firewall rules are automated inside `bootstrap/security.sh`:
- **Default Incoming**: Denied.
- **Default Outgoing**: Allowed.
- **Allow Rules**:
  - `22/tcp` (SSH access)
  - `80/tcp` (HTTP web challenge validation)
  - `443/tcp` (HTTPS secure web proxy)

### 2. Sysctl Kernel Configurations
Tuned parameters are set in `/etc/sysctl.d/99-neos-platform.conf` during host provisioning:
- `vm.overcommit_memory = 1`: Enabled for Redis to prevent forks from crashing when memory reserves are low.
- `fs.file-max = 2097152`: Increases file descriptor maximums, essential for high-concurrency Nginx reverse proxies and Loki shippers.
- `net.core.somaxconn = 65535`: Raises host socket listen backlogs to prevent dropping connection requests during traffic spikes.

---

## Container Security & Network Isolation

### 1. Network Segment Boundaries
Core databases and application containers do not publish host port bindings (`ports: ...`).
- All inter-container communication uses Docker internal hostnames within the `neos_backend` network.
- SQL injections, cross-app threats, or scanning vectors cannot interact with internal services directly without proxying through Nginx first.

### 2. Privilege Escalation Mitigation
Where containers require privileged API bindings, we restrict options:
- **Portainer Docker Socket**: Portainer mounts the host Docker socket (`/var/run/docker.sock:ro`) as **read-only** to prevent compromised Portainer instances from modifying host configurations.
- **`no-new-privileges:true`**: Enforced on Portainer and core templates to prevent containers from gaining extra permissions via SUID binaries.

---

## Logging Limits and Storage Protections

Stdout container logging can easily exhaust storage on a shared VPS.
- **Log Limits**: `/etc/docker/daemon.json` defines global log rotation for all containers:
  ```json
  {
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "50m",
      "max-file": "3"
    }
  }
  ```
- **Log Aggregation**: Promtail scrapes container logs and ships them to Loki. This decouples long-term log retention from the VPS host file limits, allowing system operators to maintain audit trails without consuming host storage.
