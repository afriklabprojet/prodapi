const { google } = require('googleapis');
const key = require('../api/storage/app/firebase-credentials.json');

const jwtClient = new google.auth.JWT({
  email: key.client_email,
  key: key.private_key,
  scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

(async () => {
  await jwtClient.authorize();
  const su = google.serviceusage({ version: 'v1', auth: jwtClient });

  // Check current state
  try {
    const res = await su.services.get({ name: 'projects/dr-pharma-6027d/services/androidcheck.googleapis.com' });
    console.log('Android Device Verification API state:', res.data.state);
  } catch (e) {
    console.log('Check error:', e.code, e.errors?.[0]?.message || e.message?.substring(0, 200));
  }

  // Try to enable it
  try {
    console.log('Enabling Android Device Verification API...');
    const res = await su.services.enable({ name: 'projects/dr-pharma-6027d/services/androidcheck.googleapis.com' });
    console.log('Enable result:', JSON.stringify(res.data).substring(0, 500));
  } catch (e) {
    console.log('Enable error:', e.code, e.errors?.[0]?.message || e.message?.substring(0, 300));
  }

  // Also check and enable Play Integrity API (replacement for SafetyNet)
  try {
    const res = await su.services.get({ name: 'projects/dr-pharma-6027d/services/playintegrity.googleapis.com' });
    console.log('Play Integrity API state:', res.data.state);
  } catch (e) {
    console.log('Play Integrity check error:', e.code);
  }

  try {
    console.log('Enabling Play Integrity API...');
    const res = await su.services.enable({ name: 'projects/dr-pharma-6027d/services/playintegrity.googleapis.com' });
    console.log('Play Integrity enable result:', JSON.stringify(res.data).substring(0, 300));
  } catch (e) {
    console.log('Play Integrity enable error:', e.code, e.errors?.[0]?.message || e.message?.substring(0, 200));
  }
})();
