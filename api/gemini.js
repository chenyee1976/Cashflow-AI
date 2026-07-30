// Vercel Serverless Function Proxy for Google Gemini API (Supports new AQ.Ab8... Auth Keys)

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
    const model = req.query.model || 'gemini-2.0-flash';

    // Target Google Gemini REST Endpoint using x-goog-api-key header (required for new AQ... Auth Keys)
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      body: body,
    });

    const responseData = await response.text();

    res.status(response.status).setHeader('Content-Type', 'application/json');
    return res.send(responseData);

  } catch (e) {
    console.error('Proxy error:', e);
    return res.status(500).json({ error: 'Proxy Request Failed', details: e.message || e.toString() });
  }
};
