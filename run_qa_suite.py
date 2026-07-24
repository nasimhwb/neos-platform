import json, time, urllib.request, urllib.parse, subprocess

host = "https://supabase.neosfacility.com"
anon_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzUxNTAwODAwLCJleHAiOjE5MDkyNzcyMDB9.w4OLwQ68oYkzZqzftTmKZPJx_fl8dDW4mLvMu0IkvQk"
service_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJpYXQiOjE3NTE1MDA4MDAsImV4cCI6MTkwOTI2NzIwMH0.Zr-j7DRo-CwKVpguG9MaR3q8LAX4mgchZRjllA49W40"

results = {
    'phase1_auth': {},
    'phase2_modules': {},
    'phase3_crud': {},
    'phase4_roles': {},
    'phase5_storage': {},
    'phase6_realtime': {},
    'phase7_performance': {}
}

def test_api(url, method='GET', payload=None, headers=None):
    if headers is None:
        headers = {'apikey': anon_key, 'Authorization': f'Bearer {anon_key}'}
    
    req_data = json.dumps(payload).encode('utf-8') if payload else None
    req = urllib.request.Request(url, data=req_data, headers=headers, method=method)
    
    start = time.time()
    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            elapsed_ms = round((time.time() - start) * 1000, 2)
            body = res.read().decode('utf-8')
            return {'status': res.status, 'latency_ms': elapsed_ms, 'body_length': len(body), 'data': json.loads(body) if body.startswith(('[', '{')) else body, 'error': None}
    except Exception as e:
        elapsed_ms = round((time.time() - start) * 1000, 2)
        code = getattr(e, 'code', 500)
        return {'status': code, 'latency_ms': elapsed_ms, 'body_length': 0, 'data': None, 'error': str(e)}

print("=== STARTING QA VERIFICATION SUITE ===")

# Phase 1 — User Journey & Auth Endpoints
print("\n--- PHASE 1: Auth Endpoints ---")
results['phase1_auth']['gotrue_health'] = test_api(f"{host}/auth/v1/health")
results['phase1_auth']['recover'] = test_api(f"{host}/auth/v1/recover", method='POST', payload={'email': 'fatma@neosfacility.com'})
results['phase1_auth']['otp'] = test_api(f"{host}/auth/v1/otp", method='POST', payload={'email': 'najirhossain1308@gmail.com', 'create_user': False})

# Phase 2 & 3 — Module & CRUD Endpoints
print("\n--- PHASE 2 & 3: Module & CRUD Validation ---")
modules = [
    ('Dashboard/Orders', f"{host}/rest/v1/orders?select=id,status,total_amount&limit=10"),
    ('Users/Profiles', f"{host}/rest/v1/profiles?select=id,email,full_name,role&limit=10"),
    ('Employees', f"{host}/rest/v1/employees?select=id,full_name,active_status&limit=10"),
    ('Attendance', f"{host}/rest/v1/attendance?select=id,date,status&limit=10"),
    ('Tasks', f"{host}/rest/v1/tasks?select=id,title,completed&limit=10"),
    ('Suggestions', f"{host}/rest/v1/suggestions?select=id,title,status&limit=10"),
    ('Notifications', f"{host}/rest/v1/notifications?select=id,title,is_read&limit=10"),
    ('Locations', f"{host}/rest/v1/locations?select=id,name&limit=10"),
    ('Sister Companies', f"{host}/rest/v1/sister_companies?select=id,name&limit=10"),
    ('Activity Logs', f"{host}/rest/v1/activity_logs?select=id,log_type&limit=10"),
    ('Error Logs', f"{host}/rest/v1/error_logs?select=id,error_message&limit=10"),
    ('Config Parameters', f"{host}/rest/v1/config_parameters?select=config_key,config_value&limit=10"),
    ('RPC get_user_order_counts', f"{host}/rest/v1/rpc/get_user_order_counts", 'POST', {}),
    ('RPC calculate_haversine_distance', f"{host}/rest/v1/rpc/calculate_haversine_distance", 'POST', {'lat1': 28.6, 'lon1': 77.2, 'lat2': 28.61, 'lon2': 77.21})
]

for item in modules:
    name = item[0]
    url = item[1]
    method = item[2] if len(item) > 2 else 'GET'
    payload = item[3] if len(item) > 3 else None
    
    headers = {'apikey': service_key, 'Authorization': f'Bearer {service_key}', 'Content-Type': 'application/json'}
    res = test_api(url, method=method, payload=payload, headers=headers)
    results['phase2_modules'][name] = res
    count = len(res['data']) if isinstance(res['data'], list) else 'RPC'
    print(f"  [MODULE] {name:35s} -> Status: {res['status']}, Count: {count}, Latency: {res['latency_ms']}ms")

# Phase 5 — Storage Buckets
print("\n--- PHASE 5: Storage Validation ---")
buckets = ['attachments', 'efop-photos', 'efop-signatures', 'field-tracking', 'order-attachments']
for b in buckets:
    url = f"{host}/storage/v1/bucket"
    headers = {'apikey': service_key, 'Authorization': f'Bearer {service_key}'}
    res = test_api(url, method='GET', headers=headers)
    results['phase5_storage'][b] = res
    print(f"  [STORAGE BUCKET LIST] {b:25s} -> Status: {res['status']}, Latency: {res['latency_ms']}ms")

# Phase 6 — Realtime
print("\n--- PHASE 6: Realtime Publication ---")
cmd = ["docker", "exec", "neos_postgres", "psql", "-U", "postgres", "-d", "postgres", "-t", "-A", "-c", "SELECT pubname, schemaname, tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime';"]
res_rt = subprocess.run(cmd, capture_output=True, text=True)
rt_tables = [l for l in res_rt.stdout.strip().split('\n') if l]
results['phase6_realtime']['realtime_tables'] = rt_tables
print("  Realtime Published Tables:", rt_tables)

# Phase 7 — Performance Summary
print("\n--- PHASE 7: Performance Summary ---")
latencies = [v['latency_ms'] for v in results['phase2_modules'].values()]
avg_lat = round(sum(latencies) / len(latencies), 2)
max_lat = max(latencies)
results['phase7_performance'] = {
    'avg_api_latency_ms': avg_lat,
    'max_api_latency_ms': max_lat,
    'total_endpoints_tested': len(latencies)
}
print(f"  Average API Latency: {avg_lat}ms")
print(f"  Max API Latency:     {max_lat}ms")

with open(r"D:\WebApp\KVM2\qa_results.json", "w") as f:
    json.dump(results, f, indent=2)

print("\n=== QA VERIFICATION SUITE COMPLETE ===")
