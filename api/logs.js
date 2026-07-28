// Central Activity & Error Logs API for CashFlow AI Beta Testers
let memoryLogs = [];

module.exports = (req, res) => {
  // CORS Headers for Flutter Web
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
        memoryLogs.unshift({
          ...body,
          serverTimestamp: new Date().toISOString(),
        });
        if (memoryLogs.length > 500) {
          memoryLogs = memoryLogs.slice(0, 500);
        }
      }
      return res.status(200).json({ success: true, count: memoryLogs.length });
    } catch (e) {
      return res.status(400).json({ error: e.toString() });
    }
  }

  if (req.method === 'GET') {
    return res.status(200).json(memoryLogs);
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
