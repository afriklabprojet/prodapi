const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();

  // Test Android Device Verification API with API key
  const apiKey = 'AIzaSyBuhUz0-qs06sQ1xty-Awzh6kjLplqf_sI';
  const res = await fetch(
    `https://www.googleapis.com/androidcheck/v1/attestations/verify?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ signedAttestation: 'test' })
    }
  );
  const data = await res.json();
  console.log('Response:', JSON.stringify(data, null, 2));

  if (data.error && data.error.message && data.error.message.includes('not enabled')) {
    console.log('\nSTATUS: Android Device Verification API NOT ENABLED');
    console.log('Enable it here: https://console.cloud.google.com/apis/library/androidcheck.googleapis.com?project=dr-pharma-6027d');
  } else {
    console.log('\nSTATUS: Android Device Verification API IS ENABLED');
  }

  // Also try enabling via service account (in case role was granted)
  console.log('\n--- Trying to enable androidcheck via service account ---');
  const enableRes = await fetch(
    'https://serviceusage.googleapis.com/v1/projects/dr-pharma-6027d/services/androidcheck.googleapis.com:enable',
    {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
    }
  );
  const enableData = await enableRes.json();
  if (enableData.error) {
    console.log('Could not enable via SA:', enableData.error.message.substring(0, 80));
  } else {
    console.log('Enabled successfully:', JSON.stringify(enableData));
  }
}
main().catch(console.error);
