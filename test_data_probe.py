import json, urllib.request

url = 'https://supabase.neosfacility.com/auth/v1/token?grant_type=password'
anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzUxNTAwODAwLCJleHAiOjE5MDkyNjcyMDB9.w4OLwQ68oYkzZqzftTmKZPJx_fl8dDW4mLvMu0IkvQk'

headers = {'apikey': anon_key, 'Content-Type': 'application/json'}
data = json.dumps({'email': 'tester@neosfacility.com', 'password': 'Neos1234!'}).encode('utf-8')
req = urllib.request.Request(url, data=data, headers=headers, method='POST')

user_token = None
try:
    with urllib.request.urlopen(req) as res:
        resp = json.loads(res.read().decode('utf-8'))
        user_token = resp['access_token']
        print('AUTH SUCCESS. Token length:', len(user_token))
except Exception as e:
    print('AUTH FAILED:', e)

endpoints = [
    '/rest/v1/tasks?select=*',
    '/rest/v1/employees?select=*',
    '/rest/v1/client_profiles?select=*',
    '/rest/v1/orders?select=*',
    '/rest/v1/attendance?select=*',
    '/rest/v1/notifications?select=*',
    '/rest/v1/billing_consultancy_ledger?select=*'
]

print('\n=== PROBING POSTGREST BUSINESS DATA ENDPOINTS ===')
for ep in endpoints:
    ep_url = 'https://supabase.neosfacility.com' + ep
    req_headers = {
        'apikey': anon_key,
        'Authorization': f'Bearer {user_token}',
        'Content-Type': 'application/json'
    }
    req_ep = urllib.request.Request(ep_url, headers=req_headers, method='GET')
    try:
        with urllib.request.urlopen(req_ep) as res:
            body = res.read().decode('utf-8')
            data = json.loads(body)
            print(f'{ep} -> HTTP {res.status} | Records count: {len(data) if isinstance(data, list) else "N/A"}')
    except Exception as e:
        print(f'{ep} -> ERROR: {e}')
        if hasattr(e, 'read'):
            print('  Response:', e.read().decode('utf-8'))
