const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/cloud-billing']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';

  // 1. Try to enable Cloud Billing API first
  console.log('=== Enabling Cloud Billing API ===');
  const enableUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/cloudbilling.googleapis.com:enable`;
  const enableRes = await fetch(enableUrl, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({})
  });
  const enableData = await enableRes.json();
  if (enableRes.ok) {
    console.log('✅ Cloud Billing API enabled');
  } else {
    console.log('Billing API:', JSON.stringify(enableData, null, 2));
  }

  // Wait a bit for propagation
  if (enableRes.ok) {
    console.log('Waiting for propagation...');
    await new Promise(r => setTimeout(r, 5000));
  }

  // 2. Check current billing status
  console.log('\n=== Current Billing Status ===');
  const billingUrl = `https://cloudbilling.googleapis.com/v1/projects/${projectId}/billingInfo`;
  const billingRes = await fetch(billingUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const billing = await billingRes.json();
  console.log(JSON.stringify(billing, null, 2));

  if (billing.billingAccountName) {
    console.log('\n✅ Project already has billing! Blaze plan is active.');
    console.log(`Billing account: ${billing.billingAccountName}`);
    return;
  }

  // 3. List available billing accounts
  console.log('\n=== Available Billing Accounts ===');
  const accountsUrl = 'https://cloudbilling.googleapis.com/v1/billingAccounts';
  const accountsRes = await fetch(accountsUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const accounts = await accountsRes.json();
  
  if (accounts.billingAccounts && accounts.billingAccounts.length > 0) {
    accounts.billingAccounts.forEach(a => {
      console.log(`  - ${a.name}: ${a.displayName} (${a.open ? 'OPEN' : 'CLOSED'})`);
    });

    // 4. Link the first open billing account to the project
    const openAccount = accounts.billingAccounts.find(a => a.open);
    if (openAccount) {
      console.log(`\nLinking billing account ${openAccount.name} to project...`);
      const linkRes = await fetch(billingUrl, {
        method: 'PUT',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          billingAccountName: openAccount.name
        })
      });
      const linkData = await linkRes.json();
      if (linkRes.ok) {
        console.log('✅ Blaze plan activated!');
        console.log(JSON.stringify(linkData, null, 2));
      } else {
        console.log('❌ Failed to link billing:');
        console.log(JSON.stringify(linkData, null, 2));
      }
    } else {
      console.log('\n⚠️ No open billing accounts found.');
      console.log('You need to create a billing account at: https://console.firebase.google.com/project/dr-pharma-6027d/overview');
      console.log('Then go to Settings > Usage and billing > Upgrade to Blaze plan');
    }
  } else {
    console.log('⚠️ No billing accounts accessible with this service account.');
    console.log('\n📋 To upgrade to Blaze plan manually:');
    console.log('1. Go to https://console.firebase.google.com/project/dr-pharma-6027d/overview');
    console.log('2. Click on the gear icon (Settings) > Usage and billing');
    console.log('3. Click "Modify plan" or "Upgrade"');
    console.log('4. Select "Blaze (pay as you go)"');
    console.log('5. Add a payment method (card)');
    console.log('\nNote: Phone auth SMS costs ~$0.06/SMS for Côte d\'Ivoire');
    console.log('You can set budget alerts to control costs.');
  }
}

main().catch(console.error);
