const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';

  // 1. Check Android Device Verification API status
  console.log('=== Checking Android Device Verification API ===');
  const checkUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/androidcheck.googleapis.com`;
  const checkRes = await fetch(checkUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const checkData = await checkRes.json();
  console.log('Status:', checkData.state || checkData.error?.message || JSON.stringify(checkData));

  if (checkData.state !== 'ENABLED') {
    console.log('\n=== Enabling Android Device Verification API ===');
    const enableUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/androidcheck.googleapis.com:enable`;
    const enableRes = await fetch(enableUrl, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
    });
    const enableData = await enableRes.json();
    console.log('Enable result:', JSON.stringify(enableData, null, 2));
  }

  // 2. Also check Firebase App Check API
  console.log('\n=== Checking Firebase App Check API ===');
  const appCheckUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/firebaseappcheck.googleapis.com`;
  const appCheckRes = await fetch(appCheckUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const appCheckData = await appCheckRes.json();
  console.log('Status:', appCheckData.state || JSON.stringify(appCheckData));

  if (appCheckData.state !== 'ENABLED') {
    console.log('Enabling Firebase App Check API...');
    const enableUrl2 = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/firebaseappcheck.googleapis.com:enable`;
    const enableRes2 = await fetch(enableUrl2, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
    });
    console.log('Result:', JSON.stringify(await enableRes2.json(), null, 2));
  }

  // 3. Check reCAPTCHA Enterprise API
  console.log('\n=== Checking reCAPTCHA Enterprise API ===');
  const recaptchaUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/recaptchaenterprise.googleapis.com`;
  const recaptchaRes = await fetch(recaptchaUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const recaptchaData = await recaptchaRes.json();
  console.log('Status:', recaptchaData.state || JSON.stringify(recaptchaData));

  if (recaptchaData.state !== 'ENABLED') {
    console.log('Enabling reCAPTCHA Enterprise API...');
    const enableUrl3 = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/recaptchaenterprise.googleapis.com:enable`;
    const enableRes3 = await fetch(enableUrl3, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
    });
    console.log('Result:', JSON.stringify(await enableRes3.json(), null, 2));
  }

  // 4. Check Identity Toolkit API
  console.log('\n=== Checking Identity Toolkit API ===');
  const idtkUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/identitytoolkit.googleapis.com`;
  const idtkRes = await fetch(idtkUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const idtkData = await idtkRes.json();
  console.log('Status:', idtkData.state || JSON.stringify(idtkData));

  // 5. List SHA fingerprints for client app to verify  
  console.log('\n=== SHA Fingerprints for client app ===');
  const sha1Url = `https://firebase.googleapis.com/v1beta1/projects/${projectId}/androidApps/1:549879846840:android:0f5cdc8af2efe91458614d/sha`;
  const sha1Res = await fetch(sha1Url, { headers: { 'Authorization': `Bearer ${token}` } });
  const sha1Data = await sha1Res.json();
  console.log(JSON.stringify(sha1Data, null, 2));
}
main().catch(console.error);
