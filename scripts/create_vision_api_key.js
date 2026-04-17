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

  const apikeys = google.apikeys({ version: 'v2', auth: client });

  const parent = 'projects/549879846840/locations/global';

  try {
    // First, list existing keys
    const listRes = await apikeys.projects.locations.keys.list({ parent });
    console.log('Existing keys:', listRes.data.keys?.length || 0);

    // Try to create new key
    const res = await apikeys.projects.locations.keys.create({
      parent: parent,
      keyId: 'vision-ocr-key',
      requestBody: {
        displayName: 'Vision API Key for OCR',
        restrictions: {
          apiTargets: [
            { service: 'vision.googleapis.com' }
          ]
        }
      }
    });
    console.log('API Key creation started:', res.data.name);

    // Wait for operation to complete
    const opName = res.data.name;
    let done = false;
    let keyName = null;

    for (let i = 0; i < 10; i++) {
      await new Promise(resolve => setTimeout(resolve, 2000));
      const opRes = await apikeys.operations.get({ name: opName });
      if (opRes.data.done) {
        done = true;
        keyName = opRes.data.response.name;
        break;
      }
      console.log('Waiting...');
    }

    if (done && keyName) {
      const keyRes = await apikeys.projects.locations.keys.getKeyString({ name: keyName });
      console.log('\n========================================');
      console.log('VISION API KEY:', keyRes.data.keyString);
      console.log('========================================\n');
      console.log('Add this to your .env file:');
      console.log('GOOGLE_CLOUD_VISION_API_KEY=' + keyRes.data.keyString);
    } else {
      console.log('Operation not done yet');
    }
  } catch (e) {
    if (e.code === 409) {
      console.log('Key already exists, fetching...');
      // Try to fetch existing key
      try {
        const keyName = 'projects/549879846840/locations/global/keys/vision-ocr-key';
        const keyRes = await apikeys.projects.locations.keys.getKeyString({ name: keyName });
        console.log('\n========================================');
        console.log('VISION API KEY:', keyRes.data.keyString);
        console.log('========================================\n');
      } catch (e2) {
        console.log('Could not fetch key:', e2.message);
      }
    } else {
      console.log('Error:', e.code, e.message);
    }
  }
}

main().catch(e => console.error('FATAL:', e.message));
