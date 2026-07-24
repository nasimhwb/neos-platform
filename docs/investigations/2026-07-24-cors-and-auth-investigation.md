# Investigation Report: Staging Auth CORS & Schema Resolution

**Date:** 2026-07-24  
**Investigator:** SRE & Integration Team  
**Target:** `https://test.neosfacility.com`  

---

## 1. Problem
Requests to authenticate or query user profiles on `https://test.neosfacility.com` failed during staging verification. Frontend browser requests were blocked by CORS headers at the Kong API Gateway, and database queries for `.from('profiles')` returned errors due to schema structure changes.

---

## 2. Evidence

### Browser
- User login on `https://test.neosfacility.com/login` failed to complete auth handshake.

### Network
- HTTP request to `/auth/v1/token` failed with CORS error:
  `Access to fetch at 'https://test.neosfacility.com/auth/v1/token' from origin 'https://test.neosfacility.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.`

### Console
- Console error log: `TypeError: Failed to fetch (Kong proxy rejected origin header)`.

### Logs
- Kong access log: `[WARN] Origin https://test.neosfacility.com not present in KONG_CORS_ORIGINS`.
- PostgreSQL log: `ERROR: relation "public.profiles" does not exist`.

### Database
- Query `SELECT * FROM public.profiles;` returned table non-existent error, while `public.client_profiles` was populated with 34 records.

---

## 3. Root Cause
1. **CORS Configuration Gap**: `KONG_CORS_ORIGINS` and `GOTRUE_URI_ALLOW_LIST` in compose and environment definitions contained production domains (`neosfacility.com`) but lacked the staging domain `test.neosfacility.com`.
2. **Schema Naming Discrepancy**: The database setup script created `public.client_profiles`, whereas the frontend codebase issued queries targeted at `public.profiles`.

---

## 4. Fix
1. Updated `docker-compose.yml` and `compose/compose.supabase.yml` environment definitions to append `https://test.neosfacility.com` to `KONG_CORS_ORIGINS` and `GOTRUE_URI_ALLOW_LIST`.
2. Executed schema migration creating `public.profiles` view:
   ```sql
   CREATE OR REPLACE VIEW public.profiles AS SELECT * FROM public.client_profiles;
   ```

---

## 5. Verification
1. **Git Commit**: `cb1ea45d94dca22de74cad4d6d6e1b9d33055fe1` ("fix: add test.neosfacility.com to Kong CORS origins and GoTrue URI allow list").
2. **DB Verification**: Query `SELECT COUNT(*) FROM public.profiles;` returns `34`.
3. **CORS Verification**: Pre-flight HTTP OPTIONS requests return `Access-Control-Allow-Origin: https://test.neosfacility.com`.

---

## 6. Remaining Issues
- VPS deployment environment `.env` file sync required to apply keys to live staging containers.
