import threading, time, json, urllib.request, urllib.parse, subprocess, os

host = "https://supabase.neosfacility.com"
service_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJpYXQiOjE3NTE1MDA4MDAsImV4cCI6MTkwOTI2NzIwMH0.Zr-j7DRo-CwKVpguG9MaR3q8LAX4mgchZRjllA49W40"

headers = {
    'apikey': service_key,
    'Authorization': f'Bearer {service_key}',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal'
}

def exec_user_workflow(user_id):
    latencies = []
    errors = 0
    
    steps = [
        # 1. Login / Auth Health
        ('Login', f"{host}/auth/v1/health", 'GET', None),
        # 2. Load Dashboard
        ('Load Dashboard', f"{host}/rest/v1/orders?select=id,status,total_amount&limit=10", 'GET', None),
        # 3. Create Task
        ('Create Task', f"{host}/rest/v1/tasks", 'POST', {'title': f'Load Test Task User {user_id}'}),
        # 4. View Orders
        ('View Orders', f"{host}/rest/v1/orders?select=id,ticket_id,client_id,total_amount&limit=20", 'GET', None),
        # 5. Update Attendance
        ('Update Attendance', f"{host}/rest/v1/attendance", 'POST', {'date': '2026-07-23', 'status': 'present', 'employeeId': '41624960-705a-4c32-9330-407258e22a06'}),
        # 6. Upload Attachment
        ('Upload Attachment', f"{host}/rest/v1/attachments", 'POST', {'file_name': f'load_test_{user_id}.pdf', 'file_path': f'/test/path_{user_id}.pdf', 'bucket_id': 'attachments'}),
        # 7. Generate Report RPC
        ('Generate Report', f"{host}/rest/v1/rpc/get_user_order_counts", 'POST', {})
    ]
    
    for name, url, method, payload in steps:
        req_data = json.dumps(payload).encode('utf-8') if payload else None
        req = urllib.request.Request(url, data=req_data, headers=headers, method=method)
        start = time.time()
        try:
            with urllib.request.urlopen(req, timeout=10) as res:
                elapsed_ms = round((time.time() - start) * 1000, 2)
                latencies.append(elapsed_ms)
        except Exception as e:
            elapsed_ms = round((time.time() - start) * 1000, 2)
            latencies.append(elapsed_ms)
            code = getattr(e, 'code', 500)
            if code >= 400:
                errors += 1
            
    return latencies, errors

def capture_system_metrics():
    mem = subprocess.run("free -m | awk 'NR==2{print $3\"MB / \"$2\"MB\"}'", shell=True, capture_output=True, text=True).stdout.strip()
    cpu = subprocess.run("top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4\"%\"}'", shell=True, capture_output=True, text=True).stdout.strip()
    db_conns = subprocess.run("docker exec neos_postgres psql -U postgres -d postgres -t -A -c 'SELECT count(*) FROM pg_stat_activity;'", shell=True, capture_output=True, text=True).stdout.strip()
    docker_stats = subprocess.run("docker stats --no-stream --format '{{.Name}}: CPU {{.CPUPerc}} | MEM {{.MemUsage}}'", shell=True, capture_output=True, text=True).stdout.strip().split('\n')
    
    return {
        'cpu_usage': cpu,
        'ram_usage': mem,
        'db_connections': db_conns,
        'docker_stats': docker_stats[:5]
    }

load_test_results = {}

for num_users in [5, 10, 20, 30]:
    print(f"\n--- RUNNING LOAD TEST TIER: {num_users} CONCURRENT USERS ---")
    threads = []
    user_results = []
    
    start_tier = time.time()
    initial_metrics = capture_system_metrics()
    
    def worker(u_id):
        lats, errs = exec_user_workflow(u_id)
        user_results.append({'latencies': lats, 'errors': errs})
        
    for i in range(num_users):
        t = threading.Thread(target=worker, args=(i+1,))
        threads.append(t)
        t.start()
        
    for t in threads:
        t.join()
        
    tier_duration = round(time.time() - start_tier, 2)
    peak_metrics = capture_system_metrics()
    
    all_latencies = []
    total_errors = 0
    for r in user_results:
        all_latencies.extend(r['latencies'])
        total_errors += r['errors']
        
    all_latencies.sort()
    avg_lat = round(sum(all_latencies) / len(all_latencies), 2) if all_latencies else 0
    p50_lat = all_latencies[int(len(all_latencies) * 0.50)] if all_latencies else 0
    p95_lat = all_latencies[int(len(all_latencies) * 0.95)] if all_latencies else 0
    max_lat = max(all_latencies) if all_latencies else 0
    rps = round((num_users * 7) / tier_duration, 2)
    
    tier_summary = {
        'concurrent_users': num_users,
        'total_requests': num_users * 7,
        'total_errors': total_errors,
        'tier_duration_seconds': tier_duration,
        'requests_per_second': rps,
        'avg_latency_ms': avg_lat,
        'p50_latency_ms': p50_lat,
        'p95_latency_ms': p95_lat,
        'max_latency_ms': max_lat,
        'initial_metrics': initial_metrics,
        'peak_metrics': peak_metrics
    }
    
    load_test_results[f"{num_users}_users"] = tier_summary
    print(f"  Completed Tier {num_users} in {tier_duration}s | RPS: {rps} | Avg Latency: {avg_lat}ms | P95: {p95_lat}ms | Max: {max_lat}ms | Errors: {total_errors}")
    print(f"  CPU: {peak_metrics['cpu_usage']} | RAM: {peak_metrics['ram_usage']} | DB Conns: {peak_metrics['db_connections']}")

with open("/tmp/load_test_results.json", "w") as f:
    json.dump(load_test_results, f, indent=2)

print("\n=== LOAD TEST SUITE COMPLETE ===")
