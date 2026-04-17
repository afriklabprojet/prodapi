const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/identitytoolkit', 'https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';
  const configUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;

  // 1. Disable toll fraud protection that blocks SMS on low reCAPTCHA scores
  console.log('=== Disabling SMS toll fraud protection ===');
  const updateUrl = `${configUrl}?updateMask=recaptchaConfig`;
  const body = {
    recaptchaConfig: {
      emailPasswordEnforcementState: 'OFF',
      phoneEnforcementState: 'OFF',
      useSmsTollFraudProtection: false,
      useSmsBotScore: false,
      tollFraudManagedRules: []
    }
  };

  const res = await fetch(updateUrl, {
    method: 'PATCH',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  const result = await res.json();

  if (result.error) {
    console.log('Error:', JSON.stringify(result.error, null, 2));
  } else {
    console.log('reCAPTCHA config updated:');
    console.log('  phoneEnforcementState:', result.recaptchaConfig?.phoneEnforcementState);
    console.log('  useSmsTollFraudProtection:', result.recaptchaConfig?.useSmsTollFraudProtection);
    console.log('  useSmsBotScore:', result.recaptchaConfig?.useSmsBotScore);
    console.log('  tollFraudManagedRules:', JSON.stringify(result.recaptchaConfig?.tollFraudManagedRules));
  }

  // 2. Also add drlpharma.com to authorized domains
  console.log('\n=== Adding drlpharma.com to authorized domains ===');
  const domainUrl = `${configUrl}?updateMask=authorizedDomains`;
  const domainBody = {
    authorizedDomains: [
      'localhost',
      'dr-pharma-6027d.firebaseapp.com',
      'dr-pharma-6027d.web.app',
      'drlpharma.com',
      'www.drlpharma.com'
    ]
  };

  const domainRes = await fetch(domainUrl, {
    method: 'PATCH',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(domainBody)
  });
  const domainResult = await domainRes.json();

  if (domainResult.error) {
    console.log('Error:', domainResult.error.message);
  } else {
    console.log('Authorized domains:', domainResult.authorizedDomains);
  }
}
main().catch(console.error);
