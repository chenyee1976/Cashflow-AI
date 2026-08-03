const https = require('https');

const FEEDBACK_ENDPOINT = 'https://api.restful-api.dev/objects/ff8081819f7e10ae019fc55ab9e864fd';

function fetchCloudFeedback() {
  return new Promise((resolve) => {
    https.get(FEEDBACK_ENDPOINT, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed && parsed.data && Array.isArray(parsed.data.items)) {
            resolve(parsed.data.items);
          } else {
            resolve([]);
          }
        } catch (_) {
          resolve([]);
        }
      });
    }).on('error', () => resolve([]));
  });
}

function saveCloudFeedback(items) {
  return new Promise((resolve) => {
    try {
      const payload = JSON.stringify({
        name: 'sgcashflow_global_feedback',
        data: { items }
      });
      const req = https.request(FEEDBACK_ENDPOINT, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload),
        },
      }, () => resolve(true));
      req.on('error', () => resolve(false));
      req.write(payload);
      req.end();
    } catch (_) {
      resolve(false);
    }
  });
}

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
        const cloudItems = await fetchCloudFeedback();
        const existingMap = new Map();
        for (const item of cloudItems) {
          if (item && item.id) existingMap.set(item.id, item);
        }

        const newEntry = {
          ...body,
          serverTimestamp: new Date().toISOString(),
        };
        existingMap.set(newEntry.id || Date.now().toString(), newEntry);

        const updatedList = Array.from(existingMap.values());
        updatedList.sort((a, b) => new Date(b.timestamp || b.serverTimestamp || 0) - new Date(a.timestamp || a.serverTimestamp || 0));

        await saveCloudFeedback(updatedList);
        return res.status(200).json({ success: true, count: updatedList.length });
      }
      return res.status(200).json({ success: true });
    } catch (e) {
      return res.status(400).json({ error: e.toString() });
    }
  }

  if (req.method === 'GET') {
    const cloudItems = await fetchCloudFeedback();
    return res.status(200).json(cloudItems);
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
