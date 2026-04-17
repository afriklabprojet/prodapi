const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';
  const projectNumber = '549879846840';

  // 1. Check if Blaze plan by looking for billing account via projects.getBillingInfo
  console.log('=== Checking Billing Plan ===');
  try {
    const billingUrl = `https://cloudbilling.googleapis.com/v1/projects/${projectId}/billingInfo`;
    const billingRes = await fetch(billingUrl, { headers: { 'Authorization': `Bearer ${token}` } });
    if (billingRes.ok) {
      const billing = await billingRes.json();
      console.log('Billing:', JSON.stringify(billing, null, 2));
      if (billing.billingAccountName) {
        console.log('✅ Blaze plan (billing active)');
      } else {
        console.log('⚠️  No billing account = SPARK (FREE) PLAN');
        console.log('   Firebase Spark plan limits Phone Auth to ~10 SMS/day');
      }
    } else {
      console.log('Cannot check billing (API not enabled). Checking alternatives...');
    }
  } catch (e) {
    console.log('Billing check error:', e.message);
  }

  // 2. Check services that only exist on Blaze
  console.log('\n=== Checking Blaze-only services ===');
  const blazeServices = [
    'cloudfunctions.googleapis.com',
    'run.googleapis.com',
    'firestore.googleapis.com',
    'storage-component.googleapis.com'
  ];
  for (const svc of blazeServices) {
    const svcUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/${svc}`;
    const svcRes = await fetch(svcUrl, { headers: { 'Authorization': `Bearer ${token}` } });
    const svcData = await svcRes.json();
    console.log(`  ${svc}: ${svcData.state || 'ERROR'}`);
  }

  // 3. Check Phone Auth daily quota via monitoring (if available)
  console.log('\n=== SMS Verification Usage (last 7 days) ===');
  const now = new Date();
  const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  
  const monitorUrl = `https://monitoring.googleapis.com/v3/projects/${projectId}/timeSeries?` + new URLSearchParams({
    'filter': 'metric.type="identitytoolkit.googleapis.com/usage/phone_auth_sms_sent_count"',
    'interval.startTime': weekAgo.toISOString(),
    'interval.endTime': now.toISOString(),
    'aggregation.alignmentPeriod': '86400s',
    'aggregation.perSeriesAligner': 'ALIGN_SUM',
  });
  
  const monitorRes = await fetch(monitorUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  if (monitorRes.ok) {
    const monitorData = await monitorRes.json();
    if (monitorData.timeSeries && monitorData.timeSeries.length > 0) {
      monitorData.timeSeries.forEach(ts => {
        console.log(`  Metric: ${ts.metric.type}`);
        ts.points?.forEach(p => {
          console.log(`    ${p.interval.startTime}: ${p.value?.int64Value || p.value?.doubleValue || 0} SMS`);
        });
      });
    } else {
      console.log('  No SMS usage data available (metric may not exist or no SMS sent)');
    }
  } else {
    const err = await monitorRes.text();
    console.log('  Monitoring API response:', monitorRes.status, err.substring(0, 200));
  }

  // 4. Check Identity Platform quota override (Firebase-specific)
  console.log('\n=== Identity Platform Quota Config ===');
  const quotaUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;
  const quotaRes = await fetch(quotaUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const quotaConfig = await quotaRes.json();
  console.log('  Quota section:', JSON.stringify(quotaConfig.quota, null, 2));
  console.log('  SMS template:', JSON.stringify(quotaConfig.notification?.sendSms, null, 2));
  console.log('  MFA:', JSON.stringify(quotaConfig.mfa, null, 2));
  
  // 5. Test if we can list auth users with phone numbers (proves phone auth works/worked)
  console.log('\n=== Users with Phone Numbers ===');
  const admin = require('firebase-admin');
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert('api/storage/app/firebase-credentials.json'),
    });
  }
  
  try {
    const listResult = await admin.auth().listUsers(20);
    const phoneUsers = listResult.users.filter(u => u.phoneNumber);
    console.log(`  Total users: ${listResult.users.length}, with phone: ${phoneUsers.length}`);
    phoneUsers.forEach(u => {
      console.log(`  - ${u.phoneNumber} | UID: ${u.uid} | Last sign-in: ${u.metadata.lastSignInTime || 'never'} | Created: ${u.metadata.creationTime}`);
    });
    
    // Also show recently created users
    console.log('\n=== Most Recently Active Users ===');
    const sorted = listResult.users.sort((a, b) => {
      const aTime = new Date(a.metadata.lastSignInTime || 0).getTime();
      const bTime = new Date(b.metadata.lastSignInTime || 0).getTime();
      return bTime - aTime;
    });
    sorted.slice(0, 5).forEach(u => {
      console.log(`  - ${u.phoneNumber || u.email || 'N/A'} | Last: ${u.metadata.lastSignInTime} | Provider: ${u.providerData.map(p => p.providerId).join(',')}`);
    });
  } catch (e) {
    console.log('  Error listing users:', e.message);
  }
}

main().catch(console.error);
