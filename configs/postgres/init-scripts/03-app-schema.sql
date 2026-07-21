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
-- 1b. profiles — Alias View pointing to client_profiles
--     Required by webapp queries (.from('profiles'))
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

-- Grant permissions on profiles view
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated, service_role, anon;

-- ------------------------------------------------------------------------------
-- 1c. tasks — Core task management table (accessed by Tasks page)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tasks (
  id                       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title                    TEXT        NOT NULL,
  notes                    TEXT,
  due_date                 TIMESTAMPTZ,
  due_date_reason          TEXT,
  assigned_to              UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  created_by               UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  starred                  BOOLEAN     NOT NULL DEFAULT false,
  completed                BOOLEAN     NOT NULL DEFAULT false,
  cancelled                BOOLEAN     NOT NULL DEFAULT false,
  order_id                 UUID,
  client_id                UUID,
  vendor_id                UUID,
  lead_id                  UUID,
  stage                    TEXT,
  amount                   NUMERIC(12, 2),
  completed_at             TIMESTAMPTZ,
  original_due_date        TIMESTAMPTZ,
  overdue_notified         BOOLEAN     NOT NULL DEFAULT false,
  last_overdue_reminded_at TIMESTAMPTZ,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by  ON public.tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_tasks_completed   ON public.tasks(completed);

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own tasks" ON public.tasks;
CREATE POLICY "Users can view own tasks"
  ON public.tasks FOR SELECT
  TO authenticated
  USING (auth.uid() = assigned_to OR auth.uid() = created_by OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Users can insert own tasks" ON public.tasks;
CREATE POLICY "Users can insert own tasks"
  ON public.tasks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by OR auth.uid() = assigned_to OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Users can update own tasks" ON public.tasks;
CREATE POLICY "Users can update own tasks"
  ON public.tasks FOR UPDATE
  TO authenticated
  USING (auth.uid() = assigned_to OR auth.uid() = created_by OR auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role full access on tasks" ON public.tasks;
CREATE POLICY "Service role full access on tasks"
  ON public.tasks FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- 1d. task_assignees — Multi-assignee support table
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.task_assignees (
  id          SERIAL      PRIMARY KEY,
  task_id     UUID        NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  profile_id  UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(task_id, profile_id)
);

ALTER TABLE public.task_assignees ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role full access on task_assignees" ON public.task_assignees;
CREATE POLICY "Service role full access on task_assignees"
  ON public.task_assignees FOR ALL TO service_role USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated read on task_assignees" ON public.task_assignees;
CREATE POLICY "Authenticated read on task_assignees"
  ON public.task_assignees FOR SELECT TO authenticated USING (true);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.tasks          TO authenticated, service_role, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.task_assignees TO authenticated, service_role, anon;

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

DO $$ BEGIN
  RAISE NOTICE '=== App schema migration completed successfully ===';
END $$;
