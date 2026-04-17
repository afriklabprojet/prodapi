const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/identitytoolkit', 'https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';
  const configUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;

  // Remove test phone numbers (set empty object)
  const updateUrl = `${configUrl}?updateMask=signIn.phoneNumber.testPhoneNumbers`;
  const body = {
    signIn: {
      phoneNumber: {
        enabled: true,
        testPhoneNumbers: {}
      }
    }
  };

  console.log('Removing test phone numbers...');
  const res = await fetch(updateUrl, {
    method: 'PATCH',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  const result = await res.json();

  if (result.error) {
    console.log('Error:', result.error.message);
  } else {
    console.log('Done. Test numbers:', JSON.stringify(result.signIn?.phoneNumber?.testPhoneNumbers || {}));
  }

  // Check authorized domains
  console.log('\nAuthorized domains:', result.authorizedDomains);

  // Check reCAPTCHA config
  console.log('\nreCAPTCHA config:', JSON.stringify(result.recaptchaConfig, null, 2));
}
main().catch(console.error);
