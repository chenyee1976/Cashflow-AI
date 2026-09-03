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

    const cleanLines = lines.filter(l => {
      const trimmed = l.trim();
      if (!trimmed) return false;
      if (trimmed.includes('at org.gradle.')) return false;
      if (trimmed.includes('at java.base/')) return false;
      if (trimmed.includes('<asynchronous suspension>')) return false;
      if (/#\d+\s+/.test(trimmed)) return false;
      return true;
    });

    const last120Clean = cleanLines.slice(-120).join('\n');
    console.log('=== CLEAN ERROR LOG ===');
    console.log(last120Clean);

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
          error: last120Clean.substring(0, 10000)
        },
        client_timestamp: new Date().toISOString()
      })
    });
    console.log('Reported to Supabase! HTTP status:', res.status);
  } catch (e) {
    console.error('Error reporting:', e);
  }
}

report();
