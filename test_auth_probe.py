import json, urllib.request

url = 'https://supabase.neosfacility.com/auth/v1/token?grant_type=password'
anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzUxNTAwODAwLCJleHAiOjE5MDkyNjcyMDB9.w4OLwQ68oYkzZqzftTmKZPJx_fl8dDW4mLvMu0IkvQk'

headers = {
    'apikey': anon_key,
    'Authorization': f'Bearer {anon_key}',
    'Content-Type': 'application/json'
}

data = json.dumps({'email': 'tester@neosfacility.com', 'password': 'Neos1234!'}).encode('utf-8')
req = urllib.request.Request(url, data=data, headers=headers, method='POST')

try:
    with urllib.request.urlopen(req) as res:
        print('HTTP STATUS:', res.status)
        body = res.read().decode('utf-8')
        resp = json.loads(body)
        print('ACCESS TOKEN RETURNED:', 'access_token' in resp)
        print('TOKEN TYPE:', resp.get('token_type'))
        print('USER EMAIL:', resp.get('user', {}).get('email'))
except Exception as e:
    print('ERROR:', e)
    if hasattr(e, 'read'):
        print('ERROR BODY:', e.read().decode('utf-8'))
