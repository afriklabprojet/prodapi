const https = require('https');

const API_KEY = '239e46fe655d53cc9cde8dd8b62e6fc0-d074b80d-744c-4314-a00a-017596dfe48e';
const BASE_HOST = '8vg98e.api.infobip.com';

function request(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const headers = {
      'Authorization': `App ${API_KEY}`,
      'Accept': 'application/json',
    };
    if (body) headers['Content-Type'] = 'application/json';

    const req = https.request({
      hostname: BASE_HOST,
      path,
      method,
      headers,
    }, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function main() {
  // 1. Verify SMS API works (send a ping-style request)
  console.log('=== SMS API - Preview ===');
  const smsPreview = await request('POST', '/sms/1/preview', {
    text: 'Test OTP: 123456'
  });
  console.log('Status:', smsPreview.status);
  console.log('Response:', smsPreview.body.substring(0, 500));

  // 2. Try getting WhatsApp templates via management API v2
  console.log('\n=== WhatsApp Templates (v2) ===');
  const templates = await request('GET', '/whatsapp/2/senders/15558636493/templates');
  console.log('Status:', templates.status);
  console.log('Response:', templates.body.substring(0, 1000));

  // 3. Try management API v1
  console.log('\n=== WhatsApp Templates (v1) ===');
  const templatesV1 = await request('GET', '/whatsapp/1/senders/15558636493/templates');
  console.log('Status:', templatesV1.status);
  console.log('Response:', templatesV1.body.substring(0, 1000));

  // 4. Try sending a WhatsApp template (DRY RUN - to invalid number to check API access)
  // This tests if the API key has SEND permission
  console.log('\n=== WhatsApp Template Send Test (to invalid number) ===');
  const sendTest = await request('POST', '/whatsapp/1/message/template', {
    messages: [{
      from: '15558636493',
      to: '22500000000',  // invalid test number
      content: {
        templateName: 'otp_verification',
        templateData: {
          body: { placeholders: ['123456'] }
        },
        language: 'fr'
      }
    }]
  });
  console.log('Status:', sendTest.status);
  console.log('Response:', sendTest.body.substring(0, 1000));
}

main().catch(console.error);
