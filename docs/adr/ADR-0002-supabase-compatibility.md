# ADR-0002: Supabase Compatibility Layer Design

## Status
Approved

## Context
The Neos SaaS Client Application (`neos-app`) is currently coupled to the Supabase hosted platform (PostgreSQL, Supabase Auth, Supabase Storage, Realtime, and Edge Functions). To secure data ownership, reduce vendor costs, and enforce zero-downtime Blue-Green deployments on our private VPS node, we need to migrate away from Supabase. 

The primary constraint is that the migration must require **minimal code changes** in the client application codebase.

## Decision
We will deploy a self-hosted **Supabase Compatibility Layer** directly on our Docker Compose platform. This replication layer will run the exact open-source components that power Supabase:

1. **Kong** as the central API Gateway.
2. **GoTrue** (Auth) to manage JWT sign-in, login, and sessions.
3. **PostgREST** to automatically generate REST APIs from our PostgreSQL schemas.
4. **Supabase Storage API** (Node-based S3 adapter) to proxy file uploads to our MinIO cluster.
5. **Realtime** (Elixir-based WAL reader) for broadcast and DB event streaming over WebSockets.

By keeping the routing paths (`/auth/v1`, `/rest/v1`, `/storage/v1`, `/realtime/v1`) identical, the client application can switch from Supabase to our private VPS by simply updating its configuration variables:
```env
SUPABASE_URL=https://supabase.neos-platform.local
SUPABASE_ANON_KEY=local_jwt_anon_key
```

### Alternatives Considered
* **Complete Codebase Rewrite**: Refactoring the app to use Express/Node.js backend with Prisma ORM. *Rejected* due to massive code churn, high cost, and disruption to product roadmaps.
* **Custom Translation API Wrappers**: Writing thin custom proxy controllers translating Supabase queries to raw SQL. *Rejected* due to maintenance overhead and difficulty matching Supabase API features (e.g. Realtime filtering, dynamic storage auth).

---

## Unreplicated Features & Proposed Alternatives

The following Supabase platform features cannot be directly mirrored in a minimal self-hosted Compose cluster without substantial memory overhead, and are replaced with enterprise alternatives:

| Supabase Feature | Self-Hosted Status | Proposed Production Alternative |
| :--- | :--- | :--- |
| **Supabase Studio (UI)** | Available (`supabase/studio` image) | **Do not deploy in production**. It consumes substantial RAM and exposes a security hole. Use **PgAdmin**, **Portainer**, or **DBeaver** secured behind VPNs for database operations. |
| **Edge Functions** | Deno runtime dependent | Host Edge Functions as independent **Dockerized microservices** (e.g. Node.js/Python) or deploy the open-source **Deno Edge Runtime** container in `compose.supabase.yml` if Deno-specific features are critical. |
| **Auth SMTP Mail** | Mocked in development | Configure GoTrue to route authentication emails (invitations, password resets) using a dedicated SMTP service (e.g. SendGrid, Mailgun) via environment variables. |
| **Automatic Backups** | Platform-managed | Handled by our platform's **GPG-encrypted backup engine** (`backup.sh` and `test-restore.sh`). |

---

## Consequences
* **Zero Client Code Changes**: The application continues to use `@supabase/supabase-js` without modifications.
* **Memory Footprint**: Self-hosting these five services adds approximately 300MB-500MB RAM overhead on the VPS. This is well within the KVM2 VPS's 4GB RAM threshold.
* **Security & RLS**: PostgreSQL Row Level Security (RLS) remains 100% active, as PostgREST honors RLS rules by parsing JWT scopes supplied by GoTrue.
