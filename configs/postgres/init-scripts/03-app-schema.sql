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

-- ------------------------------------------------------------------------------
-- 7. Additional Application Core Tables & RPC Functions
-- ------------------------------------------------------------------------------

-- Suggestions table (for Suggestions Admin Workbench)
CREATE TABLE IF NOT EXISTS public.suggestions (
  id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID        REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id             UUID,
  title                 TEXT        NOT NULL,
  category              TEXT,
  user_suggestion       TEXT        NOT NULL,
  user_question         TEXT,
  suggested_workflow    TEXT,
  module                TEXT        DEFAULT 'General',
  priority              TEXT        DEFAULT 'medium',
  app_version           TEXT        DEFAULT '1.0.0',
  current_record        TEXT,
  current_permission    TEXT,
  current_workflow      TEXT,
  ai_suggested_solution TEXT,
  browser_info          TEXT,
  operating_system      TEXT,
  device_type           TEXT,
  current_url           TEXT,
  screen_resolution     TEXT,
  screenshot            TEXT,
  viewport_size         TEXT,
  device_pixel_ratio    NUMERIC,
  language              TEXT,
  timezone              TEXT,
  network_status        TEXT,
  status                TEXT        DEFAULT 'new',
  occurrence_count      INTEGER     DEFAULT 1,
  affected_users        UUID[],
  assigned_developer_id UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  estimated_effort      TEXT,
  github_issue          TEXT,
  release_version       TEXT,
  resolution_notes      TEXT,
  developer_notes       TEXT,
  latest_seen           TIMESTAMPTZ DEFAULT NOW(),
  submitted_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.suggestions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on suggestions" ON public.suggestions;
CREATE POLICY "Service role full access on suggestions" ON public.suggestions FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on suggestions" ON public.suggestions;
CREATE POLICY "Authenticated users access on suggestions" ON public.suggestions FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Error logs table (for Admin Error Workbench)
CREATE TABLE IF NOT EXISTS public.error_logs (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  page_url        TEXT,
  page_title      TEXT,
  error_message   TEXT        NOT NULL,
  error_stack     TEXT,
  user_id         UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  user_role       TEXT,
  browser         TEXT,
  timestamp       TIMESTAMPTZ DEFAULT NOW(),
  action_context  JSONB,
  record_id       TEXT,
  module          TEXT,
  severity        TEXT        DEFAULT 'medium',
  status          TEXT        DEFAULT 'open',
  ai_explanation  TEXT,
  ai_causes       JSONB,
  ai_fix_prompt   TEXT,
  ai_severity     TEXT,
  occurrences     INTEGER     DEFAULT 1,
  resolved_at     TIMESTAMPTZ,
  resolved_by     UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  resolution_note TEXT
);

ALTER TABLE public.error_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on error_logs" ON public.error_logs;
CREATE POLICY "Service role full access on error_logs" ON public.error_logs FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on error_logs" ON public.error_logs;
CREATE POLICY "Authenticated users access on error_logs" ON public.error_logs FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Employees table (for HR Directory & Dialogs)
CREATE TABLE IF NOT EXISTS public.employees (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id       TEXT        UNIQUE NOT NULL,
  full_name         TEXT        NOT NULL,
  email             TEXT,
  contact_no        TEXT,
  designation       TEXT,
  department        TEXT,
  manager_id        UUID,
  sister_company_id UUID,
  active_status     BOOLEAN     DEFAULT true,
  employment_status TEXT        DEFAULT 'Active',
  date_of_joining   DATE,
  date_of_leaving   DATE,
  image_url         TEXT,
  custom_fields     JSONB       DEFAULT '{}'::jsonb,
  created_by_id     UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW(),
  deleted_at        TIMESTAMPTZ
);

ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on employees" ON public.employees;
CREATE POLICY "Service role full access on employees" ON public.employees FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on employees" ON public.employees;
CREATE POLICY "Authenticated users access on employees" ON public.employees FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Employee Salaries table
CREATE TABLE IF NOT EXISTS public.employee_salaries (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id    TEXT        NOT NULL,
  base_salary    NUMERIC(12,2),
  allowances     NUMERIC(12,2),
  deductions     NUMERIC(12,2),
  effective_date DATE,
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.employee_salaries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on employee_salaries" ON public.employee_salaries;
CREATE POLICY "Service role full access on employee_salaries" ON public.employee_salaries FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on employee_salaries" ON public.employee_salaries;
CREATE POLICY "Authenticated users access on employee_salaries" ON public.employee_salaries FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Attachments table
CREATE TABLE IF NOT EXISTS public.attachments (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT        NOT NULL,
  entity_id   UUID        NOT NULL,
  file_name   TEXT        NOT NULL,
  file_url    TEXT        NOT NULL,
  file_type   TEXT,
  file_size   BIGINT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on attachments" ON public.attachments;
CREATE POLICY "Service role full access on attachments" ON public.attachments FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on attachments" ON public.attachments;
CREATE POLICY "Authenticated users access on attachments" ON public.attachments FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Config parameters table
CREATE TABLE IF NOT EXISTS public.config_parameters (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key   TEXT        UNIQUE NOT NULL,
  config_value TEXT        NOT NULL,
  is_draft     BOOLEAN     DEFAULT false,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.config_parameters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on config_parameters" ON public.config_parameters;
CREATE POLICY "Service role full access on config_parameters" ON public.config_parameters FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on config_parameters" ON public.config_parameters;
CREATE POLICY "Authenticated users access on config_parameters" ON public.config_parameters FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Sister companies table
CREATE TABLE IF NOT EXISTS public.sister_companies (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT        UNIQUE NOT NULL,
  code       TEXT,
  is_active  BOOLEAN     DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.sister_companies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on sister_companies" ON public.sister_companies;
CREATE POLICY "Service role full access on sister_companies" ON public.sister_companies FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on sister_companies" ON public.sister_companies;
CREATE POLICY "Authenticated users access on sister_companies" ON public.sister_companies FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Locations table
CREATE TABLE IF NOT EXISTS public.locations (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT        NOT NULL,
  location_type TEXT        DEFAULT 'office',
  address       TEXT,
  latitude      NUMERIC(10,8),
  longitude     NUMERIC(11,8),
  radius_meters INTEGER     DEFAULT 1000,
  is_active     BOOLEAN     DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on locations" ON public.locations;
CREATE POLICY "Service role full access on locations" ON public.locations FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on locations" ON public.locations;
CREATE POLICY "Authenticated users access on locations" ON public.locations FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Employee location mappings table
CREATE TABLE IF NOT EXISTS public.employee_location_mappings (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID        NOT NULL,
  location_id UUID        NOT NULL REFERENCES public.locations(id) ON DELETE CASCADE,
  is_primary  BOOLEAN     DEFAULT false,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.employee_location_mappings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on employee_location_mappings" ON public.employee_location_mappings;
CREATE POLICY "Service role full access on employee_location_mappings" ON public.employee_location_mappings FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on employee_location_mappings" ON public.employee_location_mappings;
CREATE POLICY "Authenticated users access on employee_location_mappings" ON public.employee_location_mappings FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Role permissions table
CREATE TABLE IF NOT EXISTS public.role_permissions (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  role       TEXT        NOT NULL,
  module     TEXT        NOT NULL,
  action     TEXT        NOT NULL,
  allowed    BOOLEAN     DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on role_permissions" ON public.role_permissions;
CREATE POLICY "Service role full access on role_permissions" ON public.role_permissions FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on role_permissions" ON public.role_permissions;
CREATE POLICY "Authenticated users access on role_permissions" ON public.role_permissions FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Audit logs table
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type  TEXT,
  entity_id    TEXT,
  action       TEXT        NOT NULL,
  description  TEXT,
  user_id      UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  performed_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on audit_logs" ON public.audit_logs;
CREATE POLICY "Service role full access on audit_logs" ON public.audit_logs FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on audit_logs" ON public.audit_logs;
CREATE POLICY "Authenticated users access on audit_logs" ON public.audit_logs FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Activity logs table
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  module            TEXT        NOT NULL,
  entity_id         UUID,
  action            TEXT        NOT NULL,
  remarks           TEXT,
  sister_company_id UUID,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on activity_logs" ON public.activity_logs;
CREATE POLICY "Service role full access on activity_logs" ON public.activity_logs FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on activity_logs" ON public.activity_logs;
CREATE POLICY "Authenticated users access on activity_logs" ON public.activity_logs FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Orders table (stub for order counting)
CREATE TABLE IF NOT EXISTS public.orders (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role full access on orders" ON public.orders;
CREATE POLICY "Service role full access on orders" ON public.orders FOR ALL TO service_role USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated users access on orders" ON public.orders;
CREATE POLICY "Authenticated users access on orders" ON public.orders FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- RPC Function: get_user_order_counts()
CREATE OR REPLACE FUNCTION public.get_user_order_counts()
RETURNS TABLE (
  user_id UUID,
  order_count BIGINT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'orders') THEN
    RETURN QUERY SELECT o.created_by AS user_id, COUNT(*)::BIGINT AS order_count FROM public.orders o GROUP BY o.created_by;
  ELSE
    RETURN;
  END IF;
END;
$$;

-- Global Schema Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role, anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role, anon;

DO $$ BEGIN
  RAISE NOTICE '=== App schema migration completed successfully ===';
END $$;
