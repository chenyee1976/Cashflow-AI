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

          const r2 = (v) => Math.round((Number(v) || 0) * 100) / 100;

          return {
            user_hash: item.userHash || item.user_hash || 'anonymous',
            month_year: item.monthYear || item.month_year || new Date().toISOString().substring(0, 7),
            environment: item.environment || defaultEnvironment,
            bank_statements_count: item.bankStatementsCount || item.bank_statements_count || 0,
            card_statements_count: item.cardStatementsCount || item.card_statements_count || 0,
            net_cash_position: r2(item.netCashPosition ?? item.net_cash_position),
            net_cash_flow: r2(item.netCashFlow ?? item.net_cash_flow),
            monthly_income: r2(item.monthlyIncome ?? item.monthly_income),
            monthly_expenses: r2(item.monthlyExpenses ?? item.monthly_expenses),
            monthly_transfers: r2(item.monthlyTransfers ?? item.monthly_transfers),
            total_miles_balance: r2(item.totalMilesBalance ?? item.total_miles_balance),
            total_cashback_earned: r2(item.totalCashbackEarned ?? item.total_cashback_earned),

            // Dedicated Income columns
            income_salary: r2(item.incomeSalary ?? item.income_salary ?? inc['Salary'] ?? inc['salary']),
            income_interest: r2(item.incomeInterest ?? item.income_interest ?? inc['Interest'] ?? inc['interest']),
            income_investments: r2(item.incomeInvestments ?? item.income_investments ?? inc['Investments'] ?? inc['investments']),
            income_dividends: r2(item.incomeDividends ?? item.income_dividends ?? inc['Dividends'] ?? inc['dividends']),
            income_other: r2(item.incomeOther ?? item.income_other ?? inc['Other Income'] ?? inc['Other']),

            // Dedicated Expense columns (negative values)
            expense_groceries: r2(item.expenseGroceries ?? item.expense_groceries ?? (exp['Groceries'] ? -Math.abs(exp['Groceries']) : 0.0)),
            expense_transport: r2(item.expenseTransport ?? item.expense_transport ?? (exp['Transport'] ? -Math.abs(exp['Transport']) : 0.0)),
            expense_shopping: r2(item.expenseShopping ?? item.expense_shopping ?? (exp['Shopping'] ? -Math.abs(exp['Shopping']) : 0.0)),
            expense_dining: r2(item.expenseDining ?? item.expense_dining ?? (exp['Dining'] ? -Math.abs(exp['Dining']) : 0.0)),
            expense_education: r2(item.expenseEducation ?? item.expense_education ?? (exp['Education'] ? -Math.abs(exp['Education']) : 0.0)),
            expense_utilities: r2(item.expenseUtilities ?? item.expense_utilities ?? (exp['Utilities'] ? -Math.abs(exp['Utilities']) : 0.0)),
            expense_investments: r2(item.expenseInvestments ?? item.expense_investments ?? (exp['Investments'] ? -Math.abs(exp['Investments']) : 0.0)),
            expense_tax: r2(item.expenseTax ?? item.expense_tax ?? (exp['Tax'] ? -Math.abs(exp['Tax']) : 0.0)),
            expense_healthcare: r2(item.expenseHealthcare ?? item.expense_healthcare ?? (exp['Healthcare'] ? -Math.abs(exp['Healthcare']) : 0.0)),
            expense_petrol: r2(item.expensePetrol ?? item.expense_petrol ?? (exp['Petrol'] ? -Math.abs(exp['Petrol']) : 0.0)),
            expense_entertainment: r2(item.expenseEntertainment ?? item.expense_entertainment ?? (exp['Entertainment'] ? -Math.abs(exp['Entertainment']) : 0.0)),
            expense_other: r2(item.expenseOther ?? item.expense_other ?? (exp['Other expenses'] || exp['Other'] ? -Math.abs(exp['Other expenses'] || exp['Other']) : 0.0)),

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
