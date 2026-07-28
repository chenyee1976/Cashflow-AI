// Central Feedback API for CashFlow AI Beta Testers
let memoryFeedback = [];

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
        memoryFeedback.unshift({
          ...body,
          serverTimestamp: new Date().toISOString(),
        });
        if (memoryFeedback.length > 200) {
          memoryFeedback = memoryFeedback.slice(0, 200);
        }
      }
      return res.status(200).json({ success: true, count: memoryFeedback.length });
    } catch (e) {
      return res.status(400).json({ error: e.toString() });
    }
  }

  if (req.method === 'GET') {
    return res.status(200).json(memoryFeedback);
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
