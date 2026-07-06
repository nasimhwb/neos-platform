# Neos Platform Shared Infrastructure - Architecture Documentation

This document describes the high-level architecture, network segmentation, persistence strategy, and security framework for the Neos Platform shared infrastructure.

## Architectural Overview

The shared infrastructure uses a **Hub-and-Spoke** container orchestration design on a single Ubuntu VPS, managed via Docker Compose. Public-facing traffic enters through a single gateway (Nginx), which routes requests internally to service networks.

```
                   +-----------------------------------------------+
                   |                 Public Internet               |
                   +-----------------------+-----------------------+
                                           | HTTP / HTTPS (80/443)
                                           v
+------------------+-----------------------+---------------------------------------+
| VPS Host Boundary                                                                |
|                                                                                  |
|   +--------------------------------------------------------------------------+   |
|   | neos_frontend Network (Bridge)                                           |   |
|   |                                                                          |   |
|   |      +-------------------------------------------------------------+     |   |
|   |      |                    Nginx Reverse Proxy                      |     |   |
|   |      +-----+-----------------------+-------------------------+---+     |   |
|   |            |                       |                         |           |   |
|   +------------|-----------------------|-------------------------|-----------+   |
|                |                       |                         |               |
|   +------------|-----------------------|-------------------------|-----------+   |
|   | neos_backend Network (Bridge - Private)                       |           |   |
|   |            |                       |                         |           |   |
|   |            v                       v                         v           |   |
|   |      +-----------+           +-----------+             +-----------+     |   |
|   |      | PostgreSQL|           |   Redis   |             |   MinIO   |     |   |
|   |      | Database  |           |   Cache   |             | Object St.|     |   |
|   |      +-----------+           +-----------+             +-----+-----+     |   |
|   |                                                              |           |   |
|   |  +-----------------------------------------------------------+           |   |
|   |  |                                                                       |   |
|   |  |   +---------------------------------------------------------------+   |   |
|   |  |   | Observability Stack                                           |   |   |
|   |  |   |                                                               |   |   |
|   |  |   |   +------------+     +------------+     +------------+        |   |   |
|   |  +------>| Prometheus |<----+  Node Exp. |     |  Promtail  |        |   |   |
|   |      |   +-----+------+     +------------+     +-----+------+        |   |   |
|   |      |         |                                     |               |   |   |
|   |      |         v                                     v               |   |   |
|   |      |   +-----+------+                        +-----+------+        |   |   |
|   |      |   |  Grafana   |<-----------------------|    Loki    |        |   |   |
|   |      |   +------------+                        +------------+        |   |   |
|   |      |                                                               |   |   |
|   |      +---------------------------------------------------------------+   |   |
|   |                                                                          |   |
|   +--------------------------------------------------------------------------+   |
+----------------------------------------------------------------------------------+
```

---

## Component Details

### 1. Nginx Reverse Proxy (Gateway)
- **Role**: Entry point for all HTTP/HTTPS traffic. Handles SSL/TLS termination, HTTP-to-HTTPS redirection, and security headers.
- **Network**: Interfaces with both `neos_frontend` and `neos_backend`.
- **Certificates**: Managed using Certbot (Let's Encrypt), mapped from the host `/srv/neos/letsencrypt/` directory.

### 2. PostgreSQL (Database Cluster)
- **Role**: Relational database storage for ERP, CRM, HRMS, Billing Dashboard, and Inventory.
- **Network**: Strictly inside `neos_backend`. Exposed to NO external ports on the VPS.
- **Tuning**: Configured via `postgres/postgresql.conf` for optimized memory use, SSD storage, and autovacuum schedules.
- **Initialization**: Automatically provisions individual databases/users via a start-up hook parsing `.env` file variables.

### 3. Redis (Cache and Session Store)
- **Role**: In-memory key-value cache and session state for the SaaS products.
- **Network**: Strictly inside `neos_backend`.
- **Persistence**: Employs double persistence: RDB snapshots (fast recovery) and AOF logs (minimal write loss).
- **Security**: Bound to all interfaces inside its isolated network; uses password authentication.

### 4. MinIO (S3 Object Storage)
- **Role**: Document and media attachment storage (e.g. invoice PDFs, user avatars, inventory images).
- **Network**: Connected to both networks. Nginx proxies HTTP calls to either the API (port 9000) or Console UI (port 9001).

### 5. Observability (Prometheus + Loki + Grafana)
- **Prometheus**: Pulls time-series metrics from containers.
- **Node Exporter**: Collects system metrics (disk usage, CPU load, RAM utilization) from the host VPS.
- **Loki**: Log aggregation server receiving container and host logs.
- **Promtail**: Ships host system logs (`/var/log/*log`) and Docker JSON container logs (`/var/lib/docker/containers/*/*.log`) to Loki.
- **Grafana**: Web interface serving dashboards. Proxied securely under `monitor.neos-platform.local`.

---

## Security Policies

1. **Least Privilege Networking**: No internal services (Postgres, Redis, Loki, etc.) publish ports to the VPS host interface. All communication is routed internally through bridge networks or proxied by Nginx.
2. **VPS Firewall**: UFW blocks all incoming traffic except port `22` (SSH), `80` (HTTP), and `443` (HTTPS).
3. **Data Encryption**: All traffic over public channels is encrypted via TLS 1.3/1.2 with strong cipher parameters and Strict Transport Security (HSTS) headers enabled.
4. **Volume Isolations**: Persistent data volumes map to managed Docker volumes, backed up nightly to compressed encrypted archives.
