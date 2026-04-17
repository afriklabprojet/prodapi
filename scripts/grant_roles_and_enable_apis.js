const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';
  const serviceAccountEmail = 'firebase-adminsdk-fbsvc@dr-pharma-6027d.iam.gserviceaccount.com';

  // Step 1: Get current IAM policy
  console.log('=== Getting current IAM policy ===');
  const getPolicyUrl = `https://cloudresourcemanager.googleapis.com/v1/projects/${projectId}:getIamPolicy`;
  const policyRes = await fetch(getPolicyUrl, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  });
  const policy = await policyRes.json();

  if (policy.error) {
    console.log('ERROR getting policy:', JSON.stringify(policy.error, null, 2));
    console.log('\n=== MANUAL STEPS REQUIRED ===');
    console.log('The service account cannot modify its own IAM roles.');
    console.log('You need to do this manually in Google Cloud Console:');
    console.log(`\n1. Go to: https://console.cloud.google.com/iam-admin/iam?project=${projectId}`);
    console.log(`2. Find: ${serviceAccountEmail}`);
    console.log('3. Click the pencil (edit) icon');
    console.log('4. Add these roles:');
    console.log('   - Service Usage Consumer');
    console.log('   - Service Usage Admin');
    console.log('5. Click Save');
    return;
  }

  console.log('Current bindings count:', policy.bindings?.length || 0);

  // List current roles for our service account
  const currentRoles = (policy.bindings || [])
    .filter(b => b.members?.includes(`serviceAccount:${serviceAccountEmail}`))
    .map(b => b.role);
  console.log('\nCurrent roles for service account:', currentRoles);

  // Step 2: Add missing roles
  const rolesToAdd = [
    'roles/serviceusage.serviceUsageConsumer',
    'roles/serviceusage.serviceUsageAdmin',
    'roles/firebase.admin'
  ];

  const missingRoles = rolesToAdd.filter(r => !currentRoles.includes(r));

  if (missingRoles.length === 0) {
    console.log('\nAll roles already assigned!');
  } else {
    console.log('\nAdding missing roles:', missingRoles);

    for (const role of missingRoles) {
      const existing = policy.bindings?.find(b => b.role === role);
      if (existing) {
        if (!existing.members.includes(`serviceAccount:${serviceAccountEmail}`)) {
          existing.members.push(`serviceAccount:${serviceAccountEmail}`);
        }
      } else {
        if (!policy.bindings) policy.bindings = [];
        policy.bindings.push({
          role: role,
          members: [`serviceAccount:${serviceAccountEmail}`]
        });
      }
    }

    // Step 3: Set updated policy
    const setPolicyUrl = `https://cloudresourcemanager.googleapis.com/v1/projects/${projectId}:setIamPolicy`;
    const setRes = await fetch(setPolicyUrl, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ policy: policy })
    });
    const result = await setRes.json();

    if (result.error) {
      console.log('ERROR setting policy:', JSON.stringify(result.error, null, 2));
      console.log('\n=== MANUAL STEPS REQUIRED ===');
      console.log(`Go to: https://console.cloud.google.com/iam-admin/iam?project=${projectId}`);
      console.log(`Find: ${serviceAccountEmail}`);
      console.log('Add roles: Service Usage Consumer, Service Usage Admin, Firebase Admin');
    } else {
      console.log('SUCCESS! Roles updated.');

      // Verify
      const newRoles = (result.bindings || [])
        .filter(b => b.members?.includes(`serviceAccount:${serviceAccountEmail}`))
        .map(b => b.role);
      console.log('Updated roles:', newRoles);
    }
  }

  // Step 4: Now enable the required APIs
  console.log('\n=== Enabling required APIs ===');
  const apisToEnable = [
    'androidcheck.googleapis.com',
    'firebaseappcheck.googleapis.com',
    'recaptchaenterprise.googleapis.com',
    'identitytoolkit.googleapis.com'
  ];

  for (const api of apisToEnable) {
    const checkUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/${api}`;
    const checkRes = await fetch(checkUrl, { headers: { 'Authorization': `Bearer ${token}` } });
    const checkData = await checkRes.json();

    if (checkData.state === 'ENABLED') {
      console.log(`${api}: already ENABLED`);
    } else {
      console.log(`${api}: ${checkData.state || 'NOT ENABLED'} -> enabling...`);
      const enableUrl = `${checkUrl}:enable`;
      const enableRes = await fetch(enableUrl, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
      });
      const enableData = await enableRes.json();
      if (enableData.error) {
        console.log(`  ERROR: ${enableData.error.message}`);
      } else {
        console.log(`  OK: operation ${enableData.name || 'started'}`);
      }
    }
  }
}
main().catch(console.error);
