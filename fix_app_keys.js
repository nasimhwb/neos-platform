const fs = require('fs');
const path = require('path');

const validAnon = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzUxNTAwODAwLCJleHAiOjE5MDkyNjcyMDB9.w4OLwQ68oYkzZqzftTmKZPJx_fl8dDW4mLvMu0IkvQk';
const validService = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiaXNzIjoic3VwYWJhc2UiLCJpYXQiOjE3NTE1MDA4MDAsImV4cCI6MTkwOTI2NzIwMH0.Zr-j7DRo-CwKVpguG9MaR3q8LAX4mgchZRjllA49W40';

let count = 0;
function walk(dir) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    if (file === 'node_modules' || file === '.git') continue;
    const full = path.join(dir, file);
    const stat = fs.statSync(full);
    if (stat.isDirectory()) {
      walk(full);
    } else {
      try {
        let text = fs.readFileSync(full, 'utf8');
        let replaced = false;
        
        if (text.includes('local_jwt_anon_key')) {
          text = text.replaceAll('local_jwt_anon_key', validAnon);
          replaced = true;
        }
        if (text.includes('local_jwt_service_key')) {
          text = text.replaceAll('local_jwt_service_key', validService);
          replaced = true;
        }
        if (text.includes('epcbqpkosqucugfbmveo.supabase.co')) {
          text = text.replaceAll('epcbqpkosqucugfbmveo.supabase.co', 'supabase.neosfacility.com');
          replaced = true;
        }
        if (replaced) {
          fs.writeFileSync(full, text, 'utf8');
          count++;
        }
      } catch (e) {}
    }
  }
}

walk('/app');
console.log(`CLEANED KEYS AND PLACEHOLDERS IN ${count} FILES`);
