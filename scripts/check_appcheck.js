const { GoogleAuth } = require('google-auth-library');

async function main() {
  const auth = new GoogleAuth({
    keyFile: 'api/storage/app/firebase-credentials.json',
    scopes: ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform']
  });
  const token = await auth.getAccessToken();
  const projectId = 'dr-pharma-6027d';
  const projectNumber = '549879846840';

  // 1. Enable App Check API if needed
  console.log('=== Checking App Check API ===');
  const enableUrl = `https://serviceusage.googleapis.com/v1/projects/${projectId}/services/firebaseappcheck.googleapis.com`;
  const enableRes = await fetch(enableUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  const enableData = await enableRes.json();
  console.log(`App Check API: ${enableData.state}`);

  if (enableData.state !== 'ENABLED') {
    console.log('Enabling App Check API...');
    await fetch(`${enableUrl}:enable`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: '{}'
    });
    await new Promise(r => setTimeout(r, 5000));
    console.log('Enabled. Waiting...');
  }

  // 2. Check App Check service enforcement
  console.log('\n=== App Check Service Enforcement ===');
  const servicesUrl = `https://firebaseappcheck.googleapis.com/v1/projects/${projectNumber}/services`;
  const servicesRes = await fetch(servicesUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  
  if (servicesRes.ok) {
    const servicesData = await servicesRes.json();
    if (servicesData.services) {
      servicesData.services.forEach(svc => {
        const name = svc.name.split('/').pop();
        const mode = svc.enforcementMode || 'UNENFORCED';
        const icon = mode === 'ENFORCED' ? '🔴' : '✅';
        console.log(`  ${icon} ${name}: ${mode}`);
      });
    } else {
      console.log('  No services found');
      console.log(JSON.stringify(servicesData, null, 2));
    }
  } else {
    const errText = await servicesRes.text();
    console.log(`  Error (${servicesRes.status}): ${errText.substring(0, 300)}`);
    
    // Try with project ID instead of number
    const alt = `https://firebaseappcheck.googleapis.com/v1/projects/${projectId}/services`;
    const altRes = await fetch(alt, { headers: { 'Authorization': `Bearer ${token}` } });
    if (altRes.ok) {
      const altData = await altRes.json();
      if (altData.services) {
        altData.services.forEach(svc => {
          const name = svc.name.split('/').pop();
          console.log(`  ${name}: ${svc.enforcementMode || 'UNENFORCED'}`);
        });
      }
    } else {
      console.log('  Alt also failed:', altRes.status);
    }
  }

  // 3. Check Safety Net / Play Integrity setup
  console.log('\n=== App Check Apps (Play Integrity / SafetyNet) ===');
  const appsUrl = `https://firebaseappcheck.googleapis.com/v1/projects/${projectNumber}/apps`;
  const appsRes = await fetch(appsUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  if (appsRes.ok) {
    const appsData = await appsRes.json();
    if (appsData.apps) {
      appsData.apps.forEach(app => {
        console.log(`  ${app.name}: ${JSON.stringify(app, null, 2)}`);
      });
    } else {
      console.log('  Response:', JSON.stringify(appsData, null, 2));
    }
  } else {
    // Try project ID  
    const appsUrl2 = `https://firebaseappcheck.googleapis.com/v1/projects/${projectId}/apps`;
    const appsRes2 = await fetch(appsUrl2, { headers: { 'Authorization': `Bearer ${token}` } });
    if (appsRes2.ok) {
      const data = await appsRes2.json();
      console.log(JSON.stringify(data, null, 2));
    } else {
      console.log('  Error:', appsRes.status, (await appsRes.text()).substring(0, 200));
    }
  }

  // 4. Check Android device verification (Play Integrity / SafetyNet)
  console.log('\n=== Android Device Verification ===');
  const androidCheckUrl = `https://firebaseappcheck.googleapis.com/v1/projects/${projectNumber}/apps/1:549879846840:android:0f5cdc8af2efe91458614d/playIntegrityConfig`;
  const androidRes = await fetch(androidCheckUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  if (androidRes.ok) {
    console.log('Play Integrity:', JSON.stringify(await androidRes.json(), null, 2));
  } else {
    console.log(`Play Integrity: not configured (${androidRes.status})`);
  }
  
  // SafetyNet
  const safetyNetUrl = `https://firebaseappcheck.googleapis.com/v1/projects/${projectNumber}/apps/1:549879846840:android:0f5cdc8af2efe91458614d/safetyNetConfig`;
  const safetyNetRes = await fetch(safetyNetUrl, { headers: { 'Authorization': `Bearer ${token}` } });
  if (safetyNetRes.ok) {
    console.log('SafetyNet:', JSON.stringify(await safetyNetRes.json(), null, 2));
  } else {
    console.log(`SafetyNet: not configured (${safetyNetRes.status})`);
  }

  // 5. Check recent Firebase Auth events via Cloud Logging
  console.log('\n=== Recent Auth Logs (via Cloud Logging) ===');
  const loggingUrl = `https://logging.googleapis.com/v2/entries:list`;
  const logBody = {
    resourceNames: [`projects/${projectId}`],
    filter: 'resource.type="identitytoolkit_project" AND timestamp>="' + new Date(Date.now() - 7*24*60*60*1000).toISOString() + '"',
    orderBy: 'timestamp desc',
    pageSize: 20
  };
  
  const logRes = await fetch(loggingUrl, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(logBody)
  });
  
  if (logRes.ok) {
    const logData = await logRes.json();
    if (logData.entries) {
      console.log(`Found ${logData.entries.length} recent auth events:`);
      logData.entries.forEach(entry => {
        const ts = entry.timestamp || entry.receiveTimestamp;
        const sev = entry.severity;
        const msg = entry.textPayload || JSON.stringify(entry.jsonPayload || {}).substring(0, 200);
        console.log(`  [${ts}] ${sev}: ${msg}`);
      });
    } else {
      console.log('  No auth log entries found in last 7 days');
    }
  } else {
    const logErr = await logRes.text();
    console.log(`  Logging API error (${logRes.status}): ${logErr.substring(0, 200)}`);
    
    // Enable logging API
    if (logRes.status === 403) {
      console.log('  Enabling Cloud Logging API...');
      await fetch(`https://serviceusage.googleapis.com/v1/projects/${projectId}/services/logging.googleapis.com:enable`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: '{}'
      });
    }
  }
}

main().catch(console.error);
