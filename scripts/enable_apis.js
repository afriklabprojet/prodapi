const { google } = require('googleapis');
const path = require('path');
const keyFile = path.join(__dirname, '..', 'api', 'storage', 'app', 'firebase-credentials.json');

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: keyFile,
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });
  const client = await auth.getClient();
  console.log('Auth OK');

  const su = google.serviceusage({ version: 'v1', auth: client });

  const apis = [
    'androidcheck.googleapis.com',
    'playintegrity.googleapis.com',
  ];

  for (const api of apis) {
    // Use project number
    const name = 'projects/549879846840/services/' + api;

    try {
      const res = await su.services.get({ name: name });
      console.log(api + ' state: ' + res.data.state);
    } catch (e) {
      console.log(api + ' check error: ' + (e.code || 'unknown') + ' - ' + (e.message || '').substring(0, 150));
    }

    try {
      const res = await su.services.enable({ name: name });
      console.log(api + ' -> ENABLED OK (op: ' + (res.data.name || 'done') + ')');
    } catch (e) {
      console.log(api + ' -> enable error: ' + (e.code || 'unknown') + ' - ' + (e.message || '').substring(0, 150));
    }
  }

  console.log('DONE');
}

main().catch(function (e) { console.error('FATAL: ' + e.message); });
