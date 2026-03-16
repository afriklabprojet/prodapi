const { google } = require('googleapis');
const path = require('path');

const keyFile = path.join(__dirname, '..', 'api', 'storage', 'app', 'firebase-credentials.json');
const key = require(keyFile);

async function main() {
  console.log('Service account:', key.client_email);
  console.log('Project:', key.project_id);

  const auth = new google.auth.GoogleAuth({
    keyFile: keyFile,
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });

  const authClient = await auth.getClient();
  const su = google.serviceusage({ version: 'v1', auth: authClient });
  const projectId = key.project_id;

  // APIs needed for Firebase Phone Auth
  const apis = [
    'androidcheck.googleapis.com',
    'playintegrity.googleapis.com',
    'identitytoolkit.googleapis.com',
    'firebaseappcheck.googleapis.com',
  ];

  for (const api of apis) {
    const name = `projects/${projectId}/services/${api}`;

    // Check state
    try {
      const res = await su.services.get({ name });
      console.log(`\n${api}: ${res.data.state}`);
    } catch (e) {
      console.log(`\n${api}: ERROR checking - ${e.code || e.message}`);
    }

    // Enable if needed
    try {
      const res = await su.services.enable({ name });
      console.log(`  -> Enable operation: ${res.data.name || 'done'}`);
    } catch (e) {
      const msg = e.errors?.[0]?.message || e.message || '';
      console.log(`  -> Enable error: ${e.code} - ${msg.substring(0, 150)}`);
    }
  }
}

main().catch(e => console.error('Fatal:', e.message));
