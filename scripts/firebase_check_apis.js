/**
 * Try enabling Android Device Verification API via Service Management API
 * and also check if it's already available via serviceusage
 */
const crypto = require('crypto');
const https = require('https');
const fs = require('fs');
const path = require('path');

const SA_KEY = JSON.parse(fs.readFileSync(
  path.join(__dirname, '..', 'api', 'storage', 'app', 'firebase-credentials.json'), 'utf8'
));

const PROJECT_ID = 'dr-pharma-6027d';
const PROJECT_NUMBER = '549879846840';

function base64url(buf) {
  return buf.toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function createJWT(scopes) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: SA_KEY.client_email,
    scope: scopes.join(' '),
    aud: SA_KEY.token_uri,
    iat: now,
    exp: now + 3600,
  };
  const segments = [
    base64url(Buffer.from(JSON.stringify(header))),
    base64url(Buffer.from(JSON.stringify(payload))),
  ];
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(segments.join('.'));
  segments.push(base64url(sign.sign(SA_KEY.private_key)));
  return segments.join('.');
}

function getAccessToken() {
  return new Promise((resolve, reject) => {
    const jwt = createJWT([
      'https://www.googleapis.com/auth/firebase',
      'https://www.googleapis.com/auth/cloud-platform',
      'https://www.googleapis.com/auth/service.management',
    ]);
    const body = `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`;
    const req = https.request('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    }, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.access_token) resolve(parsed.access_token);
          else reject(new Error('No access_token: ' + data));
        } catch (e) { reject(e); }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function apiCall(method, url, token, body) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const opts = {
      method,
      hostname: u.hostname,
      path: u.pathname + u.search,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    };
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, data: JSON.parse(data) }); }
        catch (e) { resolve({ status: res.statusCode, data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function main() {
  console.log('🔐 Getting access token...');
  const token = await getAccessToken();

  // 1. List all enabled services to see what's available
  console.log('\n📋 Checking currently enabled services...');
  const listRes = await apiCall('GET',
    `https://serviceusage.googleapis.com/v1/projects/${PROJECT_ID}/services?filter=state:ENABLED&pageSize=200`,
    token
  );

  if (listRes.status === 200 && listRes.data.services) {
    const relevant = listRes.data.services.filter(s =>
      s.config?.name?.includes('android') ||
      s.config?.name?.includes('play') ||
      s.config?.name?.includes('firebase') ||
      s.config?.name?.includes('identity') ||
      s.config?.name?.includes('token') ||
      s.config?.name?.includes('safetynet')
    );
    console.log('\nRelevant enabled services:');
    relevant.forEach(s => console.log(`  ✅ ${s.config.name} - ${s.config.title}`));

    // Check specifically for androidcheck
    const allNames = listRes.data.services.map(s => s.config?.name);
    console.log('\nAll enabled services count:', allNames.length);

    if (allNames.includes('androidcheck.googleapis.com')) {
      console.log('\n🎉 androidcheck.googleapis.com IS ALREADY ENABLED!');
    } else {
      console.log('\n⚠️  androidcheck.googleapis.com is NOT enabled');
    }
    if (allNames.includes('playintegrity.googleapis.com')) {
      console.log('🎉 playintegrity.googleapis.com IS ALREADY ENABLED!');
    }
  } else {
    console.log('List response:', listRes.status, JSON.stringify(listRes.data, null, 2));
  }

  // 2. Try enabling via project number instead of project ID
  console.log('\n🌐 Trying to enable androidcheck via project NUMBER...');
  const enableRes = await apiCall('POST',
    `https://serviceusage.googleapis.com/v1/projects/${PROJECT_NUMBER}/services/androidcheck.googleapis.com:enable`,
    token, {}
  );
  console.log('Result:', enableRes.status, JSON.stringify(enableRes.data, null, 2));

  // 3. Try via Service Management API (different from Service Usage)
  console.log('\n🌐 Trying via Service Management API...');
  const mgmtRes = await apiCall('POST',
    `https://servicemanagement.googleapis.com/v1/services/androidcheck.googleapis.com:enable`,
    token,
    { consumerId: `project:${PROJECT_ID}` }
  );
  console.log('Result:', mgmtRes.status, JSON.stringify(mgmtRes.data, null, 2));

  // 4. Check the service state
  console.log('\n📋 Checking androidcheck service state...');
  const stateRes = await apiCall('GET',
    `https://serviceusage.googleapis.com/v1/projects/${PROJECT_ID}/services/androidcheck.googleapis.com`,
    token
  );
  console.log('State:', stateRes.status, JSON.stringify(stateRes.data, null, 2));

  // 5. Test Firebase Phone Auth directly
  console.log('\n📱 Testing Firebase Phone Auth...');
  const phoneRes = await apiCall('POST',
    `https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=AIzaSyBuhUz0-qs06sQ1xty-Awzh6kjLplqf_sI`,
    null,
    { phoneNumber: '+2250777019185' }
  );
  console.log('Phone auth result:', phoneRes.status, JSON.stringify(phoneRes.data, null, 2));
}

main().catch(err => {
  console.error('💥 Error:', err.message);
  process.exit(1);
});
