const SUPABASE_URL = process.env.SUPABASE_URL || 'https://damkiewubedfkajbvoeo.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhbWtpZXd1YmVkZmthamJ2b2VvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcyODIyOTgsImV4cCI6MjEwMjg1ODI5OH0.DumsVaIE0R0qJax221CieE8_ldi3YMchybZome2c1G4';

module.exports = async (req, res) => {
  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_logs?select=id&limit=1`, {
      method: 'GET',
      headers: {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
      },
    });

    if (response.ok) {
      return res.status(200).json({ status: 'ok', message: 'Supabase keep-alive ping successful', timestamp: new Date().toISOString() });
    } else {
      const errText = await response.text();
      return res.status(response.status).json({ error: 'Supabase ping failed', detail: errText });
    }
  } catch (err) {
    return res.status(500).json({ error: 'Cron execution exception', detail: err.message });
  }
};
