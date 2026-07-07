# NEOS Platform Dashboard Architecture

This document describes the design and architecture of the NEOS Platform Dashboard.

## Overview

The NEOS Platform Dashboard serves as the central control plane and visual management console for the entire NEOS self-hosted infrastructure. Rather than relying on multiple separate dashboards (e.g., Portainer, Grafana, MinIO Console, Uptime Kuma, CLI, and direct database queries), the NEOS Dashboard aggregates status information, metrics, resource utilization, backups, and security events into a single, unified interface.

## Tech Stack

- **Framework**: Next.js 15 (using App Router, server-side rendering, and API routes)
- **Language**: TypeScript
- **Styling**: Tailwind CSS v4 & custom variables for high-fidelity dark-themed UI
- **Components**: Primitive custom components styled with `clsx` and class variance authorities, inspired by shadcn/ui.
- **Icons**: `lucide-react`
- **Charting**: `recharts` for memory, CPU, and disk usage visualization

## Components & Layout

The dashboard is structured into 14 distinct modules:

1. **Overview**: Comprehensive view of CPU, Memory, Disk, Swap, Load Average, Docker status, active alerts, and deployment color.
2. **Applications**: Status cards for all platform application services (CRM, ERP, Billing, Inventory, visitor, AI, Neos-App) with quick action controls.
3. **Infrastructure**: Diagnostic view of Docker Engine version, containers list with resource usage, network subnets, and volume paths/sizes.
4. **PostgreSQL**: Postgres 16 engine stats, active connections, list of databases and sizes, and active database users/roles.
5. **Redis**: Cache stats, memory/eviction policy, persistence status (AOF/RDB), command rate, and client connections.
6. **Object Storage**: MinIO bucket size/object count, bucket access policies, and storage users list.
7. **Monitoring**: Promethean scrape targets status, Alertmanager firing and resolved alerts, and Uptime Kuma monitoring feeds.
8. **Backups**: Enterprise backup history, verification state, encryption keys, and countdown to next scheduled backup.
9. **Deployments**: History of Blue-Green app releases, Git commits/branches, deployment duration, and rollback actions.
10. **Logs**: Aggregated system, Docker, and application logs feed with log level filters.
11. **SSL**: Let's Encrypt certificate validation states, remaining days warnings, and auto-renewal checks.
12. **Security**: Firewall status, Fail2Ban blocks, SSH login attempt audits, and open ports checks.
13. **Users**: Platform user roles, permissions matrix, and invitations.
14. **Settings**: Environment configuration and maintenance mode controls.

---

## Security Model

The NEOS Dashboard is designed with a **Server-Side API Abstraction Layer**:
- The dashboard UI does NOT call Portainer, the Docker socket, PostgreSQL, Redis, or MinIO directly from the client.
- Instead, the UI invokes Next.js internal API routes (`/api/*`).
- These API routes perform authorized queries on the host machine or inside the Docker network.
- Docker sockets, DB passwords, and other sensitive credentials never leave the host server.

---

## Service Abstraction Layer

The dashboard defines a TypeScript interface and service provider design:
- `lib/types/index.ts` contains the formal type models for all modules.
- `lib/mock-data.ts` offers a high-fidelity mock implementation returning structured, realistic platform data.
- The UI pages consume this mock data, which simulates live responses from actual services.
- Real backend adapters (e.g., Docker SDK, PG client, Redis client, Prometheus API) can be introduced progressively without modifying page designs.

---

## Future Roadmap

1. **Active Controller Integration**: Connect mock services to active commands (e.g., executing `docker restart` or triggering database backups via `/api/*`).
2. **Prometheus & Loki Direct Queries**: Configure real Prometheus HTTP and Loki API integrations into `/api/metrics` and `/api/logs` respectively.
3. **SSO Authentication**: Replace local credentials with SSO auth.
