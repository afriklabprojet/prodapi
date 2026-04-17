const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/identitytoolkit']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';

  // Test phone numbers for development/demo
  const testPhones = {
    '+2250100000001': '123456',
    '+2250100000002': '123456',
    '+2250100000003': '123456',
  };

  console.log('Adding test phone numbers to Firebase project...');
  console.log('Numbers:', Object.keys(testPhones).join(', '));

  // Update project config via Identity Toolkit Admin API v2
  const url = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config?updateMask=signIn.phoneNumber.testPhoneNumbers`;
  
  const body = {
    signIn: {
      phoneNumber: {
        enabled: true,
        testPhoneNumbers: testPhones
      }
    }
  };

  const res = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(body)
  });

  const result = await res.json();
  
  if (res.ok) {
    console.log('\n✅ Test phone numbers added successfully!');
    console.log('Phone numbers:', JSON.stringify(result.signIn?.phoneNumber, null, 2));
  } else {
    console.log('\n❌ Failed to add test phone numbers:');
    console.log(JSON.stringify(result, null, 2));
  }

  // Verify the update
  console.log('\n=== Verifying configuration ===');
  const verifyUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config`;
  const verifyRes = await fetch(verifyUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const verifyConfig = await verifyRes.json();
  console.log('Test phones:', JSON.stringify(verifyConfig.signIn?.phoneNumber?.testPhoneNumbers, null, 2));
}

main().catch(console.error);
