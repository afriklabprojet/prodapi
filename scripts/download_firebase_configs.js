const { GoogleAuth } = require('google-auth-library');
const fs = require('fs');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();

  const apps = [
    { name: 'client', appId: '1:549879846840:android:0f5cdc8af2efe91458614d', dest: 'mobile/client/android/app/google-services.json' },
    { name: 'delivery', appId: '1:549879846840:android:0eadce85c99c3bf658614d', dest: 'mobile/delivery/android/app/google-services.json' },
    { name: 'pharmacy', appId: '1:549879846840:android:86aea6d70d78ec4258614d', dest: 'mobile/pharmacy/android/app/google-services.json' }
  ];

  for (const app of apps) {
    const url = `https://firebase.googleapis.com/v1beta1/projects/dr-pharma-6027d/androidApps/${app.appId}/config`;
    const res = await fetch(url, { headers: { 'Authorization': `Bearer ${token}` } });
    const data = await res.json();
    if (data.configFileContents) {
      const config = Buffer.from(data.configFileContents, 'base64').toString('utf8');
      fs.writeFileSync(app.dest, config);
      console.log(`${app.name}: OK -> ${app.dest}`);
      // Show oauth_client count
      const parsed = JSON.parse(config);
      const oauthCount = parsed.client?.[0]?.oauth_client?.length || 0;
      console.log(`  oauth_client entries: ${oauthCount}`);
    } else {
      console.log(`${app.name}: ERROR`, JSON.stringify(data));
    }
  }
}
main().catch(console.error);
