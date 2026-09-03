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

    // 1. Look for Target ... failed
    let relevantLines = [];
    const targetIdx = lines.findIndex(l => l.includes('Target ') && l.includes('failed'));
    if (targetIdx !== -1) {
      const start = Math.max(0, targetIdx - 20);
      const end = Math.min(lines.length, targetIdx + 80);
      relevantLines.push('=== TARGET FAILURE SECTION ===');
      relevantLines.push(...lines.slice(start, end));
    }

    // 2. Look for compileFlutterBuildRelease or throwToolExit
    const toolExitIdx = lines.findIndex(l => l.includes('throwToolExit'));
    if (toolExitIdx !== -1) {
      const start = Math.max(0, toolExitIdx - 40);
      const end = Math.min(lines.length, toolExitIdx + 20);
      relevantLines.push('=== THROW TOOL EXIT SECTION ===');
      relevantLines.push(...lines.slice(start, end));
    }

    // 3. Fallback: all lines containing error, failed, exception (case insensitive)
    if (relevantLines.length === 0) {
      const matching = lines.filter(l => 
        (l.toLowerCase().includes('error') || l.toLowerCase().includes('exception') || l.toLowerCase().includes('failed')) &&
        !l.includes('org.gradle.internal.execution.steps')
      );
      relevantLines.push('=== FILTERED ERROR/EXCEPTION LINES ===');
      relevantLines.push(...matching.slice(-100));
    }

    const outputText = relevantLines.join('\n').substring(0, 15000);

    console.log('=== EXTRACTED TEXT ===');
    console.log(outputText);

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
          error: outputText
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
