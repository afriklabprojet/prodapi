const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/identitytoolkit']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';

  // Check phone auth config
  const configUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;
  const res = await fetch(configUrl, { headers: { Authorization: `Bearer ${token}` } });
  const config = await res.json();

  console.log('=== PHONE AUTH CONFIG ===');
  console.log('Phone enabled:', config.signIn?.phoneNumber?.enabled);
  console.log('Test phone numbers:', JSON.stringify(config.signIn?.phoneNumber?.testPhoneNumbers || {}, null, 2));

  // Check quota
  const quotaUrl = `https://identitytoolkit.googleapis.com/v2/projects/${projectId}/config`;
  const qRes = await fetch(quotaUrl, { headers: { Authorization: `Bearer ${token}` } });
  const qConfig = await qRes.json();
  console.log('=== QUOTA CONFIG ===');
  console.log('Quota:', JSON.stringify(qConfig.quota || 'N/A', null, 2));

  // Check authorized domains
  console.log('=== AUTHORIZED DOMAINS ===');
  console.log(JSON.stringify(config.authorizedDomains || [], null, 2));

  // Check if Android app SHA is configured
  const appsUrl = `https://firebase.googleapis.com/v1beta1/projects/${projectId}/androidApps`;
  const appsRes = await fetch(appsUrl, { headers: { Authorization: `Bearer ${token}` } });
  const apps = await appsRes.json();
  console.log('=== ANDROID APPS ===');
  if (apps.apps) {
    for (const app of apps.apps) {
      console.log(`  ${app.displayName || 'N/A'} | Package: ${app.packageName} | AppId: ${app.appId}`);
      // Get SHA certs
      const shaUrl = `https://firebase.googleapis.com/v1beta1/${app.name}/sha`;
      const shaRes = await fetch(shaUrl, { headers: { Authorization: `Bearer ${token}` } });
      const shaData = await shaRes.json();
      if (shaData.certificates && shaData.certificates.length > 0) {
        shaData.certificates.forEach(c => console.log(`    SHA-${c.certType === 'SHA_256' ? '256' : '1'}: ${c.shaHash}`));
      } else {
        console.log('    ⚠️  AUCUN SHA enregistré !');
      }
    }
  } else {
    console.log('  Aucune app Android trouvée ou erreur:', JSON.stringify(apps));
  }
}

main().catch(e => console.error('Error:', e.message));
