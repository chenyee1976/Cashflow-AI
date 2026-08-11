const SUPABASE_URL = process.env.SUPABASE_URL || 'https://wdvkkxczjphebrawhyqe.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndkdmtreGN6anBoZWJyYXdoeXFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0MjUwMTQsImV4cCI6MjEwMjAwMTAxNH0.mzQ8QToUFb_1I4qpbQVHPqIaOHpoiIf4oY_76wcqkbs';

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
          const details = item.details || {};
          rows.push({
            event_type: item.type || 'event',
            event_name: item.name || 'unknown_event',
            user_id: details.userId || null,
            user_email: details.userEmail || details.email || null,
            ip_address: clientIp,
            platform: details.platform || null,
            details: details,
            client_timestamp: item.timestamp || null,
            server_timestamp: new Date().toISOString(),
          });
        }

        if (rows.length > 0) {
          const response = await fetch(`${SUPABASE_URL}/rest/v1/activity_logs`, {
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
            console.error('Supabase insert error:', errText);
            return res.status(500).json({ error: 'Failed to store logs', detail: errText });
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
        `${SUPABASE_URL}/rest/v1/activity_logs?order=server_timestamp.desc&limit=2000`,
        {
          headers: {
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          },
        }
      );

      if (!response.ok) {
        const errText = await response.text();
        return res.status(500).json({ error: 'Failed to fetch logs', detail: errText });
      }

      const rows = await response.json();

      // Map back to the original format expected by the Flutter app
      const logs = rows.map(row => ({
        type: row.event_type,
        name: row.event_name,
        timestamp: row.client_timestamp,
        serverTimestamp: row.server_timestamp,
        details: {
          ...(row.details || {}),
          userId: row.user_id || (row.details || {}).userId,
          userEmail: row.user_email || (row.details || {}).userEmail,
          ipAddress: row.ip_address,
          platform: row.platform || (row.details || {}).platform,
        },
      }));

      return res.status(200).json(logs);
    } catch (e) {
      return res.status(500).json({ error: e.toString() });
    }
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
