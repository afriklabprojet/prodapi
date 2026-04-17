const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';

  // 1. Get full auth config
  const url = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;
  const res = await fetch(url, { headers: { 'Authorization': `Bearer ${token}` } });
  const config = await res.json();

  console.log('=== Phone Auth Enabled ===');
  console.log(JSON.stringify(config.signIn?.phoneNumber, null, 2));

  console.log('\n=== SMS Region Config ===');
  console.log(JSON.stringify(config.smsRegionConfig, null, 2));

  console.log('\n=== Quota ===');
  console.log(JSON.stringify(config.quota, null, 2));

  console.log('\n=== reCAPTCHA Config ===');
  console.log(JSON.stringify(config.recaptchaConfig, null, 2));

  // 2. Check billing / usage via Cloud Billing API
  const billingUrl = `https://cloudbilling.googleapis.com/v1/projects/${projectId}/billingInfo`;
  const billingRes = await fetch(billingUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const billingInfo = await billingRes.json();
  console.log('\n=== Billing Info ===');
  console.log(JSON.stringify(billingInfo, null, 2));

  // 3. List test phone numbers (Identity Platform v2)
  const v2Url = `https://identitytoolkit.googleapis.com/v2/projects/${projectId}/config`;
  const v2Res = await fetch(v2Url, { headers: { 'Authorization': `Bearer ${token}` } });
  const v2Config = await v2Res.json();
  console.log('\n=== Sign-In Config (v2) ===');
  console.log(JSON.stringify(v2Config.signIn, null, 2));

  // 4. Check if there are authorized phone test numbers
  if (v2Config.signIn?.phoneNumber?.testPhoneNumbers) {
    console.log('\n=== Test Phone Numbers ===');
    console.log(JSON.stringify(v2Config.signIn.phoneNumber.testPhoneNumbers, null, 2));
  } else {
    console.log('\n=== Test Phone Numbers ===');
    console.log('No test phone numbers configured');
  }

  // 5. Check App Check enforcement
  const appCheckUrl = `https://firebaseappcheck.googleapis.com/v1/projects/${projectId}/apps`;
  const appCheckRes = await fetch(appCheckUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const appCheck = await appCheckRes.json();
  console.log('\n=== App Check ===');
  console.log(JSON.stringify(appCheck, null, 2));

  // 6. Check recently created users (to see if auth works at all)
  const usersUrl = `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:batchGet?maxResults=5`;
  const usersRes = await fetch(usersUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const users = await usersRes.json();
  console.log('\n=== Recent Users (last 5) ===');
  if (users.users) {
    users.users.forEach(u => {
      console.log(`  - ${u.phoneNumber || u.email || 'N/A'} | Created: ${new Date(parseInt(u.createdAt)).toISOString()} | Last login: ${u.lastLoginAt ? new Date(parseInt(u.lastLoginAt)).toISOString() : 'never'}`);
    });
  } else {
    console.log('No users found or error:', JSON.stringify(users));
  }
}

main().catch(console.error);
