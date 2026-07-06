# Reverse Proxy Comparison: Nginx vs. Traefik

This document compares **Nginx** and **Traefik** as ingress reverse proxies for the NEOS Platform and outlines the long-term maintainability considerations and a future migration path.

---

## Technical Comparison

| Criteria | Nginx Reverse Proxy | Traefik Proxy |
| :--- | :--- | :--- |
| **Service Discovery** | Static configuration file (`conf.d/*.conf`). Requires manual reloads when containers are added or removed. | Dynamic discovery. Automatically detects containers via Docker socket labels without configuration files. |
| **SSL Automation** | Requires external tool (Certbot) running as cron or sidecar. Requires reload to pick up certs. | Native, automatic Let's Encrypt certificates management (built-in ACME solver). Zero extra tools required. |
| **Resource Overhead** | Extremely low RAM footprint (~20-50MB). High CPU efficiency for static file serving. | Moderate RAM footprint (~100-250MB) due to Golang runtime. High networking throughput. |
| **Configuration Syntax** | Procedural scripting configuration. Can become complex to read when mapping many sites. | Declarative. Utilizes YAML or Docker labels on the target containers directly. |
| **Kubernetes Transition** | Integrates well via the Nginx Ingress Controller, but requires Helm values configuration. | Native compatibility. Traefik is built from the ground up for microservices and runs natively as a k8s Ingress. |

---

## Rationale for Current Choice (Nginx)

On the Hostinger KVM2 VPS node, resources are limited (2 vCPUs, 4GB RAM).
1. **Low Overhead**: Nginx's extremely low memory footprint saves memory for PostgreSQL and the application services.
2. **Predictable Routing**: In the early phase, the subdomains for ERP, CRM, HRMS, and Inventory are static. Dynamic discovery is a luxury, not a necessity.
3. **Simpler Debugging**: Experienced sysadmins are universally comfortable debugging Nginx `.conf` files.

---

## Migration Roadmap: Moving to Traefik

If the platform grows to host 15+ subdomains and microservices, migrating to Traefik will improve maintainability:

### Step 1: Add Traefik Service definition
Create a `compose/compose.traefik.yml` stack definition:
```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v3.0
    container_name: neos_traefik
    restart: unless-stopped
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"
      - "--certificatesresolvers.myresolver.acme.email=admin@neos-platform.local"
      - "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /srv/neos/shared/ssl:/letsencrypt
    networks:
      - neos-public
      - neos-private
```

### Step 2: Remove Nginx Service
Delete Nginx service from `compose/compose.proxy.yml` and stop the container.

### Step 3: Attach Labels to Target Applications
Add labels directly to application blocks inside `compose/compose.apps.yml` to instruct Traefik to route traffic:
```yaml
services:
  erp:
    # ...
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.erp.rule=Host(`erp.neos-platform.local`)"
      - "traefik.http.routers.erp.entrypoints=websecure"
      - "traefik.http.routers.erp.tls.certresolver=myresolver"
      - "traefik.http.services.erp.loadbalancer.server.port=8000"
```

### Step 4: Validate and Launch
Deploy the Traefik stack. Traefik will automatically bind to the Docker socket, detect the `erp` container, request SSL certificates from Let's Encrypt, and begin routing traffic.
