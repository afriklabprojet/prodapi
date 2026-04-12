const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/identitytoolkit', 'https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';
  
  // Update SMS region to allow more countries (West Africa + France for testing)
  const configUrl = `https://identitytoolkit.googleapis.com/admin/v2/projects/${projectId}/config?updateMask=smsRegionConfig`;
  const body = {
    smsRegionConfig: {
      allowlistOnly: {
        allowedRegions: ['CI', 'BF', 'SN', 'ML', 'GN', 'TG', 'BJ', 'NE', 'FR']
      }
    }
  };
  
  console.log('Updating SMS regions...');
  const res = await fetch(configUrl, {
    method: 'PATCH',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });
  const result = await res.json();
  
  if (result.error) {
    console.log('Error:', result.error.message);
  } else {
    console.log('SUCCESS! SMS regions updated:');
    console.log(JSON.stringify(result.smsRegionConfig, null, 2));
  }
}
main().catch(console.error);
