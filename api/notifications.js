// Central Notifications API for CashFlow AI Beta Testers
let notifications = [
  {
    id: 'welcome_beta_1',
    title: '🚀 Welcome to SGCashFlowAI Beta!',
    message: 'Thank you for testing CashFlow AI! You can upload your MariBank, DBS, UOB, OCBC, Citi bank and credit card statements to analyze your cashflow, card rewards, and expense tracking.',
    publishedAt: '2026-07-30T17:06:00.000Z',
    author: 'SGCashFlowAI Team',
  },
  {
    id: 'privacy_beta_testers',
    title: 'Current data privacy for beta testers',
    message: `1. 🛡️ Financial Data is 100% Local (Private to the Tester's Device)
Uploaded Statements (PDFs / Images), Extracted Transactions, Account Balances, Credit Card Details, and Income/Expense Figures are saved ONLY on the beta tester's local phone or computer (inside their browser's encrypted IndexedDB storage).
Admin will NOT be able to view their actual bank statements, transaction amounts, balances, or card details.
This guarantees 100% compliance with Singapore's PDPA privacy laws, so beta testers can comfortably test the app with real statements without worrying about anyone seeing their financial numbers.

2. 📊 What Admin CAN See (Beta Activity Logs)
While Admin cannot see their private financial figures, your Admin Mode allows Admin to track their engagement via the Activity Logs screen:
Tester Identity: First Name, Last Name, and Email (entered during their first login popup).
Action Timeline: Event logs such as User Onboarded, Uploaded Bank Statement, Uploaded Credit Card Statement, Viewed Cash Flow Screen, Timestamps & Log Counts.`,
    publishedAt: '2026-07-29T22:40:00.000Z',
    author: 'SGCashFlowAI Admin',
  },
  {
    id: 'list_of_banks_tested',
    title: 'List of banks',
    message: `We have tested the following bank statements and credit card statements so far on the app.
As of 29 July 2026

Bank statements:
1. POSB bank statements
2. OCBC bank statements
3. MariBank bank statements
4. Chocolate Finance bank statements
5. CIMB bank statements
6. Citibank bank statements
7. SingFinance bank statements

Credit card statements:
1. Citibank PremierMiles
2. OCBC 90n
3. MariBank credit card
4. Maybank Family and Friends card`,
    publishedAt: '2026-07-29T21:46:00.000Z',
    author: 'SGCashFlowAI Admin',
  },
  {
    id: 'welcome_beta_testers_intro',
    title: 'Welcome Beta Testers',
    message: `Thanks for agreeing to help with testing this app.

Below are the functionalities of the app that you can test:
1. Upload of bank statements to populate your total cash positions and income and expenses as of each month end
2. Upload of credit card statements to populate your expenses and rewards as of each credit card statement
3. Total view of cash position for each month end, Total income and expenses of each month end
4. Total view of cashback or miles earned from your credit card statements
5. Tracking of total miles that you have earned`,
    publishedAt: '2026-07-29T21:42:00.000Z',
    author: 'SGCashFlowAI Admin',
  },
  {
    id: 'system_update_2',
    title: '📢 System Update: Multi-Bank Statement OCR & PDF Parsing',
    message: 'We have updated our AI statement parser with higher accuracy for DBS, MariBank, UOB, OCBC, and Citibank statements.',
    publishedAt: '2026-07-28T14:30:00.000Z',
    author: 'SGCashFlowAI Admin',
  },
  {
    id: 'pdpa_privacy_3',
    title: '🛡️ PDPA & Privacy Policy Update',
    message: 'Our Terms of Service, PDPA Privacy Policy, and AI Analytics controls are now available in Account Settings and Support.',
    publishedAt: '2026-07-28T18:00:00.000Z',
    author: 'SGCashFlowAI L&C',
  },
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
