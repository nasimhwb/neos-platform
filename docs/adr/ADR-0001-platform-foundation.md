# ADR-0001: Platform Foundation and Infrastructure Stack

* **Status**: Accepted
* **Date**: 2026-07-06
* **Deciders**: Neos Platform Engineering Team
* **Context**: Architectural definition of the shared hosting platform for Neos ERP, CRM, HRMS, Billing Dashboard, Inventory, and future SaaS applications.

---

## 1. Decision Summary
We will establish a cost-effective, secure, and production-ready **Infrastructure-as-Code (IaC)** foundation for the NEOS Platform. The deployment will be hosted on a **Hostinger KVM2 VPS** running **Ubuntu 24.04 LTS**. Orchestration will be managed via **Docker Compose** to run **Nginx** (reverse proxy), **PostgreSQL 16** (multi-tenant database cluster), **Redis** (cache), **MinIO** (S3-compatible object storage), **Portainer CE** (GUI management), **Uptime Kuma** (uptime checking), and a complete **Prometheus, Grafana, Loki, and Promtail** observability stack. Deploys will be automated using **GitHub Actions**.

---

## 2. Rationale & Technology Selection

### 2.1 Hosting and Operating System
* **Decision**: Hostinger KVM2 VPS (2 vCPUs, 4GB RAM, 50GB NVMe storage) with Ubuntu 24.04 LTS.
* **Why**:
  - **Predictable Cost**: Avoids the complex, variable charging model of AWS or GCP, which is critical during early bootstrap phases.
  - **Dedicated Resources**: KVM virtualization ensures CPU and RAM resources are not overcommitted by the host provider, guaranteeing stable database and proxy performance.
  - **OS Stability**: Ubuntu 24.04 LTS provides a modern Linux kernel, security updates for 5+ years, and native compatibility with the latest Docker engines.
* **Alternatives Considered**:
  - *AWS EC2 / ECS*: Too expensive for initial stages; ingress/egress bandwidth costs can scale unpredictably.
  - *Heroku / Render*: High vendor lock-in, strict database limits, and high pricing for custom add-ons.

### 2.2 Orchestration Method
* **Decision**: Docker Compose.
* **Why**:
  - **Resource Efficiency**: A 4GB RAM VPS cannot host a full Kubernetes control plane without degrading performance. Docker Compose uses negligible host resources (<50MB).
  - **Simplicity**: Configuration is defined in a single, version-controlled [docker-compose.yml](file:///d:/Webapp/KVM2/neos-platform/docker-compose.yml), making VPS setup, updates, and recreation from Git extremely straightforward.
* **Alternatives Considered**:
  - *Kubernetes (k8s/k3s)*: Rejected for initial phase due to high memory overhead (~1.5GB to 2GB RAM just to run control plane agents) and high operational complexity.

### 2.3 Database Layer
* **Decision**: PostgreSQL 16 (Separate database and user account per application/tenant).
* **Why**:
  - **Enterprise Grade**: PostgreSQL offers ACID compliance, query optimizations, robust transactions, and strong JSONB support for semi-structured data.
  - **Tenant Isolation**: Implementing separate databases per application ensures security boundaries, allows independent backup/restores, and limits impact if one service suffers a corruption event.
* **Alternatives Considered**:
  - *MySQL*: Good, but lacks PostgreSQL's advanced JSON querying features, rich index types, and active community ecosystem for modern SaaS developments.
  - *Shared Single Database (Schema-based)*: High risk of cross-tenant data leaks and complex maintenance windows.

### 2.4 Caching Layer
* **Decision**: Redis (Password protected, persistence enabled).
* **Why**:
  - **Speed & Structure**: Redis handles session state, cache queries, and queue data structures in memory with sub-millisecond latency.
  - **Durability**: Configured with RDB snapshotting (fast recovery) and AOF logging (minimum data loss) to prevent cash-miss storms on container restarts.
* **Alternatives Considered**:
  - *Memcached*: Lacks data structure variety (only handles simple key-value) and offers no native database persistence.

### 2.5 Object Storage
* **Decision**: MinIO (Self-hosted, S3-compatible).
* **Why**:
  - **Zero Vendor Lock-in**: Because MinIO implements the standard AWS S3 API, application developers can use standard S3 client libraries. The backend can be migrated to AWS S3, Cloudflare R2, or Backblaze B2 in the future by changing environment keys, without modifying any application code.
  - **Cost**: Stores attachments (PDFs, images) on the VPS's NVMe drive for $0 in cloud storage fees during early deployment.
* **Alternatives Considered**:
  - *Direct Local Bind Mounts*: Restricts applications from scaling horizontally and complicates multi-project host mounts.
  - *AWS S3 directly*: Introduces internet latency and cloud subscription dependencies during bootstrapping.

### 2.6 Routing and Ingress
* **Decision**: Nginx Reverse Proxy.
* **Why**:
  - **Performance & Control**: Nginx handles SSL termination, custom header injection (HSTS, CSP), gzip compression, and proxy buffer tuning. It runs with minimal RAM.
  - **ACME Integration**: Configured with a fallback certificate mechanism to allow Certbot to request Let's Encrypt SSL certificates seamlessly.
* **Alternatives Considered**:
  - *Traefik*: Excellent automatic discovery, but complex to write custom Nginx proxy buffers and header overrides.
  - *Caddy*: Automatic SSL is great, but less customizable for high-throughput enterprise routing configurations.

### 2.7 Observability and Monitoring
* **Decision**: Grafana, Prometheus, Loki, Promtail, Uptime Kuma.
* **Why**:
  - **Lightweight Metrics**: Prometheus pulls metrics via HTTP endpoints. Promtail reads log files on the host and containers and streams them to Loki.
  - **Single Pane of Glass**: Grafana visualizes metrics (Prometheus) and logs (Loki) side-by-side, enabling easy correlation of CPU spikes to log errors.
  - **External Monitoring**: Uptime Kuma runs in a separate container, monitoring external subdomains and dispatching instant alerts (Slack/Telegram) if Nginx or services fail.
* **Alternatives Considered**:
  - *ELK Stack (Elasticsearch, Logstash, Kibana)*: Rejected. Elasticsearch requires a minimum of 2GB to 4GB of RAM to run stably, which would exhaust the entire KVM2 VPS.
  - *Datadog / New Relic*: High monthly costs and vendor dependency.

### 2.8 Control Panel / GUI
* **Decision**: Portainer CE (Community Edition).
* **Why**:
  - Provides a safe, browser-based GUI to check container state, restart services, and read container logs without opening SSH ports to developers.
* **Alternatives Considered**:
  - *Command Line only*: Impedes non-sysadmin developers from quickly validating container status.
  - *Rancher*: Too heavy for a single-node VPS.

---

## 3. Deployment and CI/CD (GitHub Actions)

* **Trigger**: Push or Merge to the `main` branch.
* **Process**:
  1. Automated linting of configuration files.
  2. Secure SSH transfer of configuration updates to the VPS.
  3. Re-run `scripts/deploy.sh` to pull latest images, build modified proxy containers, and reload services without downtime.
* **Benefits**: Reproducible, audit-logged deployments. Zero manual terminal deployment errors.

---

## 4. Operational Strategies

### 4.1 Backup Strategy (Automatic)
- Nightly execution of [backups/backup.sh](file:///d:/Webapp/KVM2/neos-platform/backups/backup.sh) via cron.
- **Components**:
  - Individual database `pg_dump` files, compressed (`.sql.gz`).
  - Forced Redis `SAVE` to write a clean `dump.rdb` file.
  - Compressed Tarball of MinIO persistent directories.
- **Offsite Storage**: Local backups are stored in `/srv/neos/backups` and synced offsite to S3-compatible cold storage (e.g., Backblaze B2) using `rclone`.
- **Retention**: Local backups are pruned after 14 days.

### 4.2 Disaster Recovery (Restore Strategy)
- The [backups/restore.sh](file:///d:/Webapp/KVM2/neos-platform/backups/restore.sh) script handles recovery by:
  - Wiping target volumes safely via short-lived Alpine container mounts.
  - Dropping and recreating target databases to avoid conflicts.
  - Re-injecting backups before starting up services.
- Allows rapid bare-metal rebuild of the VPS host in under 1 hour.

### 4.3 Upgrade Strategy
- Base image tags in the `.env` file are pinned to specific major/minor versions (e.g. `POSTGRES_VERSION=16.3-alpine`).
- Automatic or wild card pulling (`latest` tags) is strictly prohibited to avoid breaking changes.
- Upgrades are tested locally, the version string is updated in Git, and the deploy script runs the upgrade.

### 4.4 Security Strategy
- **Network Isolation**: Only Nginx exposes ports (80/443) to the public interface. PostgreSQL, Redis, Loki, Promtail, and Prometheus are inaccessible from the outside internet.
- **Firewall**: UFW blocks all host ports except 22 (SSH), 80, and 443.
- **Credential Rotation**: All passwords and keys are sourced from the `.env` file (which is git-ignored) and injected at container runtime.

---

## 5. Kubernetes Migration Path (Future Proofing)

While we are starting with Docker Compose for resource efficiency, the stack is designed for a direct migration to Kubernetes (such as K3s or managed EKS/GKE) as the platform scales:

1. **Decoupled Architecture**: All services communicate via network hostnames (`db`, `cache`, `object-store`), which translates directly to Kubernetes DNS Services.
2. **Environment-Driven Configuration**: Application configurations are isolated to environment variables, making it easy to translate them into Kubernetes `ConfigMaps` and `Secrets`.
3. **API Standards**: Because we chose MinIO (S3-compatible API), migrating to cloud object storage requires zero changes to application code.
4. **Volumes**: Persistent Docker volumes can be mapped directly to Kubernetes Persistent Volume Claims (PVCs) using CSI drivers.
5. **Ingress**: The Nginx configuration blocks map directly to standard Kubernetes Ingress controllers or Gateway APIs.
