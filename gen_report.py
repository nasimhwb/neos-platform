import json
import subprocess

with open('/tmp/prod_openapi.json', 'r') as f:
    prod_openapi = json.load(f)
prod_defs = prod_openapi.get('definitions', {})

def run_sql(sql):
    cmd = ['docker', 'exec', 'neos_postgres', 'psql', '-U', 'postgres', '-d', 'postgres', '-t', '-A', '-c', sql]
    res = subprocess.run(cmd, capture_output=True, text=True)
    return [l for l in res.stdout.strip().split('\n') if l]

def get_vps_data():
    tables_sql = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
    table_list = run_sql(tables_sql)
    
    cols_sql = "SELECT table_name, column_name, data_type, is_nullable FROM information_schema.columns WHERE table_schema = 'public';"
    cols_raw = run_sql(cols_sql)
    table_cols = {}
    for t in table_list:
        table_cols[t] = {}
    for line in cols_raw:
        parts = line.split('|')
        if len(parts) == 4:
            t, c, dt, nul = parts[0], parts[1], parts[2], parts[3]
            if t not in table_cols:
                table_cols[t] = {}
            table_cols[t][c] = {'data_type': dt, 'nullable': (nul == 'YES')}

    funcs_sql = "SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public';"
    funcs = run_sql(funcs_sql)
    
    trig_sql = "SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'public';"
    trigs = run_sql(trig_sql)
    
    rls_sql = "SELECT tablename, policyname, roles, cmd FROM pg_policies WHERE schemaname = 'public';"
    policies = run_sql(rls_sql)
    
    return {
        'columns': table_cols,
        'functions': funcs,
        'triggers': trigs,
        'policies': policies
    }

vps_data = get_vps_data()

prod_table_names = set(prod_defs.keys())
vps_table_names = set(vps_data['columns'].keys())

missing_in_vps = sorted(list(prod_table_names - vps_table_names))
extra_in_vps = sorted(list(vps_table_names - prod_table_names))
common_tables = sorted(list(prod_table_names & vps_table_names))

print('=== PRODUCTION VS VPS STAGING SCHEMA AUDIT ===')
print(f'Production Public Tables/Views: {len(prod_table_names)}')
print(f'VPS Staging Public Tables/Views: {len(vps_table_names)}')
print(f'Common Tables/Views: {len(common_tables)}')
print(f'Missing in VPS Staging: {len(missing_in_vps)}')
print(f'Extra in VPS Staging: {len(extra_in_vps)}')

modified = []
for t in common_tables:
    p_cols = set(prod_defs[t].get('properties', {}).keys())
    v_cols = set(vps_data['columns'][t].keys())
    m_cols = list(p_cols - v_cols)
    e_cols = list(v_cols - p_cols)
    if m_cols or e_cols:
        modified.append({'table': t, 'missing_cols': m_cols, 'extra_cols': e_cols})

print(f'Modified Tables (Column Differences): {len(modified)}')

print('\n--- DETAILED BREAKDOWN ---')
print('Missing in VPS Staging:', missing_in_vps)
print('Extra in VPS Staging:', extra_in_vps)
print('Modified Tables with column diffs:')
for m in modified:
    print(' ', m)

output = {
    'summary': {
        'prod_count': len(prod_table_names),
        'vps_count': len(vps_table_names),
        'common_count': len(common_tables),
        'missing_count': len(missing_in_vps),
        'extra_count': len(extra_in_vps),
        'modified_count': len(modified)
    },
    'missing_in_vps': missing_in_vps,
    'extra_in_vps': extra_in_vps,
    'modified_tables': modified,
    'vps_full_data': vps_data
}

with open('/tmp/schema_comparison.json', 'w') as f:
    json.dump(output, f, indent=2)

print('Audit report saved to /tmp/schema_comparison.json')
