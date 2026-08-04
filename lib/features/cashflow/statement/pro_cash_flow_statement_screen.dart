// Updated Pro Cash Flow Statement Screen with Net Savings Rate Tooltip
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/category_enum.dart';
import '../../../data/database/app_database.dart';
import 'cashflow_provider.dart';
import '../../account/account_provider.dart';
import '../../dashboard/dashboard_provider.dart';

class ProCashFlowStatementScreen extends ConsumerStatefulWidget {
  const ProCashFlowStatementScreen({super.key});

  @override
  ConsumerState<ProCashFlowStatementScreen> createState() => _ProCashFlowStatementScreenState();
}

class _ProCashFlowStatementScreenState extends ConsumerState<ProCashFlowStatementScreen> {
  bool _includeBusiness = false;
  String _periodType = 'Month'; // 'Month', 'Quarter', 'YTD'

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final cashFlowAsync = ref.watch(cashFlowScreenProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_SG', symbol: 'S\$');

    return Scaffold(
      backgroundColor: AppColors.proBackground,
      appBar: AppBar(
        backgroundColor: AppColors.proBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.proGoldGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PRO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.proBackground,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Cash Flow Statement',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.proGold),
            tooltip: 'Export Statement PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generating Pro Statement PDF export...'),
                  backgroundColor: AppColors.proPrimary,
                ),
              );
            },
          ),
        ],
      ),
      body: cashFlowAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.proPrimary),
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (state) {
          final txs = state.transactions;
          
          // Define 3 monthly periods: Current Month, 1 Month Ago, 2 Months Ago
          final m0Date = selectedMonth; // Current month
          final m1Date = DateTime(selectedMonth.year, selectedMonth.month - 1); // 1 month ago
          final m2Date = DateTime(selectedMonth.year, selectedMonth.month - 2); // 2 months ago

          final m0Label = DateFormat('MMM yyyy').format(m0Date);
          final m1Label = DateFormat('MMM yyyy').format(m1Date);
          final m2Label = DateFormat('MMM yyyy').format(m2Date);

          // Helper to calculate monthly metrics for a given target month
          Map<String, dynamic> _calcMonthMetrics(DateTime targetMonth) {
            final periodTxs = txs.where((t) {
              final d = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
              return d.year == targetMonth.year && d.month == targetMonth.month;
            }).toList();

            final salary = periodTxs
                .where((t) => t.category == TransactionCategory.incomeSalary.value)
                .fold<double>(0.0, (s, t) => s + t.amount);

            final passive = periodTxs
                .where((t) =>
                    t.category == TransactionCategory.incomeInterest.value ||
                    t.category == TransactionCategory.incomeInvestments.value ||
                    t.category == TransactionCategory.incomeDividends.value)
                .fold<double>(0.0, (s, t) => s + t.amount);

            final totalInc = periodTxs
                .where((t) => TransactionCategory.fromValue(t.category).isIncome && t.category != TransactionCategory.incomeTransfer.value)
                .fold<double>(0.0, (s, t) => s + t.amount);

            final otherInc = totalInc - salary - passive;

            final totalExp = periodTxs
                .where((t) => TransactionCategory.fromValue(t.category).isExpense && t.category != TransactionCategory.expenseTransfer.value && t.category != TransactionCategory.expenseTransferToCash.value)
                .fold<double>(0.0, (s, t) => s + t.amount.abs());

            final netCash = totalInc - totalExp;

            final newCashPos = periodTxs
                .where((t) => t.amount > 0 && t.accountId != 'manual_cash' && t.accountId != 'manual' && t.category != TransactionCategory.incomeTransfer.value)
                .fold<double>(0.0, (s, t) => s + t.amount);

            // Category breakdown for expenses
            final catMap = <String, double>{};
            for (final t in periodTxs) {
              final cat = TransactionCategory.fromValue(t.category);
              if (cat.isExpense && cat != TransactionCategory.expenseTransfer && cat != TransactionCategory.expenseTransferToCash) {
                catMap[cat.displayName] = (catMap[cat.displayName] ?? 0.0) + t.amount.abs();
              }
            }

            return {
              'salary': salary,
              'passive': passive,
              'other': otherInc,
              'totalInc': totalInc,
              'totalExp': totalExp,
              'netCash': netCash,
              'newCashPos': newCashPos,
              'catMap': catMap,
            };
          }

          final m0 = _calcMonthMetrics(m0Date);
          final m1 = _calcMonthMetrics(m1Date);
          final m2 = _calcMonthMetrics(m2Date);

          // Get unique category names across all 3 months
          final allCatNames = <String>{
            ...(m2['catMap'] as Map<String, double>).keys,
            ...(m1['catMap'] as Map<String, double>).keys,
            ...(m0['catMap'] as Map<String, double>).keys,
          }.toList();
          allCatNames.sort();

          // Cash position balances
          final cashPositionAsync = ref.watch(cashPositionProvider);
          final currentLiquidCash = cashPositionAsync.when(
            data: (pos) => pos.currentBalance,
            loading: () => 0.0,
            error: (_, __) => 0.0,
          );
          final prevMonthCash = cashPositionAsync.when(
            data: (pos) => pos.prevMonthBalance,
            loading: () => 0.0,
            error: (_, __) => 0.0,
          );

          final transferMismatch = state.transferMismatch;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Controls & Business Toggle
                _buildHeaderControls(),
                const SizedBox(height: 16),

                // Executive Summary Cards
                _buildExecutiveSummary(
                  m0['netCash'] as double,
                  m0['totalInc'] as double,
                  m0['totalExp'] as double,
                  0.0,
                  currencyFormat,
                ),
                const SizedBox(height: 20),

                // Transfer Mismatch Warning (shown ONLY if internal transfers don't net to 0)
                if (transferMismatch > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF39C12).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFF39C12), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Internal transfers do not net to zero (S\$${transferMismatch.toStringAsFixed(2)} mismatch). Tap "+ Add" on Cash Flow screen to manually offset.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Statement Banner Info
                _buildAccountingNoticeBanner(),
                const SizedBox(height: 20),

                // Part I: Operating Cash Flows (Personal) - 3 Month Comparative
                _buildStatementSection(
                  title: 'PART I: OPERATING CASH FLOWS (PERSONAL)',
                  icon: Icons.account_balance_wallet_outlined,
                  accentColor: AppColors.proPrimary,
                  children: [
                    _buildMultiColumnHeader(m2Label, m1Label, m0Label),
                    const Divider(color: Colors.white24, height: 16),
                    _buildMultiColumnRow('Salary & Earned Income', m2['salary'], m1['salary'], m0['salary'], currencyFormat, isPositive: true),
                    _buildMultiColumnRow('Interest & Investment Returns', m2['passive'], m1['passive'], m0['passive'], currencyFormat, isPositive: true),
                    _buildMultiColumnRow('Other Inflows', m2['other'], m1['other'], m0['other'], currencyFormat, isPositive: true),
                    const Divider(color: Colors.white24, height: 20),
                    _buildMultiColumnRow('Total Income', m2['totalInc'], m1['totalInc'], m0['totalInc'], currencyFormat, isBold: true, isPositive: true),
                    const SizedBox(height: 12),
                    if (allCatNames.isNotEmpty) ...[
                      const Text('Expense Categories:', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...allCatNames.map((catName) {
                        final v2 = (m2['catMap'] as Map<String, double>)[catName] ?? 0.0;
                        final v1 = (m1['catMap'] as Map<String, double>)[catName] ?? 0.0;
                        final v0 = (m0['catMap'] as Map<String, double>)[catName] ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
                          child: _buildMultiColumnRow('• $catName', -v2, -v1, -v0, currencyFormat, isPositive: false),
                        );
                      }),
                      const SizedBox(height: 6),
                    ],
                    _buildMultiColumnRow('Total Expenses', -(m2['totalExp'] as double), -(m1['totalExp'] as double), -(m0['totalExp'] as double), currencyFormat, isBold: true, isPositive: false),
                    const Divider(color: Colors.white24, height: 20),
                    _buildMultiColumnSubtotalRow('NET CASH FLOW', m2['netCash'], m1['netCash'], m0['netCash'], currencyFormat),
                  ],
                ),
                const SizedBox(height: 20),

                // Total Cash Positions - 3 Month Comparative
                _buildStatementSection(
                  title: 'TOTAL CASH POSITIONS',
                  icon: Icons.account_balance_outlined,
                  accentColor: Colors.cyanAccent,
                  children: [
                    _buildMultiColumnHeader(m2Label, m1Label, m0Label),
                    const Divider(color: Colors.white24, height: 16),
                    _buildMultiColumnRow('Beginning cash', prevMonthCash, prevMonthCash, prevMonthCash, currencyFormat, isPositive: true),
                    _buildMultiColumnRow('New cash positions added', m2['newCashPos'], m1['newCashPos'], m0['newCashPos'], currencyFormat, isPositive: true),
                    _buildMultiColumnRow('Total Income', m2['totalInc'], m1['totalInc'], m0['totalInc'], currencyFormat, isPositive: true),
                    _buildMultiColumnRow('Total Expenses', -(m2['totalExp'] as double), -(m1['totalExp'] as double), -(m0['totalExp'] as double), currencyFormat, isPositive: false),
                  ],
                ),
                const SizedBox(height: 20),

                // Part III: Optional Business Module
                if (_includeBusiness) ...[
                  _buildStatementSection(
                    title: 'PART III: BUSINESS & CAPITAL OPERATIONS',
                    icon: Icons.business_center_outlined,
                    accentColor: AppColors.proGold,
                    children: [
                      _buildMultiColumnHeader(m2Label, m1Label, m0Label),
                      const Divider(color: Colors.white24, height: 16),
                      _buildMultiColumnRow('Business Operating Revenues', 0.0, 0.0, 0.0, currencyFormat, isPositive: true),
                      _buildMultiColumnRow('Capital Expenditures & Property', 0.0, 0.0, 0.0, currencyFormat, isPositive: false),
                      const Divider(color: Colors.white24, height: 20),
                      _buildMultiColumnSubtotalRow('NET BUSINESS CASH FLOW', 0.0, 0.0, 0.0, currencyFormat),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Ending Reconciliation Section
                _buildEndingReconciliationCard(currentLiquidCash, currencyFormat),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.proCardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.proPrimary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Period Horizon', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Month', label: Text('Month')),
                  ButtonSegment(value: 'Quarter', label: Text('Quarter')),
                  ButtonSegment(value: 'YTD', label: Text('YTD')),
                ],
                selected: {_periodType},
                onSelectionChanged: (val) => setState(() => _periodType = val.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.proPrimary;
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.all(AppColors.white),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.storefront_outlined, color: AppColors.proGold, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Include Business & Capital Module',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Switch(
                value: _includeBusiness,
                activeColor: AppColors.proGold,
                onChanged: (val) => setState(() => _includeBusiness = val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary(double netCash, double grossIn, double grossOut, double netTransfers, NumberFormat fmt) {
    final savingsRatio = grossIn > 0 ? ((netCash / grossIn) * 100).clamp(0.0, 100.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.proGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.proPrimary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NET CASH FLOW', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Icon(Icons.verified_outlined, color: AppColors.proGold, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fmt.format(netCash),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL INCOME', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(fmt.format(grossIn), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL EXPENSES', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(fmt.format(grossOut), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL NET TRANSFERS', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(fmt.format(netTransfers), style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('NET SAVINGS RATE', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 3),
                        Tooltip(
                          message: 'Formula: (Net Cash Flow / Total Income) × 100%\n\nMeasures the percentage of total income retained as net savings after deducting total expenses.',
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.proCardBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.proGold),
                          ),
                          textStyle: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
                          child: const Icon(Icons.info_outline, color: Colors.white54, size: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${savingsRatio.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.proGold, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountingNoticeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.proCardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.proPrimary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Personal Cash Flow Accounting Mode: Operating cash flows represent genuine 3rd-party transactions. Internal transfers net to zero.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementSection({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.proCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLineItem(String label, double amount, NumberFormat fmt, {bool isPositive = true, bool isBold = false, String? subtitle}) {
    final color = amount == 0 ? Colors.white54 : (isPositive ? Colors.greenAccent : Colors.white);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isBold ? Colors.white : Colors.white70,
                    fontSize: isBold ? 14 : 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ],
            ),
          ),
          Text(
            fmt.format(amount),
            style: TextStyle(
              color: color,
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtotalRow(String label, double amount, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.proBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.proPrimary.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          Text(
            fmt.format(amount),
            style: TextStyle(
              color: amount >= 0 ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndingReconciliationCard(double currentLiquidCash, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.proCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.proGold.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL ENDING CASH', style: TextStyle(color: AppColors.proGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8)),
              SizedBox(height: 2),
              Text('Sum of Bank Balances + Physical Cash on Hand', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          Text(
            fmt.format(currentLiquidCash),
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiColumnHeader(String m2Label, String m1Label, String m0Label) {
    return Row(
      children: [
        const Expanded(
          flex: 4,
          child: Text('Line Item', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 3,
          child: Text(m2Label, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.proGold, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 3,
          child: Text(m1Label, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.proGold, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 3,
          child: Text(m0Label, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.proGold, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildMultiColumnRow(
    String label,
    double v2,
    double v1,
    double v0,
    NumberFormat fmt, {
    bool isPositive = true,
    bool isBold = false,
  }) {
    final c2 = v2 == 0 ? Colors.white38 : (isPositive ? Colors.greenAccent : Colors.white70);
    final c1 = v1 == 0 ? Colors.white38 : (isPositive ? Colors.greenAccent : Colors.white70);
    final c0 = v0 == 0 ? Colors.white54 : (isPositive ? Colors.greenAccent : Colors.white);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: isBold ? Colors.white : Colors.white70,
                fontSize: isBold ? 13.5 : 12.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt.format(v2),
              textAlign: TextAlign.right,
              style: TextStyle(color: c2, fontSize: isBold ? 13 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt.format(v1),
              textAlign: TextAlign.right,
              style: TextStyle(color: c1, fontSize: isBold ? 13 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt.format(v0),
              textAlign: TextAlign.right,
              style: TextStyle(color: c0, fontSize: isBold ? 14 : 12.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiColumnSubtotalRow(
    String label,
    double v2,
    double v1,
    double v0,
    NumberFormat fmt,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.proBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.proPrimary.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt.format(v2),
              textAlign: TextAlign.right,
              style: TextStyle(color: v2 >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt.format(v1),
              textAlign: TextAlign.right,
              style: TextStyle(color: v1 >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt.format(v0),
              textAlign: TextAlign.right,
              style: TextStyle(color: v0 >= 0 ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
