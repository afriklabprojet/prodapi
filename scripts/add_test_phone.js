const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/identitytoolkit', 'https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';

  // Add test phone number to bypass reCAPTCHA during testing
  // This allows specific phone numbers to receive a fixed code without SMS
  const configUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;

  // First get current config
  const getRes = await fetch(configUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const config = await getRes.json();

  if (config.error) {
    console.log('Error getting config:', config.error.message);
    return;
  }

  // Update with test phone numbers
  const updateUrl = `${configUrl}?updateMask=signIn.phoneNumber.testPhoneNumbers`;
  const body = {
    signIn: {
      phoneNumber: {
        enabled: true,
        testPhoneNumbers: {
          '+2250777019185': '123456',
          '+2250700000000': '123456'
        }
      }
    }
  };

  console.log('Adding test phone numbers...');
  const updateRes = await fetch(updateUrl, {
    method: 'PATCH',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  const result = await updateRes.json();

  if (result.error) {
    console.log('Error:', result.error.message);
  } else {
    console.log('SUCCESS! Test phone numbers added.');
    const testNumbers = result.signIn?.phoneNumber?.testPhoneNumbers;
    if (testNumbers) {
      console.log('Test numbers:', JSON.stringify(testNumbers, null, 2));
    }
  }
}
main().catch(console.error);
