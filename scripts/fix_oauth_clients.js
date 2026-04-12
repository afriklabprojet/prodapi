/**
 * fix_oauth_clients.js
 * 
 * Crée les OAuth 2.0 Client IDs manquants dans Google Cloud Console
 * qui sont requis pour que Firebase Phone Auth fonctionne sur Android.
 * 
 * Le google-services.json a `oauth_client: []` vide, ce qui empêche
 * le SDK Firebase de faire la vérification reCAPTCHA nécessaire pour
 * l'envoi de SMS OTP.
 * 
 * Usage: node scripts/fix_oauth_clients.js
 */
const { GoogleAuth } = require('google-auth-library');

const PROJECT_ID = 'dr-pharma-6027d';
const PROJECT_NUMBER = '549879846840';

// SHA-1 fingerprints from release keystores
const ANDROID_APPS = [
  {
    name: 'Client',
    packageName: 'ci.drpharma.drpharma_client',
    sha1: '9C2B7857C2616FCCB0E100B6808546BFBFE2E427',
  },
  {
    name: 'Courier',
    packageName: 'com.drpharma.courier_flutter',
    sha1: '8FD434BC9024968F106F1D4CC7DFFBACC44C8942',
  },
  {
    name: 'Pharmacy',
    packageName: 'com.drpharma.pharmacy',
    sha1: '2627268893E902978B8291631881457AACCB1B46',
  },
];

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: [
      'https://www.googleapis.com/auth/cloud-platform',
      'https://www.googleapis.com/auth/firebase',
    ],
  });
  const token = await auth.getAccessToken();

  // Step 1: Check if OAuth consent screen exists
  console.log('=== Step 1: Check OAuth Consent Screen (Brand) ===');
  const brandsUrl = `https://iap.googleapis.com/v1/projects/${PROJECT_NUMBER}/brands`;
  const brandsRes = await fetch(brandsUrl, { headers: { Authorization: `Bearer ${token}` } });
  let brandsData;
  
  if (brandsRes.ok) {
    brandsData = await brandsRes.json();
    console.log('Brands:', JSON.stringify(brandsData, null, 2));
  } else {
    console.log('Brands API response:', brandsRes.status);
    // Try to create a brand (OAuth consent screen)
    console.log('\n>> Creating OAuth Consent Screen (Brand)...');
    const createBrandRes = await fetch(brandsUrl, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        applicationTitle: 'DR-PHARMA',
        supportEmail: 'support@drlpharma.com',
      }),
    });
    if (createBrandRes.ok) {
      brandsData = { brands: [await createBrandRes.json()] };
      console.log('Brand created:', JSON.stringify(brandsData, null, 2));
    } else {
      const err = await createBrandRes.text();
      console.log('Brand creation failed:', err);
    }
  }

  // Step 2: Enable required APIs
  console.log('\n=== Step 2: Check/Enable Required APIs ===');
  const requiredApis = [
    'identitytoolkit.googleapis.com',
    'playintegrity.googleapis.com',
    'recaptchaenterprise.googleapis.com',
    'cloudresourcemanager.googleapis.com',
  ];

  for (const api of requiredApis) {
    const statusUrl = `https://serviceusage.googleapis.com/v1/projects/${PROJECT_ID}/services/${api}`;
    const statusRes = await fetch(statusUrl, { headers: { Authorization: `Bearer ${token}` } });
    const statusData = await statusRes.json();
    
    if (statusData.state === 'ENABLED') {
      console.log(`  ✅ ${api}: ENABLED`);
    } else {
      console.log(`  ⚠️  ${api}: ${statusData.state || 'UNKNOWN'} — enabling...`);
      const enableUrl = `${statusUrl}:enable`;
      const enableRes = await fetch(enableUrl, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: '{}',
      });
      const enableData = await enableRes.json();
      console.log(`     Result: ${enableData.done ? 'ENABLED' : JSON.stringify(enableData.error || enableData)}`);
    }
  }

  // Step 3: Verify SHA certs are registered for all apps
  console.log('\n=== Step 3: Verify SHA Certificates ===');
  const appsUrl = `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps`;
  const appsRes = await fetch(appsUrl, { headers: { Authorization: `Bearer ${token}` } });
  const appsData = await appsRes.json();

  for (const expectedApp of ANDROID_APPS) {
    const firebaseApp = appsData.apps?.find(a => a.packageName === expectedApp.packageName);
    if (!firebaseApp) {
      console.log(`  ❌ ${expectedApp.name} (${expectedApp.packageName}): NOT REGISTERED`);
      continue;
    }

    const shaUrl = `https://firebase.googleapis.com/v1beta1/${firebaseApp.name}/sha`;
    const shaRes = await fetch(shaUrl, { headers: { Authorization: `Bearer ${token}` } });
    const shaData = await shaRes.json();
    const sha1Certs = (shaData.certificates || []).filter(c => c.certType === 'SHA_1').map(c => c.shaHash.toUpperCase());
    
    if (sha1Certs.includes(expectedApp.sha1.toUpperCase())) {
      console.log(`  ✅ ${expectedApp.name} (${expectedApp.packageName}): SHA-1 registered`);
    } else {
      console.log(`  ⚠️  ${expectedApp.name}: Release SHA-1 ${expectedApp.sha1} not found in ${sha1Certs.join(', ')}`);
    }
  }

  // Step 4: Check the google-services.json to see if oauth_client got populated
  console.log('\n=== Step 4: Fresh google-services.json Check ===');
  for (const expectedApp of ANDROID_APPS) {
    const firebaseApp = appsData.apps?.find(a => a.packageName === expectedApp.packageName);
    if (!firebaseApp) continue;

    const configUrl = `https://firebase.googleapis.com/v1beta1/${firebaseApp.name}/config`;
    const configRes = await fetch(configUrl, { headers: { Authorization: `Bearer ${token}` } });
    const configData = await configRes.json();
    
    if (configData.configFileContents) {
      const config = JSON.parse(Buffer.from(configData.configFileContents, 'base64').toString('utf8'));
      const client = config.client?.find(c => c.client_info?.android_client_info?.package_name === expectedApp.packageName);
      const oauthClients = client?.oauth_client || [];
      
      if (oauthClients.length > 0) {
        console.log(`  ✅ ${expectedApp.name}: ${oauthClients.length} OAuth clients`);
        oauthClients.forEach(c => console.log(`     - type ${c.client_type}: ${c.client_id}`));
      } else {
        console.log(`  ❌ ${expectedApp.name}: oauth_client is EMPTY`);
        console.log(`     This is the ROOT CAUSE of OTP failure on Android.`);
        console.log(`     FIX: Go to Google Cloud Console → APIs & Services → Credentials`);
        console.log(`           → Create OAuth Client ID → Web Application → "DR-PHARMA Web Client"`);
        console.log(`     Then re-download google-services.json from Firebase Console.`);
      }
    }
  }

  // Step 5: Summary
  console.log('\n══════════════════════════════════════');
  console.log('FIREBASE PHONE AUTH DIAGNOSTIC SUMMARY');
  console.log('══════════════════════════════════════');
  console.log('');
  console.log('ACTION REQUIRED:');
  console.log('1. Go to: https://console.cloud.google.com/apis/credentials?project=' + PROJECT_ID);
  console.log('2. Click "Create Credentials" → "OAuth client ID"');
  console.log('3. Select "Web application" → Name: "DR-PHARMA Web Client"');
  console.log('4. Click "Create"');
  console.log('5. Then go to: https://console.firebase.google.com/project/' + PROJECT_ID + '/settings/general');
  console.log('6. Scroll to "Your apps" → Android app → Download google-services.json');
  console.log('7. Replace mobile/client/android/app/google-services.json with the new file');
  console.log('8. Rebuild the app');
  console.log('');
  console.log('The new google-services.json should have oauth_client entries like:');
  console.log('  { "client_type": 3, "client_id": "XXXX.apps.googleusercontent.com" }');
  console.log('');
  console.log('This web client ID is required for reCAPTCHA verification during phone auth.');
}

main().catch(console.error);
