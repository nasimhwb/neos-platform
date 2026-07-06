# Neos Platform Shared Infrastructure

A production-ready infrastructure repository managing shared databases, caching, object storage, routing, and logging/monitoring services for multiple Neos SaaS products (ERP, CRM, HRMS, Billing Dashboard, Inventory).

Orchestrated using **Docker Compose** and configured to run on an **Ubuntu 24.04 LTS VPS**.

---

## Architecture Components

1. **Nginx** (Reverse Proxy & Gateway) - Handles HTTPS redirection, security headers, and reverse proxy routing.
2. **PostgreSQL 16** (Database) - Optimized VPS database cluster with automated multi-database initialization.
3. **Redis 7** (Cache) - High-performance Cache/Session store with RDB/AOF double-persistence.
4. **MinIO** (Object Storage) - Production-ready, S3-compatible file and asset storage.
5. **Observability Stack**:
   - **Prometheus** for metric collection.
   - **Grafana Loki** for log aggregation.
   - **Promtail** for log shipping.
   - **Grafana** for dashboard visualization.
   - **Node Exporter** for host hardware tracking.

---

## Folder Structure

```
neos-platform/
├── README.md               # Main onboarding and setup documentation
├── docker-compose.yml      # Service orchestration config
├── .env.example            # Environment variables configuration template
├── .gitignore              # Files ignored by Git (logs, credentials, data)
├── nginx/                  # Gateway files
│   ├── Dockerfile
│   ├── nginx.conf          # Global Nginx performance config
│   └── conf.d/             # Routing configuration per service
├── postgres/               # Database files
│   ├── postgresql.conf     # Tuned postgres configuration parameters
│   └── init-scripts/       # Automates multi-database creation
├── redis/                  # Caching files
│   └── redis.conf          # Redis persistence and memory policies
├── monitoring/             # Observability configurations
│   ├── prometheus/
│   ├── loki/
│   └── promtail/
├── backups/                # Backup scripts
│   ├── backup.sh           # Nightly database, cache, object storage dump
│   └── restore.sh          # Full state recovery script
├── docs/                   # Architectural & operations documentation
│   ├── architecture.md
│   ├── disaster-recovery.md
│   ├── runbook.md
│   └── adr/                # Architecture Decision Records
│       └── ADR-0001-platform-foundation.md
└── scripts/                # Operations automation scripts
    ├── setup-vps.sh        # Host provisioning script (Docker, sysctl, UFW)
    └── deploy.sh           # Deployment trigger script
```

---

## Quick Start: Host VPS Deployment

Follow these steps to deploy this repository on a clean Ubuntu 24.04 VPS.

### Step 1: Clone the Repository
```bash
git clone https://github.com/nasimhwb/neos-platform.git /srv/neos-platform
cd /srv/neos-platform
```

### Step 2: Configure Environment
Copy the example file to `.env` and fill in custom credentials, domain settings, and passwords:
```bash
cp .env.example .env
nano .env
```

### Step 3: Run VPS Provisioning Script
Make all scripts executable and run the host configuration script as root:
```bash
chmod +x scripts/setup-vps.sh scripts/deploy.sh backups/backup.sh backups/restore.sh
sudo ./scripts/setup-vps.sh
```
*This installs Docker, adjusts kernel sysctl settings, configures the UFW firewall, and generates dummy self-signed SSL certificates to bootstrap Nginx.*

### Step 4: Deploy the Infrastructure
Use the deploy script to pull images, build the custom proxy container, and spin up services:
```bash
./scripts/deploy.sh
```

### Step 5: Configure SSL (Let's Encrypt)
Once the Nginx proxy is running, request real Let's Encrypt certificates to overwrite the dummy bootstrap certs:
```bash
sudo certbot certonly --webroot -w /srv/neos/www \
  -d neos-platform.local \
  -d erp.neos-platform.local \
  -d crm.neos-platform.local \
  -d hrms.neos-platform.local \
  -d billing.neos-platform.local \
  -d inventory.neos-platform.local \
  -d s3.neos-platform.local \
  -d s3-console.neos-platform.local \
  -d monitor.neos-platform.local
```
Reload Nginx to pick up the certificates:
```bash
docker compose exec reverse-proxy nginx -s reload
```

---

## Documentation & Decisions

For architecture decisions, operations guidelines, and recovery procedures, refer to the documentation:
- [ADR-0001: Platform Foundation & Tech Stack Selection](docs/adr/ADR-0001-platform-foundation.md)
- [System Architecture Details](docs/architecture.md)
- [Operations Runbook](docs/runbook.md)
- [Disaster Recovery Procedures](docs/disaster-recovery.md)
