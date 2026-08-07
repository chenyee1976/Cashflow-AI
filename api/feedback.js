let inMemoryFeedback = [];

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

        for (const item of incomingItems) {
          if (!item) continue;
          const newEntry = {
            ...item,
            ipAddress: clientIp,
            serverTimestamp: new Date().toISOString(),
          };
          inMemoryFeedback.unshift(newEntry);
        }

        // Deduplicate & trim
        const map = new Map();
        for (const item of inMemoryFeedback) {
          const key = item.id || `${item.timestamp || item.serverTimestamp}`;
          if (!map.has(key)) map.set(key, item);
        }
        inMemoryFeedback = Array.from(map.values()).slice(0, 500);

        return res.status(200).json({ success: true, count: inMemoryFeedback.length });
      }
      return res.status(200).json({ success: true });
    } catch (e) {
      return res.status(400).json({ error: e.toString() });
    }
  }

  if (req.method === 'GET') {
    return res.status(200).json(inMemoryFeedback);
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
