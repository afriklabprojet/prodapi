const { google } = require('googleapis');
const creds = require('../api/storage/app/firebase-credentials.json');

async function enableVisionAPI() {
  const auth = new google.auth.GoogleAuth({
    credentials: creds,
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });

  const serviceUsage = google.serviceusage({ version: 'v1', auth });

  try {
    // Check if Vision API is enabled
    const res = await serviceUsage.services.get({
      name: 'projects/dr-pharma-6027d/services/vision.googleapis.com'
    });
    console.log('Vision API status:', res.data.state);

    if (res.data.state !== 'ENABLED') {
      console.log('Enabling Vision API...');
      await serviceUsage.services.enable({
        name: 'projects/dr-pharma-6027d/services/vision.googleapis.com'
      });
      console.log('✅ Vision API enabled!');
    } else {
      console.log('✅ Vision API is already enabled');
    }
  } catch (e) {
    if (e.code === 403 || e.message.includes('permission')) {
      console.log('❌ Service account lacks permission to enable APIs');
      console.log('Please enable manually: https://console.cloud.google.com/apis/library/vision.googleapis.com?project=dr-pharma-6027d');
    } else {
      console.log('Error:', e.message);
    }
  }
}

enableVisionAPI();
