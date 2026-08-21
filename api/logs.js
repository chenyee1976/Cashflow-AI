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

        // Handle backfill: update unknown_user entries with real identity
        if (body.action === 'backfill_identity') {
          const { userId, userEmail } = body;
          if (userId && userEmail) {
            const oneHourAgo = new Date(Date.now() - 3600000).toISOString();
            const updateResponse = await fetch(
              `${SUPABASE_URL}/rest/v1/activity_logs?user_id=eq.unknown_user&ip_address=eq.${encodeURIComponent(clientIp)}&server_timestamp=gte.${encodeURIComponent(oneHourAgo)}`,
              {
                method: 'PATCH',
                headers: {
                  'Content-Type': 'application/json',
                  'apikey': SUPABASE_ANON_KEY,
                  'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                  'Prefer': 'return=minimal',
                },
                body: JSON.stringify({
                  user_id: userId,
                  user_email: userEmail,
                }),
              }
            );
            return res.status(200).json({ success: true, action: 'backfill' });
          }
          return res.status(200).json({ success: true, action: 'backfill', skipped: true });
        }

        const incomingItems = Array.isArray(body) ? body : [body];

        const host = req.headers['host'] || req.headers['x-forwarded-host'] || 'web';
        const environment = host.includes('web-kappa') ? 'Beta (web-kappa)' : (host.includes('sgcashflowai') ? 'Production (sgcashflowai)' : host);

        const rows = [];
        for (const item of incomingItems) {
          if (!item) continue;
          const details = item.details || {};
          const email = (details.userEmail && details.userEmail.includes('@')) 
            ? details.userEmail 
            : ((details.email && details.email.includes('@')) ? details.email : null);
          const userId = (details.userId && details.userId !== 'unknown_user') ? details.userId : null;

          rows.push({
            event_type: item.type || 'event',
            event_name: item.name || 'unknown_event',
            user_id: userId,
            user_email: email,
            ip_address: clientIp,
            platform: environment,
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

          // Also upsert into registered_users table if user_registered or valid email is present
          for (const item of incomingItems) {
            const details = item.details || {};
            const email = (details.userEmail && details.userEmail.includes('@')) 
              ? details.userEmail 
              : ((details.email && details.email.includes('@')) ? details.email : null);
            const userId = (details.userId && details.userId !== 'unknown_user') ? details.userId : null;

            if (email) {
              const nowIso = new Date().toISOString();
              // First try to update existing user by email
              const patchRes = await fetch(
                `${SUPABASE_URL}/rest/v1/registered_users?email=eq.${encodeURIComponent(email)}`,
                {
                  method: 'PATCH',
                  headers: {
                    'Content-Type': 'application/json',
                    'apikey': SUPABASE_ANON_KEY,
                    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                    'Prefer': 'return=representation',
                  },
                  body: JSON.stringify({
                    last_login_at: nowIso,
                    platform: environment,
                    display_name: details.displayName || email,
                    first_name: details.firstName || undefined,
                    last_name: details.lastName || undefined,
                  }),
                }
              );

              const patchedRows = patchRes.ok ? await patchRes.json() : [];
              if (!Array.isArray(patchedRows) || patchedRows.length === 0) {
                // If not found, insert new row
                await fetch(`${SUPABASE_URL}/rest/v1/registered_users`, {
                  method: 'POST',
                  headers: {
                    'Content-Type': 'application/json',
                    'apikey': SUPABASE_ANON_KEY,
                    'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                  },
                  body: JSON.stringify({
                    id: userId || `user_${email.replace(/[^a-zA-Z0-9]/g, '_')}`,
                    email: email,
                    display_name: details.displayName || email,
                    first_name: details.firstName || null,
                    last_name: details.lastName || null,
                    google_id: details.googleId || null,
                    photo_url: details.photoUrl || null,
                    platform: environment,
                    registered_at: nowIso,
                    last_login_at: nowIso,
                  }),
                });
              }
            }
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
