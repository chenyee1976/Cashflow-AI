const fs = require('fs');

async function report() {
  try {
    const logPath = process.argv[2] || 'build_aab.log';
    if (!fs.existsSync(logPath)) {
      console.log('Log file not found:', logPath);
      return;
    }
    const content = fs.readFileSync(logPath, 'utf8');
    const lines = content.split('\n');
    const lastLines = lines.slice(-120).join('\n');

    console.log('=== EXTRACTED LAST 120 LINES ===');
    console.log(lastLines);

    const res = await fetch('https://damkiewubedfkajbvoeo.supabase.co/rest/v1/activity_logs', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhbWtpZXd1YmVkZmthamJ2b2VvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcyODIyOTgsImV4cCI6MjEwMjg1ODI5OH0.DumsVaIE0R0qJax221CieE8_ldi3YMchybZome2c1G4',
        'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhbWtpZXd1YmVkZmthamJ2b2VvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcyODIyOTgsImV4cCI6MjEwMjg1ODI5OH0.DumsVaIE0R0qJax221CieE8_ldi3YMchybZome2c1G4'
      },
      body: JSON.stringify({
        event_type: 'build_diagnostic',
        event_name: 'android_build_failed',
        user_id: 'github_actions',
        details: {
          error: lastLines.substring(0, 10000)
        },
        client_timestamp: new Date().toISOString()
      })
    });

    console.log('Reported to Supabase! HTTP status:', res.status);
  } catch (e) {
    console.error('Error reporting build failure:', e);
  }
}

report();
