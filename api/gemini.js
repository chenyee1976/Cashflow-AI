// Vercel Serverless Function Proxy for Google Gemini API
const https = require('https');

module.exports = async (req, res) => {
  // CORS Headers for Flutter Web
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-gemini-key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Get Gemini API key from backend environment variable or custom header fallback
  const apiKey = process.env.GEMINI_API_KEY || req.headers['x-gemini-key'];

  if (!apiKey) {
    return res.status(500).json({
      error: 'GEMINI_API_KEY environment variable is missing on Vercel backend.'
    });
  }

  try {
    const body = typeof req.body === 'string' ? req.body : JSON.stringify(req.body || {});
    const model = req.query.model || 'gemini-1.5-flash';
    
    // Target Google Gemini REST Endpoint
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    };

    const proxyReq = https.request(options, (proxyRes) => {
      let responseData = '';
      proxyRes.on('data', (chunk) => {
        responseData += chunk;
      });
      proxyRes.on('end', () => {
        res.status(proxyRes.statusCode).setHeader('Content-Type', 'application/json');
        return res.send(responseData);
      });
    });

    proxyReq.on('error', (err) => {
      return res.status(500).json({ error: 'Proxy Request Failed', details: err.message });
    });

    proxyReq.write(body);
    proxyReq.end();

  } catch (e) {
    return res.status(500).json({ error: e.toString() });
  }
};
