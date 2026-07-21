-- ==============================================================================
-- NEOS PLATFORM — SUPABASE COMPATIBILITY LAYER INITIALIZATION
-- ==============================================================================
-- This script creates all PostgreSQL roles, schemas, and extensions required
-- by the self-hosted Supabase stack (GoTrue, PostgREST, Realtime, Storage).
--
-- Run order: After 01-init-databases.sh, before starting supabase containers.
-- Target DB:  postgres (the main Supabase-compatible database)
--
-- Required .env variables substituted at runtime:
--   POSTGRES_SUPABASE_ADMIN_PASSWORD
--   POSTGRES_AUTHENTICATOR_PASSWORD
-- ==============================================================================

\connect postgres

-- ------------------------------------------------------------------------------
-- 1. Extensions
-- ------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ------------------------------------------------------------------------------
-- 2. Create required Supabase roles
-- ------------------------------------------------------------------------------

-- anon: Used by PostgREST for unauthenticated requests
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN NOINHERIT;
    RAISE NOTICE 'Created role: anon';
  ELSE
    RAISE NOTICE 'Role anon already exists, skipping.';
  END IF;
END $$;

-- authenticated: Used by PostgREST for authenticated JWT sessions
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN NOINHERIT;
    RAISE NOTICE 'Created role: authenticated';
  ELSE
    RAISE NOTICE 'Role authenticated already exists, skipping.';
  END IF;
END $$;

-- service_role: Bypasses RLS — used by service-level operations
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
    RAISE NOTICE 'Created role: service_role';
  ELSE
    RAISE NOTICE 'Role service_role already exists, skipping.';
  END IF;
END $$;

-- dashboard_user: Used for Supabase dashboard introspection
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'dashboard_user') THEN
    CREATE ROLE dashboard_user NOLOGIN NOINHERIT;
    RAISE NOTICE 'Created role: dashboard_user';
  ELSE
    RAISE NOTICE 'Role dashboard_user already exists, skipping.';
  END IF;
END $$;

-- supabase_admin: Superuser role used by GoTrue migrations
-- Password is set by the environment variable at container startup.
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') THEN
    CREATE ROLE supabase_admin LOGIN SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS;
    RAISE NOTICE 'Created role: supabase_admin';
  ELSE
    RAISE NOTICE 'Role supabase_admin already exists, skipping.';
  END IF;
END $$;

-- supabase_auth_admin: Owns the auth schema, used internally by GoTrue
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
    CREATE ROLE supabase_auth_admin NOLOGIN SUPERUSER NOINHERIT CREATEROLE;
    RAISE NOTICE 'Created role: supabase_auth_admin';
  ELSE
    RAISE NOTICE 'Role supabase_auth_admin already exists, skipping.';
  END IF;
END $$;

-- authenticator: Login role used by PostgREST connection pool.
-- PostgREST switches to anon/authenticated/service_role based on JWT.
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticator') THEN
    CREATE ROLE authenticator LOGIN NOINHERIT NOCREATEDB NOCREATEROLE NOSUPERUSER;
    RAISE NOTICE 'Created role: authenticator';
  ELSE
    RAISE NOTICE 'Role authenticator already exists, skipping.';
  END IF;
END $$;

-- Grant role-switching rights to authenticator
GRANT anon              TO authenticator;
GRANT authenticated     TO authenticator;
GRANT service_role      TO authenticator;
GRANT supabase_admin    TO authenticator;

-- ------------------------------------------------------------------------------
-- 3. Create auth schema (GoTrue owns this — it runs its own migrations)
--    We pre-create the schema so GoTrue can write to it immediately.
-- ------------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION supabase_auth_admin;
GRANT USAGE  ON SCHEMA auth TO supabase_admin, authenticator, anon, authenticated, service_role, dashboard_user;
GRANT ALL    ON SCHEMA auth TO supabase_admin;

-- ------------------------------------------------------------------------------
-- 4. Create storage schema
-- ------------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS storage;
GRANT USAGE  ON SCHEMA storage TO anon, authenticated, service_role;
GRANT ALL    ON SCHEMA storage TO supabase_admin;

-- ------------------------------------------------------------------------------
-- 5. Grant permissions on public schema
-- ------------------------------------------------------------------------------
GRANT USAGE  ON SCHEMA public TO anon, authenticated, service_role, supabase_admin;
GRANT ALL    ON SCHEMA public TO postgres, supabase_admin;

-- Allow these roles to select from tables in public (RLS handles row-level access)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated, anon, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO authenticated, anon, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT EXECUTE ON FUNCTIONS TO authenticated, anon, service_role;

-- ------------------------------------------------------------------------------
-- 6. Helper: auth.uid() function (used in RLS policies — Supabase standard)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql STABLE
AS $$
  SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb->>'sub', '')::uuid;
$$;

-- auth.role() helper
CREATE OR REPLACE FUNCTION auth.role()
RETURNS text
LANGUAGE sql STABLE
AS $$
  SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb->>'role', '')::text;
$$;

-- auth.email() helper
CREATE OR REPLACE FUNCTION auth.email()
RETURNS text
LANGUAGE sql STABLE
AS $$
  SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb->>'email', '')::text;
$$;

-- ------------------------------------------------------------------------------
-- 7. Notify completion
-- ------------------------------------------------------------------------------
DO $$ BEGIN
  RAISE NOTICE '=== Supabase compatibility roles and schemas initialized successfully ===';
END $$;
