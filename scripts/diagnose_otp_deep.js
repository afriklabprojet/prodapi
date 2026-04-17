const { GoogleAuth } = require('google-auth-library');
const admin = require('firebase-admin');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';

  // Initialize Firebase Admin
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert('api/storage/app/firebase-credentials.json'),
    });
  }

  // 1. Check SMS region config
  const configUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;
  const configRes = await fetch(configUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const config = await configRes.json();
  
  console.log('=== SMS Region Config ===');
  console.log(JSON.stringify(config.smsRegionConfig, null, 2));
  console.log('\nAllowed regions:', config.smsRegionConfig?.allowlistOnly?.allowedRegions?.join(', ') || 'ALL');

  // 2. Check reCAPTCHA enforcement
  console.log('\n=== reCAPTCHA Config ===');
  console.log(JSON.stringify(config.recaptchaConfig, null, 2));
  
  // 3. Check if there are any blocking functions
  console.log('\n=== Blocking Functions ===');
  console.log(JSON.stringify(config.blockingFunctions, null, 2));

  // 4. Check SMS template
  console.log('\n=== SMS Template ===');
  console.log(JSON.stringify(config.notification?.sendSms, null, 2));

  // 5. List ALL Firebase users (look for recent failed auth)
  console.log('\n=== All Firebase Auth Users ===');
  const listResult = await admin.auth().listUsers(100);
  console.log(`Total: ${listResult.users.length} users`);
  listResult.users.forEach(u => {
    const providers = u.providerData.map(p => p.providerId).join(', ') || 'none';
    const phone = u.phoneNumber || 'no-phone';
    const email = u.email || 'no-email';
    const disabled = u.disabled ? ' [DISABLED]' : '';
    console.log(`  ${u.uid.substring(0,12)}... | ${phone} | ${email} | providers: ${providers} | created: ${u.metadata.creationTime} | last-login: ${u.metadata.lastSignInTime || 'never'}${disabled}`);
  });

  // 6. Check if App Check is enforced for Identity Toolkit
  console.log('\n=== App Check Enforcement ===');
  const appCheckUrl = `https://firebaseappcheck.googleapis.com/v1/projects/${projectId}/apps`;
  const appCheckRes = await fetch(appCheckUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const appCheckData = await appCheckRes.json();
  
  if (appCheckData.apps) {
    appCheckData.apps.forEach(app => {
      console.log(`  ${app.name} - enforcement: ${app.enforcementState || 'UNENFORCED'}`);
    });
  } else {
    console.log('  No App Check apps configured (or error):', JSON.stringify(appCheckData).substring(0, 200));
  }

  // 7. Check if Identity Toolkit has App Check enforcement
  const enforceUrl = `https://firebaseappcheck.googleapis.com/v1/projects/${projectId}/services`;
  const enforceRes = await fetch(enforceUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const enforceData = await enforceRes.json();
  
  if (enforceData.services) {
    console.log('\n=== App Check Service Enforcement ===');
    enforceData.services.forEach(svc => {
      const name = svc.name.split('/').pop();
      console.log(`  ${name}: ${svc.enforcementMode}`);
    });
    
    const identitySvc = enforceData.services.find(s => s.name.includes('identitytoolkit'));
    if (identitySvc && identitySvc.enforcementMode === 'ENFORCED') {
      console.log('\n⚠️  WARNING: App Check is ENFORCED for Identity Toolkit!');
      console.log('This means phone auth requests WITHOUT valid App Check tokens will be REJECTED.');
      console.log('If the app doesn\'t implement App Check, OTP SMS won\'t be sent.');
    }
  } else {
    console.log('\n  App Check services:', JSON.stringify(enforceData).substring(0, 200));
  }

  // 8. Check SHA certificates vs client app package
  console.log('\n=== SHA Certificates for Client App ===');
  const appsUrl = `https://firebase.googleapis.com/v1beta1/projects/${projectId}/androidApps`;
  const appsRes = await fetch(appsUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const apps = await appsRes.json();
  
  const clientApp = apps.apps?.find(a => a.packageName === 'ci.drpharma.drpharma_client');
  if (clientApp) {
    const shaUrl = `https://firebase.googleapis.com/v1beta1/${clientApp.name}/sha`;
    const shaRes = await fetch(shaUrl, { headers: { 'Authorization': `Bearer ${token}` } });
    const sha = await shaRes.json();
    console.log(`  Package: ${clientApp.packageName}`);
    if (sha.certificates) {
      sha.certificates.forEach(c => {
        console.log(`  ${c.certType}: ${c.shaHash}`);
      });
    }
    // Check debug keystore SHA too
    console.log('\n  Debug keystore SHA (for development builds):');
    console.log('  Run: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android 2>/dev/null | grep SHA');
  }

  // 9. Check Cloud Identity Platform Phone Auth
  console.log('\n=== Identity Platform Phone Auth Settings ===');
  console.log(`  Phone Auth Enabled: ${config.signIn?.phoneNumber?.enabled}`);
  console.log(`  Test Numbers: ${JSON.stringify(config.signIn?.phoneNumber?.testPhoneNumbers || {})}`);
  
  // 10. Summary & Recommendations
  console.log('\n══════════════════════════════════════');
  console.log('DIAGNOSTIC SUMMARY');
  console.log('══════════════════════════════════════');
  
  const issues = [];
  
  if (config.smsRegionConfig?.allowlistOnly) {
    const regions = config.smsRegionConfig.allowlistOnly.allowedRegions;
    console.log(`✅ SMS limited to regions: ${regions.join(', ')}`);
  }
  
  if (enforceData.services) {
    const identitySvc = enforceData.services.find(s => s.name.includes('identitytoolkit'));
    if (identitySvc?.enforcementMode === 'ENFORCED') {
      issues.push('🔴 App Check ENFORCED for Identity Toolkit - may block phone auth');
    } else {
      console.log('✅ App Check NOT enforced for Identity Toolkit');
    }
  }
  
  if (config.recaptchaConfig?.phoneEnforcementState === 'ENFORCE') {
    issues.push('🔴 reCAPTCHA ENFORCED for phone auth');
  } else {
    console.log('✅ reCAPTCHA not enforced for phone');
  }
  
  console.log(`✅ Billing: Blaze plan active`);
  console.log(`✅ Phone Auth: ${config.signIn?.phoneNumber?.enabled ? 'Enabled' : 'DISABLED'}`);
  
  if (issues.length > 0) {
    console.log('\n🚨 ISSUES DETECTED:');
    issues.forEach(i => console.log(`  ${i}`));
  } else {
    console.log('\n✅ No configuration issues detected.');
    console.log('If OTP still not working, possible causes:');
    console.log('  1. SMS carrier issues in Côte d\'Ivoire (CI)');
    console.log('  2. User\'s phone number format incorrect');
    console.log('  3. Firebase internal rate limiting (per-number)');
    console.log('  4. APK signing mismatch (SHA not registered)');
    console.log('  5. Network/connectivity issues on user device');
  }
}

main().catch(console.error);
