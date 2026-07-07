# Traefik Reverse Proxy Production Operations Runbook

This document describes the operational maintenance, troubleshooting steps, TLS verification, and middleware adjustment procedures for the Traefik v3 Ingress Gateway on the NEOS Platform.

---

## 1. Middleware Management

All traffic passes through predefined middlewares configured in `configs/traefik/dynamic.yml`:

### Adjusting Rate Limiting
To increase or decrease API rate limits, modify the `rate-limit` block:
```yaml
    rate-limit:
      rateLimit:
        average: 150   # Allowed requests per second average
        burst: 300     # Maximum burst requests
```

### Rotating Dashboard basic-auth Credentials
The Traefik dashboard is protected by Basic Auth. To change the password:
1. Generate a new `bcrypt` password hash:
   ```bash
   # Using htpasswd utility
   htpasswd -nbB admin "NewSecurePasswordHere!"
   
   # Output example: admin:$2y$05$1G/zXz93H511.456123...
   ```
2. Update the `users` array in `configs/traefik/dynamic.yml` under `dashboard-auth`:
   ```yaml
   dashboard-auth:
     basicAuth:
       users:
         - "admin:NEW_BCRYPT_HASH_HERE"
   ```
3. Save the file. Traefik automatically watches the file and reloads the authentication configuration dynamically—no container restarts required!

---

## 2. Let's Encrypt / ACME Diagnostics

Traefik manages certificate registration and renewals automatically inside the `/letsencrypt/acme.json` file.

### Auditing Certificate Store
To inspect the domains and certificates currently held by Traefik:
1. Log in to the VPS and check the `acme.json` file size:
   ```bash
   ls -lh /srv/neos/shared/ssl/acme.json
   ```
2. View registered domains inside `acme.json` (requires root privileges due to strict file permissions `0600`):
   ```bash
   sudo jq '.letsencrypt.Certificates[].domain.main' /srv/neos/shared/ssl/acme.json
   ```

### Troubleshooting Cert Resolving Failures
If a domain shows SSL warning errors in browsers:
1. Confirm that port `80` is open on the VPS firewall and DNS records are resolving to the VPS host IP.
2. Inspect the Traefik log streams for ACME challenge errors:
   ```bash
   make logs service=reverse-proxy | grep -E "acme|letsencrypt"
   ```
3. Common error is rate limits on Let's Encrypt API or DNS propagation delays.

---

## 3. Docker Socket Permissions

Traefik requires read-only access to `/var/run/docker.sock` to detect container labels.
* If Traefik logs report `Permission denied` when connecting to the Docker socket:
  1. Confirm that the `nasim` user running the compose stack is added to the `docker` group on the host.
  2. Verify socket mount permissions inside `compose/compose.proxy.yml` (must be `:ro`).
  3. Run `ls -lh /var/run/docker.sock` on the host to ensure permissions are `srw-rw----` and owned by `root:docker`.
