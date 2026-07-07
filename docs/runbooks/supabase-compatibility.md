# Supabase Compatibility Layer Runbook

This document details the configuration, user permissions, security architectures, and troubleshooting steps for the self-hosted Supabase Compatibility Layer.

---

## 1. Environment Configurations & Bindings

To point `neos-app` or other clients from hosted Supabase to our self-hosted VPS platform, modify the client application's env variables:

```env
# Point to our Kong API Gateway endpoint
SUPABASE_URL=https://supabase.neos-platform.local

# Local JWT Anon Key and Service Key (derived from JWT_SECRET)
SUPABASE_ANON_KEY=local_jwt_anon_key
SUPABASE_SERVICE_KEY=local_jwt_service_key
```

### Server-Side Keys (.env)
The compatibility stack relies on these server-side configurations:
* **`JWT_SECRET`**: Symmetric HS256 key used by GoTrue to sign and by PostgREST / Storage to verify user JWT claims.
* **`POSTGRES_SUPABASE_ADMIN_PASSWORD`**: DB password for the `supabase_admin` superuser role.
* **`POSTGRES_AUTHENTICATOR_PASSWORD`**: DB password for the `authenticator` connection pool proxy role.

---

## 2. PostgreSQL Role Requirements & RLS

PostgREST honors PostgreSQL Row Level Security (RLS) dynamically using database roles. The compatibility layer requires the following database configuration (initialized via [02-supabase-compat.sql](file:///d:/Webapp/KVM2/neos-platform/configs/postgres/init-scripts/02-supabase-compat.sql)):

* **`anon`**: Non-login role. Bound to unauthorized client connections.
* **`authenticated`**: Non-login role. Bound to logged-in sessions presenting a valid JWT.
* **`service_role`**: Non-login role. Possesses bypass RLS permissions.
* **`authenticator`**: Login role. Authenticates PostgREST connection pools. PostgREST switches session authorization context dynamically to `anon` or `authenticated` depending on request headers.

### Row Level Security (RLS) Compatibility
Because PostgREST translates JWT scopes directly to database user context, all standard Supabase RLS policies remain 100% compatible.
Example of standard RLS policy:
```sql
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only read their own profile" ON user_profiles
    FOR SELECT
    USING (auth.uid() = id);
```
PostgREST maps the client JWT `sub` claim to the SQL session parameter `request.jwt.claims`, which resolves `auth.uid()` automatically!

---

## 3. JWT Secret Rotation Procedure

Rotating the `JWT_SECRET` invalidates all currently active user sessions, forcing users to sign in again.

1. Generate a new high-entropy secret (HS256 requires minimum 32 bytes):
   ```bash
   openssl rand -hex 32
   ```
2. Update `JWT_SECRET` in `/srv/neos/shared/.env` on the host VPS.
3. Restart the compatibility stack to apply:
   ```bash
   docker compose -f compose/compose.supabase.yml down
   docker compose -f compose/compose.supabase.yml up -d
   ```

---

## 4. Troubleshooting Ingress Gateway

If the Supabase API returns errors:
* **Kong logs**: Check Kong routing errors:
  ```bash
  docker logs neos_supabase_gateway
  ```
* **PostgREST logs**: If database schema fetches fail, verify authenticator credentials:
  ```bash
  docker logs neos_supabase_rest
  ```
* **Realtime logs**: If WebSocket client subscriptions drop, inspect WAL replication slots in Postgres:
  ```bash
  docker exec -t neos_postgres psql -U postgres -c "SELECT * FROM pg_replication_slots;"
  ```
  *Ensure the slot name `supabase_realtime_rcv` exists and is active.*
