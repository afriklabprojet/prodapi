const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/identitytoolkit']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';

  // Check Identity Platform / Auth config
  console.log('=== Checking Auth Providers ===');

  // Get project config via Identity Toolkit
  const configUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;
  const configRes = await fetch(configUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const config = await configRes.json();
  console.log('Auth Config:', JSON.stringify(config, null, 2));

  // List sign-in providers
  const providersUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/defaultSupportedIdpConfigs`;
  const providersRes = await fetch(providersUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const providers = await providersRes.json();
  console.log('\nSign-in Providers:', JSON.stringify(providers, null, 2));

  // Check if phone auth is enabled specifically  
  const phoneUrl = `https://identitytoolkit.googleapis.com/v2/projects/${projectId}/config`;
  const phoneRes = await fetch(phoneUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const phoneConfig = await phoneRes.json();
  console.log('\nProject Config v2:', JSON.stringify(phoneConfig, null, 2));
}
main().catch(console.error);
