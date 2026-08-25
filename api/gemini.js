// Vercel Serverless Function Proxy for Google Gemini API (Supports Auto-Fallback & Header Sanitization)

export const config = {
  api: {
    bodyParser: {
      sizeLimit: '50mb',
    },
  },
};

module.exports = async (req, res) => {
  // CORS Headers for Flutter Web
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, x-gemini-key');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // 1. Get Gemini API key from backend environment variable or custom header fallback
  let rawKey = (process.env.GEMINI_API_KEY || req.headers['x-gemini-key'] || '').trim();
  const apiKey = rawKey.replace(/^\uFEFF/, '').replace(/[^\x00-\x7F]/g, '').trim();

  if (!apiKey) {
    return res.status(500).json({
      error: 'GEMINI_API_KEY environment variable is missing or invalid on Vercel backend.'
    });
  }

  // 2. Handle GET /api/gemini
  if (req.method === 'GET') {
    if (req.query.action === 'listModels') {
      try {
        const listRes = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`);
        const listData = await listRes.json();
        return res.status(listRes.status).json(listData);
      } catch (err) {
        return res.status(500).json({ error: 'Failed to list models', details: err.message });
      }
    }
    if (req.query.action === 'test') {
      const testModel = req.query.model || 'gemini-2.5-flash';
      try {
        const testRes = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${testModel}:generateContent`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: JSON.stringify({ contents: [{ parts: [{ text: 'Say OK' }] }] }),
        });
        const testText = await testRes.text();
        return res.status(testRes.status).send(testText);
      } catch (err) {
        return res.status(500).json({ error: err.message });
      }
    }
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  try {
    const body = typeof req.body === 'string' ? req.body : JSON.stringify(req.body || {});
    const requestedModel = req.query.model || 'gemini-2.5-flash';

    // Primary supported active models in priority order
    const priorityModels = [
      requestedModel,
      'gemini-3.6-flash',
      'gemini-3.5-flash',
      'gemini-3.7-flash',
      'gemini-3.5-flash-lite',
      'gemini-flash-latest',
    ];
    const uniqueModels = [...new Set(priorityModels)];

    let lastErrorResponse = null;
    let lastStatus = 500;

    for (const model of uniqueModels) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 25000); // 25s per model attempt

        const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
        const response = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: body,
          signal: controller.signal,
        });
        clearTimeout(timeoutId);

        const responseText = await response.text();
        lastStatus = response.status;

        if (response.ok) {
          res.status(200).setHeader('Content-Type', 'application/json');
          return res.send(responseText);
        }

        console.warn(`Model ${model} returned ${response.status}: ${responseText.slice(0, 200)}`);
        lastErrorResponse = responseText;
      } catch (err) {
        console.error(`Model ${model} fetch exception:`, err);
        lastErrorResponse = JSON.stringify({ error: err.message });
      }
    }

    res.status(lastStatus).setHeader('Content-Type', 'application/json');
    return res.send(lastErrorResponse || JSON.stringify({ error: 'All Gemini models failed' }));

  } catch (e) {
    console.error('Proxy error:', e);
    return res.status(500).json({ error: 'Proxy Request Failed', details: e.message || e.toString() });
  }
};
