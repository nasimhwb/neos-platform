# NEOS Platform - Go-Live Routing & DNS Guide

- **Author**: Principal Platform Architect & SRE
- **Target VPS**: Hostinger KVM2 (`200.97.161.179`)
- **Status**: **ROUTING ACTIVE & VERIFIED**
- **Traefik Version**: `v3.7.8` (Upgraded from `v3.0.4` to fix Docker API compatibility)

---

## 1. Routing Validation Report

We successfully resolved the reverse-proxy routing blockers:

| Routing Verification Step | Expected Result | Actual Result | Status |
| :--- | :--- | :--- | :--- |
| **Container Status** | `neos_dashboard` running | `Up (healthy)` | **PASS** |
| **Network Configuration** | Attached to `neos-public` + internal networks | Connected to `neos-public`, `neos-private`, `neos-monitoring`, `neos-database` | **PASS** |
| **Traefik Discovery** | Container labels successfully written | Service-level labels mapped to container metadata | **PASS** |
| **Docker API Compatibility** | No negotiation client version errors | Upgraded to Traefik v3.7.8 with environment override `DOCKER_API_VERSION=1.40` | **PASS** |
| **HTTP Redirect (80 -> 443)** | Redirects to HTTPS | Returns `301 Moved Permanently` | **PASS** |
| **HTTPS Route Reachability** | API Health returns healthy status | `/api/health` returns `200 OK` (overall: "healthy") | **PASS** |

### Live API Verification Result:
```json
{
  "data": {
    "overall": "healthy",
    "services": [
      { "name": "PostgreSQL", "status": "healthy" },
      { "name": "PgBouncer", "status": "healthy" },
      { "name": "Redis", "status": "healthy" },
      { "name": "MinIO", "status": "healthy" },
      { "name": "Docker", "status": "healthy", "message": "Docker engine online. Running containers: 18." },
      { "name": "Monitoring", "status": "healthy" }
    ],
    "system": { "cpuUsage": 13, "memoryUsage": 19, "diskUsage": 12 }
  }
}
```

---

## 2. DNS Configuration Guide

For the platform to be reachable by clients/browsers publicly, configure the following DNS records in your domain registrar (e.g., Cloudflare, GoDaddy):

| Host / Subdomain | Record Type | TTL | Target Value | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `dashboard.neosfacility.com` | **A** | 300 (5 min) | `200.97.161.179` | Unified Platform Dashboard |
| `supabase.neosfacility.com` | **A** | 300 (5 min) | `200.97.161.179` | Supabase API (GoTrue, PostgREST, Realtime) |
| `monitor.neosfacility.com` | **A** | 300 (5 min) | `200.97.161.179` | Grafana Observability Dashboard |
| `s3.neosfacility.com` | **A** | 300 (5 min) | `200.97.161.179` | MinIO Object Storage API |
| `console.s3.neosfacility.com` | **A** | 300 (5 min) | `200.97.161.179` | MinIO Storage console dashboard |
| `status.neosfacility.com` | **A** | 300 (5 min) | `200.97.161.179` | Uptime Kuma Status Page |
| `app.neosfacility.com` | **A** | 300 (5 min) | `200.97.161.179` | Core Neos App Target endpoint |

---

## 3. Host Mapping Guides (Local Testing)

If DNS records are not yet active/propagated, map the domains locally on your client machine.

### A. Windows Hosts File
File path: `C:\Windows\System32\drivers\etc\hosts`
Run Notepad as Administrator and append:
```hosts
# NEOS Self-Hosted Platform Routing
200.97.161.179 dashboard.neosfacility.com
200.97.161.179 supabase.neosfacility.com
200.97.161.179 monitor.neosfacility.com
200.97.161.179 s3.neosfacility.com
200.97.161.179 console.s3.neosfacility.com
200.97.161.179 status.neosfacility.com
200.97.161.179 app.neosfacility.com
```

### B. Linux / macOS Hosts File
File path: `/etc/hosts`
Run `sudo nano /etc/hosts` and append:
```hosts
# NEOS Self-Hosted Platform Routing
200.97.161.179 dashboard.neosfacility.com
200.97.161.179 supabase.neosfacility.com
200.97.161.179 monitor.neosfacility.com
200.97.161.179 s3.neosfacility.com
200.97.161.179 console.s3.neosfacility.com
200.97.161.179 status.neosfacility.com
200.97.161.179 app.neosfacility.com
```

---

## 4. SSL Instructions

Traefik is configured with Let's Encrypt automated ACME certificate management. 
For production SSL certificates to issue successfully:

1. **DNS Propagation**: Ensure the DNS A-records listed above are fully propagated (so Let's Encrypt can pass HTTP challenges).
2. **ACME Configuration**: Check that `ACME_EMAIL` in `/srv/neos/neos-platform/.env` is set to a valid administrator email.
3. **Firewall Settings**: Ensure ports `80` and `443` are open (handled automatically by `make bootstrap` UFW rules).
4. **Certificate Validation**: Traefik automatically requests certificates on startup. Watch the log output to monitor progress:
   ```bash
   docker logs neos_traefik --follow | grep -i acme
   ```

---

## 5. Go-Live Routing Checklist

- [x] **Verify Dashboard Container Network**: Attached to `neos-public`, `neos-private`, `neos-monitoring`, `neos-database`.
- [x] **Service-Level Labels**: Traefik metadata labels moved to the service level for Docker Engine discovery.
- [x] **Docker API Version Integration**: Forced via `DOCKER_API_VERSION=1.40` on Traefik.
- [x] **Traefik Version Upgrade**: Upgraded to Traefik `v3.7.8` to enable version-negotiation and native compatibilities with Docker Engine v29+.
- [x] **SSL Directories Security**: `acme.json` permissions restricted to `600`.
- [ ] **DNS Records Propagation**: A-records mapped to VPS IP.
- [ ] **SSL Challenge Complete**: Confirm secure connection locks in client browsers without self-signed warnings.
