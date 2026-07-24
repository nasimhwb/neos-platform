# NEOS Platform — Authentication Architecture

**Last Updated:** 2026-07-24  

---

## 1. Authentication Flow Overview

NEOS Platform uses Supabase GoTrue Auth for user identity, JWT generation, and session management.

```mermaid
sequenceDiagram
    participant User as Client Browser
    participant Next as Next.js Middleware
    participant GoTrue as Supabase Auth (GoTrue)
    participant DB as PostgreSQL (public.profiles)

    User->>GoTrue: POST /auth/v1/token?grant_type=password (email, password)
    GoTrue-->>User: Return JWT access_token & set sb-access-token cookie
    User->>Next: GET /dashboard/tasks (Cookie: sb-access-token)
    Next->>GoTrue: Verify token signature against JWT Secret
    Next->>DB: Query public.profiles using user.id
    DB-->>Next: Return profile role & linked_employee_id
    Next-->>User: Render Dashboard UI
```

---

## 2. Key Secret Specifications

* **Staging Provider**: Self-Hosted GoTrue (`https://supabase.neosfacility.com/auth/v1`)
* **JWT Signing Secret**: `PGRST_JWT_SECRET` (`ChangeThisToASuperSecureJWTSecretKey123!`)
* **Anon Key**: HMAC-SHA256 token scoped to `role: anon`
* **Service Role Key**: HMAC-SHA256 token scoped to `role: service_role` with bypass RLS privileges.
