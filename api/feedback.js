const https = require('https');

const FEEDBACK_ENDPOINT = 'https://jsonblob.com/api/jsonBlob/019fcb0d-a129-7247-a603-e4411cb9c647';

function fetchCloudFeedback() {
  return new Promise((resolve) => {
    const req = https.request(FEEDBACK_ENDPOINT, {
      method: 'GET',
      headers: { 'Accept': 'application/json' }
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed && Array.isArray(parsed.items)) {
            resolve(parsed.items);
          } else {
            resolve([]);
          }
        } catch (_) {
          resolve([]);
        }
      });
    });
    req.on('error', () => resolve([]));
    req.end();
  });
}

function saveCloudFeedback(items) {
  return new Promise((resolve) => {
    try {
      const payload = JSON.stringify({ items });
      const req = https.request(FEEDBACK_ENDPOINT, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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

        const incomingItems = Array.isArray(body) ? body : [body];
        for (const item of incomingItems) {
          if (!item) continue;
          const newEntry = {
            ...item,
            serverTimestamp: new Date().toISOString(),
          };
          const key = item.id || `${item.timestamp || Date.now()}`;
          existingMap.set(key, newEntry);
        }

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
