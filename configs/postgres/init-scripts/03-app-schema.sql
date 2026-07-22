-- ==============================================================================
-- NEOS PLATFORM — APPLICATION SCHEMA MIGRATION
-- ==============================================================================
-- Creates the application-level tables in the postgres database.
-- These tables are accessed via PostgREST (rest/v1) from the webapp.
--
-- Run AFTER:
--   1. 02-supabase-compat.sql (roles created)
--   2. GoTrue has started and created the auth schema + auth.users table
--
-- To run on VPS:
--   docker exec -i neos_postgres psql -U postgres -d postgres < configs/postgres/init-scripts/03-app-schema.sql
-- ==============================================================================

\connect postgres

-- ------------------------------------------------------------------------------
-- 1. client_profiles — Core user profile table
--    id MUST match auth.users(id) — foreign key ensures referential integrity
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.client_profiles (
  id            UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT        UNIQUE,
  full_name     TEXT,
  avatar_url    TEXT,
  role          TEXT        NOT NULL DEFAULT 'user',
  company_name  TEXT,
  phone         TEXT,
  is_active     BOOLEAN     NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast lookup by email
CREATE INDEX IF NOT EXISTS idx_client_profiles_email ON public.client_profiles(email);

-- Enable RLS
ALTER TABLE public.client_profiles ENABLE ROW LEVEL SECURITY;

-- Drop policies if they exist (idempotent)
DROP POLICY IF EXISTS "Users can view own profile"   ON public.client_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.client_profiles;
DROP POLICY IF EXISTS "Service role full access"     ON public.client_profiles;

-- Policy: authenticated users can read their own profile
CREATE POLICY "Users can view own profile"
  ON public.client_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Policy: authenticated users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.client_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Policy: service_role has full access (used by server-side operations)
CREATE POLICY "Service role full access"
  ON public.client_profiles
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- 2. roles — Named roles table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.roles (
  id          SERIAL      PRIMARY KEY,
  name        TEXT        UNIQUE NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default roles (idempotent)
INSERT INTO public.roles (name, description) VALUES
  ('admin',    'Full system administrator'),
  ('manager',  'Team manager with elevated access'),
  ('user',     'Standard platform user'),
  ('viewer',   'Read-only access')
ON CONFLICT (name) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 3. user_roles — Many-to-many mapping of users to roles
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_roles (
  id          SERIAL      PRIMARY KEY,
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id     INTEGER     NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role full access" ON public.user_roles;
CREATE POLICY "Service role full access"
  ON public.user_roles FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view own roles" ON public.user_roles;
CREATE POLICY "Users can view own roles"
  ON public.user_roles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- ------------------------------------------------------------------------------
-- 4. updated_at trigger function
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON public.client_profiles;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.client_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ------------------------------------------------------------------------------
-- 5. Auto-create profile on new user signup
--    Trigger fires AFTER GoTrue inserts into auth.users
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.client_profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    ),
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ------------------------------------------------------------------------------
-- 6. Backfill: create profiles for any existing auth.users without a profile
-- ------------------------------------------------------------------------------
INSERT INTO public.client_profiles (id, email, full_name)
SELECT
  u.id,
  u.email,
  COALESCE(
    u.raw_user_meta_data->>'full_name',
    split_part(u.email, '@', 1)
  )
FROM auth.users u
WHERE u.id NOT IN (SELECT id FROM public.client_profiles)
ON CONFLICT (id) DO NOTHING;

-- Grant table access to PostgREST roles
GRANT SELECT, INSERT, UPDATE, DELETE ON public.client_profiles TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.roles           TO authenticated, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_roles      TO authenticated, service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;

-- ------------------------------------------------------------------------------
-- 7. Compatibility View: public.profiles (maps to public.client_profiles)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.profiles AS
SELECT 
  id,
  email,
  full_name,
  avatar_url,
  role,
  company_name,
  phone,
  is_active,
  created_at,
  updated_at
FROM public.client_profiles;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated, anon, service_role;

-- ------------------------------------------------------------------------------
-- 8. Backfill GoTrue Auth Metadata & Identities for Migrated Users
-- ------------------------------------------------------------------------------
-- Normalize auth.users default fields required by self-hosted GoTrue
UPDATE auth.users 
SET 
  instance_id = COALESCE(instance_id, '00000000-0000-0000-0000-000000000000'),
  aud = CASE WHEN aud IS NULL OR aud = '' THEN 'authenticated' ELSE aud END,
  role = CASE WHEN role IS NULL OR role = '' THEN 'authenticated' ELSE role END,
  email_confirmed_at = COALESCE(email_confirmed_at, created_at),
  raw_app_meta_data = COALESCE(raw_app_meta_data, '{"provider": "email", "providers": ["email"]}'::jsonb)
WHERE instance_id IS NULL OR aud IS NULL OR aud != 'authenticated' OR role IS NULL OR role != 'authenticated';

-- Ensure all users have a corresponding identity record in auth.identities
INSERT INTO auth.identities (id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, provider_id)
SELECT 
  id, 
  id AS user_id, 
  json_build_object('sub', id::text, 'email', email)::jsonb AS identity_data,
  'email' AS provider,
  NOW() AS last_sign_in_at,
  created_at,
  updated_at,
  id::text AS provider_id
FROM auth.users
ON CONFLICT (provider, provider_id) DO NOTHING;

DO $$ BEGIN
  RAISE NOTICE '=== App schema migration completed successfully ===';
END $$;

