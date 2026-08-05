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

-- ------------------------------------------------------------------------------
-- 9. RPC Function for Production Auth Synchronization
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_prod_auth_data(
    users_data jsonb,
    identities_data jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    u_rec jsonb;
    i_rec jsonb;
    synced_users_count integer := 0;
    synced_identities_count integer := 0;
    preserved_staging_count integer := 0;
BEGIN
    SELECT count(*) INTO preserved_staging_count
    FROM auth.users
    WHERE email IN ('recovery_test@neosfacility.com', 'testuser123@neosfacility.com', 'testuser@neosfacility.com');

    -- Synchronize Production auth.users
    FOR u_rec IN SELECT * FROM jsonb_array_elements(users_data)
    LOOP
        IF u_rec->>'email' NOT IN ('recovery_test@neosfacility.com', 'testuser123@neosfacility.com', 'testuser@neosfacility.com') THEN
            INSERT INTO auth.users (
                id,
                email,
                encrypted_password,
                phone,
                email_confirmed_at,
                phone_confirmed_at,
                confirmation_token,
                recovery_token,
                reauthentication_token,
                recovery_sent_at,
                confirmation_sent_at,
                email_change,
                email_change_token_new,
                email_change_token_current,
                email_change_sent_at,
                last_sign_in_at,
                banned_until,
                updated_at,
                created_at,
                raw_app_meta_data,
                raw_user_meta_data,
                aud,
                role
            ) VALUES (
                (u_rec->>'id')::uuid,
                u_rec->>'email',
                u_rec->>'encrypted_password',
                u_rec->>'phone',
                (u_rec->>'email_confirmed_at')::timestamptz,
                (u_rec->>'phone_confirmed_at')::timestamptz,
                u_rec->>'confirmation_token',
                u_rec->>'recovery_token',
                u_rec->>'reauthentication_token',
                (u_rec->>'recovery_sent_at')::timestamptz,
                (u_rec->>'confirmation_sent_at')::timestamptz,
                u_rec->>'email_change',
                u_rec->>'email_change_token_new',
                u_rec->>'email_change_token_current',
                (u_rec->>'email_change_sent_at')::timestamptz,
                (u_rec->>'last_sign_in_at')::timestamptz,
                (u_rec->>'banned_until')::timestamptz,
                COALESCE((u_rec->>'updated_at')::timestamptz, NOW()),
                COALESCE((u_rec->>'created_at')::timestamptz, NOW()),
                COALESCE(u_rec->'raw_app_meta_data', '{"provider":"email","providers":["email"]}'::jsonb),
                COALESCE(u_rec->'raw_user_meta_data', '{}'::jsonb),
                COALESCE(u_rec->>'aud', 'authenticated'),
                COALESCE(u_rec->>'role', 'authenticated')
            )
            ON CONFLICT (id) DO UPDATE SET
                email = EXCLUDED.email,
                encrypted_password = EXCLUDED.encrypted_password,
                phone = EXCLUDED.phone,
                email_confirmed_at = EXCLUDED.email_confirmed_at,
                phone_confirmed_at = EXCLUDED.phone_confirmed_at,
                confirmation_token = EXCLUDED.confirmation_token,
                recovery_token = EXCLUDED.recovery_token,
                reauthentication_token = EXCLUDED.reauthentication_token,
                recovery_sent_at = EXCLUDED.recovery_sent_at,
                confirmation_sent_at = EXCLUDED.confirmation_sent_at,
                email_change = EXCLUDED.email_change,
                email_change_token_new = EXCLUDED.email_change_token_new,
                email_change_token_current = EXCLUDED.email_change_token_current,
                email_change_sent_at = EXCLUDED.email_change_sent_at,
                last_sign_in_at = EXCLUDED.last_sign_in_at,
                banned_until = EXCLUDED.banned_until,
                updated_at = EXCLUDED.updated_at,
                raw_app_meta_data = EXCLUDED.raw_app_meta_data,
                raw_user_meta_data = EXCLUDED.raw_user_meta_data,
                aud = EXCLUDED.aud,
                role = EXCLUDED.role;

            synced_users_count := synced_users_count + 1;
        END IF;
    END LOOP;

    -- Synchronize Production auth.identities
    FOR i_rec IN SELECT * FROM jsonb_array_elements(identities_data)
    LOOP
        INSERT INTO auth.identities (
            id,
            user_id,
            identity_data,
            provider,
            last_sign_in_at,
            created_at,
            updated_at,
            email,
            provider_id
        ) VALUES (
            (i_rec->>'id')::uuid,
            (i_rec->>'user_id')::uuid,
            COALESCE(i_rec->'identity_data', '{}'::jsonb),
            COALESCE(i_rec->>'provider', 'email'),
            (i_rec->>'last_sign_in_at')::timestamptz,
            COALESCE((i_rec->>'created_at')::timestamptz, NOW()),
            COALESCE((i_rec->>'updated_at')::timestamptz, NOW()),
            i_rec->>'email',
            COALESCE(i_rec->>'provider_id', i_rec->>'user_id')
        )
        ON CONFLICT (provider, provider_id) DO UPDATE SET
            user_id = EXCLUDED.user_id,
            identity_data = EXCLUDED.identity_data,
            last_sign_in_at = EXCLUDED.last_sign_in_at,
            updated_at = EXCLUDED.updated_at,
            email = EXCLUDED.email;

        synced_identities_count := synced_identities_count + 1;
    END LOOP;

    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'synced_users', synced_users_count,
        'synced_identities', synced_identities_count,
        'preserved_staging_users', preserved_staging_count
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.sync_prod_auth_data TO service_role, postgres;

DO $$ BEGIN
  RAISE NOTICE '=== App schema migration completed successfully ===';
END $$;


