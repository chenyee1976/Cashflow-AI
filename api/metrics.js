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

        const rows = incomingItems.map(item => ({
          user_hash: item.userHash || 'anonymous',
          month_year: item.monthYear || new Date().toISOString().substring(0, 7),
          bank_statements_count: item.bankStatementsCount || 0,
          card_statements_count: item.cardStatementsCount || 0,
          net_cash_position: item.netCashPosition || 0.0,
          monthly_income: item.monthlyIncome || 0.0,
          monthly_expenses: item.monthlyExpenses || 0.0,
          category_breakdown: item.categoryBreakdown || {},
          total_miles_balance: item.totalMilesBalance || 0.0,
          total_cashback_earned: item.totalCashbackEarned || 0.0,
          manual_input_count: item.manualInputCount || 0,
          voice_upload_count: item.voiceUploadCount || 0,
          report_view_count: item.reportViewCount || 0,
          report_download_count: item.reportDownloadCount || 0,
          last_synced_at: new Date().toISOString(),
        }));

        const response = await fetch(`${SUPABASE_URL}/rest/v1/monthly_aggregate_metrics`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
            'Prefer': 'resolution=merge-duplicates',
          },
          body: JSON.stringify(rows),
        });

        if (!response.ok) {
          const errText = await response.text();
          console.error('Supabase aggregate insert error:', errText);
          return res.status(500).json({ error: 'Failed to store aggregate metrics', detail: errText });
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
        `${SUPABASE_URL}/rest/v1/monthly_aggregate_metrics?order=month_year.desc&limit=1000`,
        {
          headers: {
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          },
        }
      );

      if (!response.ok) {
        const errText = await response.text();
        return res.status(500).json({ error: 'Failed to fetch aggregate metrics', detail: errText });
      }

      const rows = await response.json();
      return res.status(200).json(rows);
    } catch (e) {
      return res.status(500).json({ error: e.toString() });
    }
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
