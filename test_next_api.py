import json, urllib.request

url = 'https://supabase.neosfacility.com/auth/v1/token?grant_type=password'
anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzUxNTAwODAwLCJleHAiOjE5MDkyNjcyMDB9.w4OLwQ68oYkzZqzftTmKZPJx_fl8dDW4mLvMu0IkvQk'
headers = {'apikey': anon_key, 'Content-Type': 'application/json'}
data = json.dumps({'email': 'tester@neosfacility.com', 'password': 'Neos1234!'}).encode('utf-8')
req = urllib.request.Request(url, data=data, headers=headers, method='POST')

with urllib.request.urlopen(req) as res:
    resp = json.loads(res.read().decode('utf-8'))
    user_token = resp['access_token']
    user_id = resp['user']['id']

print('1. GOTRUE TOKEN OBTAINED:', user_token[:30] + '...')

# Register session in Next.js backend
reg_url = 'https://test.neosfacility.com/api/auth/register-session'
reg_req = urllib.request.Request(reg_url, data=json.dumps({
    'access_token': user_token,
    'user': {'id': user_id, 'email': 'tester@neosfacility.com'}
}).encode('utf-8'), headers={
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {user_token}'
}, method='POST')

session_id = None
try:
    with urllib.request.urlopen(reg_req) as res:
        print('2. REGISTER SESSION STATUS:', res.status)
        reg_resp = json.loads(res.read().decode('utf-8'))
        print('   REGISTER SESSION RESP:', reg_resp)
        session_id = reg_resp.get('session', {}).get('id')
except Exception as e:
    print('REGISTER SESSION ERROR:', e)
    if hasattr(e, 'read'):
        print('  Response:', e.read().decode('utf-8'))

if session_id:
    chk_url = 'https://test.neosfacility.com/api/auth/session-check'
    chk_req = urllib.request.Request(chk_url, headers={
        'Cookie': f'neos_session_id={session_id}',
        'x-neos-session-id': session_id
    })
    try:
        with urllib.request.urlopen(chk_req) as res:
            print('3. SESSION CHECK STATUS:', res.status)
            print('   SESSION CHECK RESP:', res.read().decode('utf-8'))
    except Exception as e:
        print('SESSION CHECK ERROR:', e)
        if hasattr(e, 'read'):
            print('  Response:', e.read().decode('utf-8'))
