const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';

  // 1. Check SHA fingerprints for Android app
  console.log('=== Android App SHA Fingerprints ===');
  const appsUrl = `https://firebase.googleapis.com/v1beta1/projects/${projectId}/androidApps`;
  const appsRes = await fetch(appsUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const apps = await appsRes.json();
  
  if (apps.apps) {
    for (const app of apps.apps) {
      console.log(`\nApp: ${app.displayName || app.packageName} (${app.appId})`);
      console.log(`  Package: ${app.packageName}`);
      
      // Get SHA certs
      const shaUrl = `https://firebase.googleapis.com/v1beta1/${app.name}/sha`;
      const shaRes = await fetch(shaUrl, { headers: { 'Authorization': `Bearer ${token}` } });
      const sha = await shaRes.json();
      if (sha.certificates && sha.certificates.length > 0) {
        sha.certificates.forEach(c => {
          console.log(`  SHA ${c.certType}: ${c.shaHash}`);
        });
      } else {
        console.log('  ⚠️  NO SHA CERTIFICATES - Phone Auth will NOT work on Android!');
      }
    }
  }

  // 2. Check project billing account status (alternative method)
  console.log('\n=== Firebase Project Details ===');
  const projUrl = `https://firebase.googleapis.com/v1beta1/projects/${projectId}`;
  const projRes = await fetch(projUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const proj = await projRes.json();
  console.log(`  Project: ${proj.displayName}`);
  console.log(`  State: ${proj.state}`);
  console.log(`  Resources: ${JSON.stringify(proj.resources, null, 2)}`);

  // 3. Check GCP billing status via resource manager
  const rmUrl = `https://cloudresourcemanager.googleapis.com/v1/projects/${projectId}`;
  const rmRes = await fetch(rmUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const rm = await rmRes.json();
  console.log('\n=== Project Resource Manager ===');
  console.log(JSON.stringify(rm, null, 2));

  // 4. Check phone auth quotas specifically via servicemanagement
  console.log('\n=== Identity Toolkit API Enabled? ===');
  const svcUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/identitytoolkit.googleapis.com`;
  const svcRes = await fetch(svcUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const svc = await svcRes.json();
  console.log(`  State: ${svc.state}`);
  console.log(`  Config: ${svc.config?.name}`);
  
  // Check Firebase Auth API
  const authSvcUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/firebaseauth.googleapis.com`;
  const authSvcRes = await fetch(authSvcUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const authSvc = await authSvcRes.json();
  console.log(`\n  Firebase Auth API State: ${authSvc.state}`);

  // 5. Check daily SMS usage quota (using Consumer Quota)
  console.log('\n=== Consumer Quotas for Identity Toolkit ===');
  const quotaUrl = `https://serviceusage.googleapis.com/v1beta1/projects/${projectId}/services/identitytoolkit.googleapis.com/consumerQuotaMetrics`;
  const quotaRes = await fetch(quotaUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const quotaData = await quotaRes.json();
  if (quotaData.metrics) {
    for (const metric of quotaData.metrics) {
      if (metric.metric?.includes('sms') || metric.metric?.includes('phone') || metric.metric?.includes('send') || metric.displayName?.toLowerCase()?.includes('sms')) {
        console.log(`  ${metric.displayName}: ${JSON.stringify(metric.consumerQuotaLimits, null, 2)}`);
      }
    }
  }
  // Also print all quota metric names
  console.log('\n  All quota metrics:');
  if (quotaData.metrics) {
    quotaData.metrics.forEach(m => console.log(`    - ${m.displayName || m.metric}`));
  } else {
    console.log('    Error:', JSON.stringify(quotaData));
  }
}

main().catch(console.error);
