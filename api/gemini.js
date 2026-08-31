// Vercel Serverless Function Proxy for Google Gemini API (Supports Auto-Fallback & Fast Extraction)

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
      const testModel = req.query.model || 'gemini-3.6-flash';
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
    const requestedModel = req.query.model;

    // Verified-working models ordered by reliability and speed (tested 2026-08-31):
    // gemini-3.6-flash: 200 OK in 2.2s | gemini-3.5-flash: 200 OK in 9.5s | gemini-3.7-flash: works but rate-limited
    const priorityModels = [
      ...(requestedModel ? [requestedModel] : []),
      'gemini-3.6-flash',
      'gemini-3.5-flash',
      'gemini-3.7-flash',
    ];
    const uniqueModels = [...new Set(priorityModels)];

    let lastErrorResponse = null;
    let lastStatus = 500;
    const startTime = Date.now();
    const TOTAL_BUDGET_MS = 58000; // Stay within Vercel Free 60s limit

    for (let i = 0; i < uniqueModels.length; i++) {
      const elapsed = Date.now() - startTime;
      if (elapsed >= TOTAL_BUDGET_MS) break;
      const model = uniqueModels[i];
      try {
        // Give the first model nearly the full budget (55s) since large PDFs need 30-50s.
        // Subsequent models get whatever time remains.
        const remainingMs = TOTAL_BUDGET_MS - (Date.now() - startTime);
        const perAttemptTimeout = i === 0
          ? Math.min(55000, remainingMs - 1000)
          : Math.min(55000, Math.max(5000, remainingMs - 1000));
        if (perAttemptTimeout < 5000) break; // Not enough time for another attempt

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), perAttemptTimeout);

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

        // On 429 rate limit, brief pause only if enough time remains for next model
        if (response.status === 429) {
          const pauseMs = 2000;
          const remaining = TOTAL_BUDGET_MS - (Date.now() - startTime);
          if (remaining > pauseMs + 8000) {
            await new Promise(r => setTimeout(r, pauseMs));
          }
        }
      } catch (err) {
        console.error(`Model ${model} fetch exception:`, err);
        lastErrorResponse = JSON.stringify({ error: err.message });
      }
    }

    res.status(lastStatus).setHeader('Content-Type', 'application/json');
    return res.send(lastErrorResponse || JSON.stringify({ error: 'All Gemini models failed or timed out' }));

  } catch (e) {
    console.error('Proxy error:', e);
    return res.status(500).json({ error: 'Proxy Request Failed', details: e.message || e.toString() });
  }
};
