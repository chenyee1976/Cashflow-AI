// Central Notifications API for CashFlow AI Beta Testers
let notifications = [
  {
    id: 'welcome_beta_1',
    title: '🚀 Welcome to SGCashFlowAI Beta!',
    message: 'Thank you for testing CashFlow AI! You can upload your MariBank, DBS, UOB, OCBC, Citi bank and credit card statements to analyze your cashflow, card rewards, and expense tracking.',
    publishedAt: new Date().toISOString(),
    author: 'SGCashFlowAI Team',
  }
];

module.exports = (req, res) => {
  // CORS Headers for Flutter Web
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Publish new notification
  if (req.method === 'POST') {
    try {
      const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
      if (body && body.title && body.message) {
        const newNotif = {
          id: body.id || Date.now().toString(),
          title: body.title,
          message: body.message,
          publishedAt: body.publishedAt || new Date().toISOString(),
          author: body.author || 'SGCashFlowAI Admin',
        };
        notifications.unshift(newNotif);
        return res.status(200).json({ success: true, notification: newNotif });
      }
      return res.status(400).json({ error: 'Missing title or message' });
    } catch (e) {
      return res.status(400).json({ error: e.toString() });
    }
  }

  // Delete notification
  if (req.method === 'DELETE') {
    try {
      const id = req.query.id || (req.body && req.body.id);
      if (id) {
        notifications = notifications.filter((n) => n.id !== id);
        return res.status(200).json({ success: true, count: notifications.length });
      }
      return res.status(400).json({ error: 'Missing notification id' });
    } catch (e) {
      return res.status(400).json({ error: e.toString() });
    }
  }

  // Fetch notifications
  if (req.method === 'GET') {
    return res.status(200).json(notifications);
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
