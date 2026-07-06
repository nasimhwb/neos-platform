# Neos Platform Shared Infrastructure - Networking Documentation

This document describes the networking architecture, DNS mapping rules, and subdomain routing configurations of the shared private cloud platform.

## Network Topology

We define two virtual bridge networks using Docker Compose to enforce security isolation:

1. **`neos_frontend` (Public Gateway Network)**:
   - **Access**: Attaches to the Nginx reverse proxy gateway and public-facing services (MinIO Console, Grafana, Uptime Kuma).
   - **Objective**: Directs external requests into targeted containers securely.
2. **`neos_backend` (Private Service Network)**:
   - **Access**: Strictly internal. Attaches to PostgreSQL database clusters, Redis cache instances, internal prometheus collectors, Loki loggers, and application backends.
   - **Objective**: Prevents databases and caches from publishing ports on the host VPS network card directly, blocking network scanning attacks.

---

## Subdomain Mapping and Routing

Traffic routing is controlled via Virtual Host server blocks in Nginx under `configs/nginx/conf.d/*.conf`. Subdomains route to their respective Docker service name and internal port:

| Subdomain | Target Container Name | Internal Port | Network Type | Description |
| :--- | :--- | :--- | :--- | :--- |
| `erp.neos-platform.local` | `neos_erp_app` | `8000` | Backend | Neos ERP Application |
| `crm.neos-platform.local` | `neos_crm_app` | `8000` | Backend | Neos CRM Application |
| `hrms.neos-platform.local` | `neos_hrms_app` | `8000` | Backend | Neos HRMS Application |
| `billing.neos-platform.local` | `neos_billing_app` | `8000` | Backend | Neos Billing Dashboard |
| `inventory.neos-platform.local` | `neos_inventory_app` | `8000` | Backend | Neos Inventory App |
| `s3.neos-platform.local` | `neos_minio` | `9000` | Frontend + Backend | MinIO S3 API Endpoint |
| `s3-console.neos-platform.local` | `neos_minio` | `9001` | Frontend + Backend | MinIO Web Admin Console |
| `monitor.neos-platform.local` | `neos_grafana` | `3000` | Frontend + Backend | Grafana Observability Dashboards |
| `status.neos-platform.local` | `neos_uptime_kuma` | `3001` | Frontend + Backend | Uptime Kuma Status |

---

## SSL/TLS Configuration and Acme Verification

Nginx uses the Mozilla Intermediate configuration by default, enforcing TLS 1.3 & 1.2 with strong ciphers.

- **SSL Storage**: Certificates are mapped from the host `/srv/neos/letsencrypt/` directory into the Nginx container `/etc/letsencrypt/` read-only.
- **Acme HTTP Challenge**: To request or renew certificates, Certbot uses a webroot challenge validation. The directory `/srv/neos/www/` is mounted into Nginx, allowing Let's Encrypt validation requests matching `/.well-known/acme-challenge/` to resolve without SSL:
  ```nginx
  location ~/.well-known/acme-challenge/ {
      root /var/www/html;
      allow all;
      default_type "text/plain";
      try_files $uri =404;
  }
  ```
