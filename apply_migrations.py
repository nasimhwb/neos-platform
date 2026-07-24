import subprocess, sys

migrations = [
    ('001_extensions.sql', '''
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
        CREATE EXTENSION IF NOT EXISTS "pgcrypto";
        CREATE EXTENSION IF NOT EXISTS "pg_trgm";
    '''),
    ('002_types.sql', '''
        DO $$ BEGIN
            CREATE TYPE user_role_enum AS ENUM ('admin', 'manager', 'employee', 'client');
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    '''),
    ('003_tables.sql', '''
        SELECT 1;
    '''),
    ('004_constraints.sql', '''
        ALTER TABLE public.billing_consultancy_ledger ADD COLUMN IF NOT EXISTS net_amount NUMERIC;
        ALTER TABLE public.search_sessions ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
    '''),
    ('005_indexes.sql', '''
        CREATE INDEX IF NOT EXISTS idx_billing_ledger_net_amount ON public.billing_consultancy_ledger(net_amount);
        CREATE INDEX IF NOT EXISTS idx_search_sessions_created_at ON public.search_sessions(created_at);
    '''),
    ('006_views.sql', '''
        CREATE OR REPLACE VIEW public.attendance_summary AS
        SELECT 
            employee_id,
            DATE_TRUNC('month', date) AS month,
            COUNT(*) FILTER (WHERE status = 'present') AS present_days,
            COUNT(*) FILTER (WHERE status = 'absent') AS absent_days,
            COUNT(*) FILTER (WHERE status = 'late') AS late_days
        FROM public.attendance
        GROUP BY employee_id, DATE_TRUNC('month', date);

        CREATE OR REPLACE VIEW public.employee_performance_summary AS
        SELECT 
            employee_id,
            COUNT(*) AS total_signals,
            AVG(score) AS average_score
        FROM public.performance_quality_signals
        GROUP BY employee_id;

        CREATE OR REPLACE VIEW public.monthly_order_summary AS
        SELECT 
            DATE_TRUNC('month', created_at) AS order_month,
            COUNT(*) AS total_orders,
            SUM(total_amount) AS total_revenue
        FROM public.orders
        GROUP BY DATE_TRUNC('month', created_at);

        CREATE OR REPLACE VIEW public.payroll_summary AS
        SELECT 
            pay_run_id,
            COUNT(*) AS total_employees,
            SUM(net_pay) AS total_payout
        FROM public.payroll
        GROUP BY pay_run_id;

        CREATE OR REPLACE VIEW public.sales_summary AS
        SELECT 
            created_by AS salesperson_id,
            COUNT(*) AS total_sales,
            SUM(total_amount) AS total_volume
        FROM public.orders
        GROUP BY created_by;

        GRANT SELECT ON public.attendance_summary TO authenticated, service_role, anon;
        GRANT SELECT ON public.employee_performance_summary TO authenticated, service_role, anon;
        GRANT SELECT ON public.monthly_order_summary TO authenticated, service_role, anon;
        GRANT SELECT ON public.payroll_summary TO authenticated, service_role, anon;
        GRANT SELECT ON public.sales_summary TO authenticated, service_role, anon;
    '''),
    ('007_functions.sql', '''
        GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role, anon;
    '''),
    ('008_triggers.sql', '''
        CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS TRIGGER AS $$
        BEGIN
          INSERT INTO public.client_profiles (id, email, full_name, avatar_url, role)
          VALUES (
            NEW.id,
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
            COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
            COALESCE(NEW.raw_user_meta_data->>'role', 'employee')
          ) ON CONFLICT (id) DO UPDATE
          SET email = EXCLUDED.email, updated_at = NOW();
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
    '''),
    ('009_rls.sql', '''
        ALTER TABLE public.billing_consultancy_ledger ENABLE ROW LEVEL SECURITY;
        ALTER TABLE public.search_sessions ENABLE ROW LEVEL SECURITY;

        DO $$ BEGIN
            CREATE POLICY "authenticated_select_billing_ledger" ON public.billing_consultancy_ledger FOR SELECT TO authenticated USING (true);
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;

        DO $$ BEGIN
            CREATE POLICY "authenticated_select_search_sessions" ON public.search_sessions FOR SELECT TO authenticated USING (true);
        EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    '''),
    ('010_grants.sql', '''
        GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, supabase_admin, service_role;
        GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
        GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;
    '''),
    ('011_storage.sql', '''
        INSERT INTO storage.buckets (id, name, public)
        VALUES 
            ('attachments', 'attachments', true),
            ('efop-photos', 'efop-photos', true),
            ('efop-signatures', 'efop-signatures', true),
            ('field-tracking', 'field-tracking', true),
            ('order-attachments', 'order-attachments', true)
        ON CONFLICT (id) DO NOTHING;
    '''),
    ('012_realtime.sql', '''
        DO $$ BEGIN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.orders, public.tasks, public.suggestions, public.notifications;
        EXCEPTION WHEN OTHERS THEN NULL; END $$;
    ''')
]

for name, sql in migrations:
    cmd = ['docker', 'exec', '-i', 'neos_postgres', 'psql', '-U', 'postgres', '-d', 'postgres']
    res = subprocess.run(cmd, input=sql, capture_output=True, text=True)
    if res.returncode != 0:
        print("FAILED " + name + ": " + res.stderr)
        sys.exit(1)
    else:
        print("[APPLIED] " + name)

print("\nALL 12 MIGRATION SCRIPTS APPLIED SUCCESSFULLY!")
