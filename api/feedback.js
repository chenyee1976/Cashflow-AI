const SUPABASE_URL = process.env.SUPABASE_URL || 'https://damkiewubedfkajbvoeo.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhbWtpZXd1YmVkZmthamJ2b2VvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcyODIyOTgsImV4cCI6MjEwMjg1ODI5OH0.DumsVaIE0R0qJax221CieE8_ldi3YMchybZome2c1G4';

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method === 'POST') {
    try {
      const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
      if (body) {
        const clientIp = req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket?.remoteAddress || 'Unknown IP';
        const incomingItems = Array.isArray(body) ? body : [body];

        const rows = [];
        for (const item of incomingItems) {
          if (!item) continue;
          rows.push({
            feedback_id: item.id || `fb_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
            user_id: item.userId || null,
            user_email: item.userEmail || null,
            ip_address: clientIp,
            feedback_type: item.feedbackType || 'General Feedback',
            message: item.message || '',
            platform: item.platform || null,
            attachment_name: item.attachmentName || null,
            attachment_base64: item.attachmentBase64 || null,
            client_timestamp: item.timestamp || null,
            server_timestamp: new Date().toISOString(),
          });
        }

        if (rows.length > 0) {
          const response = await fetch(`${SUPABASE_URL}/rest/v1/user_feedback`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'apikey': SUPABASE_ANON_KEY,
              'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
              'Prefer': 'return=minimal',
            },
            body: JSON.stringify(rows),
          });

          if (!response.ok) {
            const errText = await response.text();
            console.error('Supabase feedback insert error:', errText);
            return res.status(500).json({ error: 'Failed to store feedback', detail: errText });
          }
        }

        return res.status(200).json({ success: true, count: rows.length });
      }
      return res.status(200).json({ success: true });
    } catch (e) {
      return res.status(400).json({ error: e.toString() });
    }
  }

  if (req.method === 'GET') {
    try {
      const response = await fetch(
        `${SUPABASE_URL}/rest/v1/user_feedback?order=server_timestamp.desc&limit=500`,
        {
          headers: {
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          },
        }
      );

      if (!response.ok) {
        const errText = await response.text();
        return res.status(500).json({ error: 'Failed to fetch feedback', detail: errText });
      }

      const rows = await response.json();

      // Map back to the original format expected by the Flutter app
      const feedback = rows.map(row => ({
        id: row.feedback_id,
        userId: row.user_id,
        userEmail: row.user_email,
        feedbackType: row.feedback_type,
        message: row.message,
        timestamp: row.client_timestamp,
        serverTimestamp: row.server_timestamp,
        platform: row.platform,
        attachmentName: row.attachment_name,
        attachmentBase64: row.attachment_base64,
        ipAddress: row.ip_address,
      }));

      return res.status(200).json(feedback);
    } catch (e) {
      return res.status(500).json({ error: e.toString() });
    }
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
