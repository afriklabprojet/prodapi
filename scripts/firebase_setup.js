/**
 * Firebase Setup Script
 * 1. Add SHA fingerprints to the Android app
 * 2. Enable required APIs (Android Device Verification, Play Integrity)
 * 3. Download updated google-services.json
 */

const crypto = require('crypto');
const https = require('https');
const fs = require('fs');
const path = require('path');

// Service Account credentials
const SA_KEY = JSON.parse(fs.readFileSync(
  path.join(__dirname, '..', 'api', 'storage', 'app', 'firebase-credentials.json'), 'utf8'
));

const PROJECT_ID = 'dr-pharma-6027d';
const APP_ID = '1:549879846840:android:0f5cdc8af2efe91458614d'; // client app

// SHA fingerprints to add
const SHA_CERTS = [
  { shaHash: 'B3:0A:28:89:2B:A7:A9:57:20:35:48:18:19:02:B1:0E:89:A1:28:71', certType: 'SHA_1' },
  { shaHash: '2A:D8:78:C6:11:10:E2:34:3B:54:B9:4B:E6:9D:5C:61:6A:3F:F3:6A:31:55:20:4A:35:24:CB:08:72:95:EF:14', certType: 'SHA_256' },
  { shaHash: '4F:53:FF:CB:1D:9C:C2:2C:26:9A:E7:81:D5:8D:5A:25:BE:10:25:EA', certType: 'SHA_1' },
  { shaHash: '1D:CD:D2:5A:62:81:2F:E2:C6:61:54:AE:8C:C0:D4:D5:D1:0C:F7:A4:CA:D6:49:E0:80:DF:48:6B:3E:D2:C3:E1', certType: 'SHA_256' },
];

// ---- JWT Token Generation ----
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
  const signature = sign.sign(SA_KEY.private_key);
  segments.push(base64url(signature));
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

// ---- HTTP helpers ----
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
        catch (e) { resolve({ status: res.statusCode, data: data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

// ---- Step 1: List existing SHA certs ----
async function listShaCerts(token) {
  const url = `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps/${APP_ID}/sha`;
  const res = await apiCall('GET', url, token);
  console.log('\n📋 Existing SHA certificates:', JSON.stringify(res.data, null, 2));
  return res.data.certificates || [];
}

// ---- Step 2: Add SHA fingerprints ----
async function addShaCert(token, shaHash, certType) {
  const cleanHash = shaHash.replace(/:/g, '').toLowerCase();
  const url = `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps/${APP_ID}/sha`;
  const body = { shaHash: cleanHash, certType };
  const res = await apiCall('POST', url, token, body);
  if (res.status === 200 || res.status === 201) {
    console.log(`  ✅ Added ${certType}: ${shaHash}`);
  } else if (res.status === 409) {
    console.log(`  ℹ️  Already exists ${certType}: ${shaHash}`);
  } else {
    console.log(`  ❌ Failed ${certType}: ${shaHash} → ${res.status}`, JSON.stringify(res.data));
  }
  return res;
}

// ---- Step 3: Enable APIs ----
async function enableAPI(token, apiName) {
  const url = `https://serviceusage.googleapis.com/v1/projects/${PROJECT_ID}/services/${apiName}:enable`;
  const res = await apiCall('POST', url, token, {});
  if (res.status === 200) {
    console.log(`  ✅ API enabled: ${apiName}`);
  } else if (res.data?.error?.message?.includes('already enabled') || res.data?.error?.code === 409) {
    console.log(`  ℹ️  Already enabled: ${apiName}`);
  } else {
    console.log(`  ⚠️  API enable ${apiName}: ${res.status}`, JSON.stringify(res.data));
  }
  return res;
}

// ---- Step 4: Download google-services.json ----
async function downloadGoogleServicesJson(token) {
  const url = `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps/${APP_ID}/config`;
  const res = await apiCall('GET', url, token);
  if (res.status === 200 && res.data.configFileContents) {
    const content = Buffer.from(res.data.configFileContents, 'base64').toString('utf8');
    const outPath = path.join(__dirname, '..', 'mobile', 'client', 'android', 'app', 'google-services.json');
    fs.writeFileSync(outPath, content);
    console.log(`\n📥 google-services.json saved to: ${outPath}`);
    console.log('Content preview:', content.substring(0, 200) + '...');
    return content;
  } else {
    console.log('❌ Failed to download google-services.json:', res.status, JSON.stringify(res.data));
    return null;
  }
}

// ---- Main ----
async function main() {
  console.log('🔐 Getting access token...');
  const token = await getAccessToken();
  console.log('✅ Token obtained');

  // Step 1: List existing certs
  const existing = await listShaCerts(token);

  // Step 2: Add SHA certs
  console.log('\n🔑 Adding SHA fingerprints...');
  for (const cert of SHA_CERTS) {
    await addShaCert(token, cert.shaHash, cert.certType);
  }

  // Verify
  console.log('\n🔍 Verifying SHA certificates after addition...');
  await listShaCerts(token);

  // Step 3: Enable APIs
  console.log('\n🌐 Enabling required APIs...');
  await enableAPI(token, 'androidcheck.googleapis.com');
  await enableAPI(token, 'playintegrity.googleapis.com');

  // Step 4: Download google-services.json
  console.log('\n📥 Downloading updated google-services.json...');
  await downloadGoogleServicesJson(token);

  console.log('\n✅ All done!');
}

main().catch(err => {
  console.error('💥 Fatal error:', err.message);
  process.exit(1);
});
