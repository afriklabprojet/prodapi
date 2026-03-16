const { google } = require('googleapis');
const https = require('https');
const path = require('path');
const keyFile = path.join(__dirname, '..', 'api', 'storage', 'app', 'firebase-credentials.json');

async function main() {
  const auth = new google.auth.GoogleAuth({
    keyFile: keyFile,
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  console.log('Got access token');

  // Check androidcheck API using raw REST call
  const apis = ['androidcheck.googleapis.com', 'playintegrity.googleapis.com'];

  for (const api of apis) {
    await new Promise(function (resolve) {
      const options = {
        hostname: 'serviceusage.googleapis.com',
        path: '/v1/projects/549879846840/services/' + api,
        method: 'GET',
        headers: { 'Authorization': 'Bearer ' + token.token },
        timeout: 10000,
      };

      const req = https.request(options, function (res) {
        let data = '';
        res.on('data', function (c) { data += c; });
        res.on('end', function () {
          try {
            const json = JSON.parse(data);
            console.log(api + ': ' + (json.state || json.error?.message || data.substring(0, 100)));
          } catch (e) {
            console.log(api + ' raw: ' + data.substring(0, 200));
          }
          resolve();
        });
      });
      req.on('error', function (e) { console.log(api + ' error: ' + e.message); resolve(); });
      req.on('timeout', function () { console.log(api + ' timeout'); req.destroy(); resolve(); });
      req.end();
    });

    // Try to enable
    await new Promise(function (resolve) {
      const options = {
        hostname: 'serviceusage.googleapis.com',
        path: '/v1/projects/549879846840/services/' + api + ':enable',
        method: 'POST',
        headers: {
          'Authorization': 'Bearer ' + token.token,
          'Content-Type': 'application/json',
        },
        timeout: 15000,
      };

      const req = https.request(options, function (res) {
        let data = '';
        res.on('data', function (c) { data += c; });
        res.on('end', function () {
          console.log('  enable ' + api + ': ' + data.substring(0, 200));
          resolve();
        });
      });
      req.on('error', function (e) { console.log('  enable error: ' + e.message); resolve(); });
      req.on('timeout', function () { console.log('  enable timeout'); req.destroy(); resolve(); });
      req.write('{}');
      req.end();
    });
  }

  console.log('DONE');
}

main().catch(function (e) { console.error('FATAL: ' + e.message); });
