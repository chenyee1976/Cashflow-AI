const https = require('https');

// Central Activity & Error Logs API for CashFlow AI Beta Testers with global persistent KV sync
let memoryLogs = [];

const KV_URL = 'https://kvdb.io/A84NqQ12999kksx882a177/sgcashflow_logs';

function fetchFromKv() {
  return new Promise((resolve) => {
    https.get(KV_URL, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (Array.isArray(parsed)) resolve(parsed);
          else resolve([]);
        } catch (_) {
          resolve([]);
        }
      });
    }).on('error', () => resolve([]));
  });
}

function saveToKv(data) {
  return new Promise((resolve) => {
    try {
      const url = new URL(KV_URL);
      const payload = JSON.stringify(data);
      const req = https.request({
        hostname: url.hostname,
        path: url.pathname,
        method: 'POST',
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
        const kvList = await fetchFromKv();
        const existingMap = new Map();
        for (const item of kvList) {
          if (item && item.timestamp) {
            const key = `${item.name || 'evt'}_${item.timestamp}`;
            existingMap.set(key, item);
          }
        }

        const newEntry = {
          ...body,
          serverTimestamp: new Date().toISOString(),
        };
        const entryKey = `${newEntry.name || 'evt'}_${newEntry.timestamp || Date.now()}`;
        existingMap.set(entryKey, newEntry);

        const updatedList = Array.from(existingMap.values());
        updatedList.sort((a, b) => new Date(b.timestamp || b.serverTimestamp || 0) - new Date(a.timestamp || a.serverTimestamp || 0));

        const finalLogs = updatedList.slice(0, 500);
        memoryLogs = finalLogs;
        await saveToKv(finalLogs);
      }
      return res.status(200).json({ success: true, count: memoryLogs.length });
    } catch (e) {
      return res.status(400).json({ error: e.toString() });
    }
  }

  if (req.method === 'GET') {
    const kvList = await fetchFromKv();
    const map = new Map();
    for (const item of memoryLogs) {
      if (item && item.timestamp) map.set(`${item.name}_${item.timestamp}`, item);
    }
    for (const item of kvList) {
      if (item && item.timestamp) map.set(`${item.name}_${item.timestamp}`, item);
    }
    const merged = Array.from(map.values());
    merged.sort((a, b) => new Date(b.timestamp || b.serverTimestamp || 0) - new Date(a.timestamp || a.serverTimestamp || 0));
    return res.status(200).json(merged);
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
