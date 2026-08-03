const https = require('https');

const LOGS_ENDPOINT = 'https://jsonblob.com/api/jsonBlob/019fc580-d01f-7aa3-a883-60d62aa3603b';

function fetchCloudLogs() {
  return new Promise((resolve) => {
    const req = https.request(LOGS_ENDPOINT, {
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

function saveCloudLogs(items) {
  return new Promise((resolve) => {
    try {
      const payload = JSON.stringify({ items });
      const req = https.request(LOGS_ENDPOINT, {
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
        const cloudItems = await fetchCloudLogs();
        const existingMap = new Map();
        for (const item of cloudItems) {
          if (item && item.timestamp) {
            const key = `${item.name || 'evt'}_${item.timestamp}`;
            existingMap.set(key, item);
          }
        }

        const incomingItems = Array.isArray(body) ? body : [body];
        for (const item of incomingItems) {
          if (!item) continue;
          const newEntry = {
            ...item,
            serverTimestamp: new Date().toISOString(),
          };
          const entryKey = `${newEntry.name || 'evt'}_${newEntry.timestamp || Date.now()}`;
          existingMap.set(entryKey, newEntry);
        }

        const updatedList = Array.from(existingMap.values());
        updatedList.sort((a, b) => new Date(b.timestamp || b.serverTimestamp || 0) - new Date(a.timestamp || a.serverTimestamp || 0));

        const trimmed = updatedList.slice(0, 500);
        await saveCloudLogs(trimmed);
        return res.status(200).json({ success: true, count: trimmed.length });
      }
      return res.status(200).json({ success: true });
    } catch (e) {
      return res.status(400).json({ error: e.toString() });
    }
  }

  if (req.method === 'GET') {
    const cloudItems = await fetchCloudLogs();
    return res.status(200).json(cloudItems);
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
