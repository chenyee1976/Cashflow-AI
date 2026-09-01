const SUPABASE_URL = process.env.SUPABASE_URL || 'https://damkiewubedfkajbvoeo.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhbWtpZXd1YmVkZmthamJ2b2VvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcyODIyOTgsImV4cCI6MjEwMjg1ODI5OH0.DumsVaIE0R0qJax221CieE8_ldi3YMchybZome2c1G4';

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
        const incomingItems = Array.isArray(body) ? body : [body];

        const host = req.headers['host'] || req.headers['x-forwarded-host'] || '';
        const defaultEnvironment = host.includes('web-kappa') 
          ? 'Preview (web-kappa)' 
          : (host.includes('sgcashflowai') ? 'Live / Production (sgcashflowai)' : (host.includes('localhost') ? 'Localhost' : 'Live / Production'));

        const rows = incomingItems.map(item => {
          const cat = item.categoryBreakdown || {};
          const inc = cat.income || {};
          const exp = cat.expenses || {};
          const tel = cat.telemetry || {};

          return {
            user_hash: item.userHash || 'anonymous',
            month_year: item.monthYear || new Date().toISOString().substring(0, 7),
            environment: item.environment || defaultEnvironment,
            bank_statements_count: item.bankStatementsCount || 0,
            card_statements_count: item.cardStatementsCount || 0,
            net_cash_position: item.netCashPosition || 0.0,
            net_cash_flow: item.netCashFlow || 0.0,
            monthly_income: item.monthlyIncome || 0.0,
            monthly_expenses: item.monthlyExpenses || 0.0,
            monthly_transfers: item.monthlyTransfers || 0.0,
            total_miles_balance: item.totalMilesBalance || 0.0,
            total_cashback_earned: item.totalCashbackEarned || 0.0,

            // Dedicated Income columns
            income_salary: item.incomeSalary ?? inc['Salary'] ?? inc['salary'] ?? 0.0,
            income_interest: item.incomeInterest ?? inc['Interest'] ?? inc['interest'] ?? 0.0,
            income_transfers: item.incomeTransfers ?? inc['Transfers'] ?? inc['transfers'] ?? inc['Transfer'] ?? 0.0,
            income_other: item.incomeOther ?? inc['Other'] ?? inc['other'] ?? 0.0,

            // Dedicated Expense columns (negative values)
            expense_groceries: item.expenseGroceries ?? (exp['Groceries'] ? -Math.abs(exp['Groceries']) : 0.0),
            expense_transport: item.expenseTransport ?? (exp['Transport'] ? -Math.abs(exp['Transport']) : 0.0),
            expense_shopping: item.expenseShopping ?? (exp['Shopping'] ? -Math.abs(exp['Shopping']) : 0.0),
            expense_dining: item.expenseDining ?? (exp['Dining'] ? -Math.abs(exp['Dining']) : 0.0),
            expense_education: item.expenseEducation ?? (exp['Education'] ? -Math.abs(exp['Education']) : 0.0),
            expense_utilities: item.expenseUtilities ?? (exp['Utilities'] ? -Math.abs(exp['Utilities']) : 0.0),
            expense_investments: item.expenseInvestments ?? (exp['Investments'] ? -Math.abs(exp['Investments']) : 0.0),
            expense_tax: item.expenseTax ?? (exp['Tax'] ? -Math.abs(exp['Tax']) : 0.0),
            expense_healthcare: item.expenseHealthcare ?? (exp['Healthcare'] ? -Math.abs(exp['Healthcare']) : 0.0),
            expense_petrol: item.expensePetrol ?? (exp['Petrol'] ? -Math.abs(exp['Petrol']) : 0.0),
            expense_entertainment: item.expenseEntertainment ?? (exp['Entertainment'] ? -Math.abs(exp['Entertainment']) : 0.0),
            expense_other: item.expenseOther ?? (exp['Other expenses'] || exp['Other'] ? -Math.abs(exp['Other expenses'] || exp['Other']) : 0.0),

            // Dedicated Telemetry columns
            manual_inputs_count: item.manualInputsCount ?? tel['manual_inputs'] ?? 0,
            voice_uploads_count: item.voiceUploadCount ?? tel['voice_uploads'] ?? 0,
            report_views_count: item.reportViewsCount ?? tel['report_views'] ?? 0,
            report_downloads_count: item.reportDownloadsCount ?? tel['report_downloads'] ?? 0,

            last_synced_at: new Date().toISOString(),
          };
        });

        const response = await fetch(`${SUPABASE_URL}/rest/v1/monthly_aggregate_metrics?on_conflict=user_hash,month_year`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
            'Prefer': 'resolution=merge-duplicates',
          },
          body: JSON.stringify(rows),
        });

        if (!response.ok) {
          const errText = await response.text();
          console.error('Supabase aggregate insert error:', errText);
          return res.status(500).json({ error: 'Failed to store aggregate metrics', detail: errText });
        }

        return res.status(200).json({ success: true, count: rows.length });
      }
      return res.status(200).json({ success: true });
    } catch (e) {
      return res.status(400).json({ error: e.toString() });
    }
  }

  if (req.method === 'GET') {
    try {
      const response = await fetch(
        `${SUPABASE_URL}/rest/v1/monthly_aggregate_metrics?order=month_year.desc&limit=1000`,
        {
          headers: {
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
          },
        }
      );

      if (!response.ok) {
        const errText = await response.text();
        return res.status(500).json({ error: 'Failed to fetch aggregate metrics', detail: errText });
      }

      const rows = await response.json();
      return res.status(200).json(rows);
    } catch (e) {
      return res.status(500).json({ error: e.toString() });
    }
  }

  return res.status(405).json({ error: 'Method Not Allowed' });
};
