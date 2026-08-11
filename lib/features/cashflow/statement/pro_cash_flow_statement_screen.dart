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
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
          final txs = state.allTransactions;
          
          // Column configuration based on _periodType: 'Month', 'Quarter', 'YTD'
          List<Map<String, dynamic>> columns = [];

          final cashPositionAsync = ref.watch(cashPositionProvider);
          final currentLiquidCash = cashPositionAsync.when(data: (pos) => pos.currentBalance, loading: () => 0.0, error: (_, __) => 0.0);
          final prevMonthCash = cashPositionAsync.when(data: (pos) => pos.prevMonthBalance, loading: () => 0.0, error: (_, __) => 0.0);

          // Helper to calculate monthly metrics
          Map<String, dynamic> _calcMonthMetrics(DateTime targetMonth, double endCashVal, double begCashVal) {
            final periodTxs = txs.where((t) {
              final d = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
              return d.year == targetMonth.year && d.month == targetMonth.month;
            }).toList();

            final salary = periodTxs.where((t) => t.category == TransactionCategory.incomeSalary.value).fold<double>(0.0, (s, t) => s + t.amount);
            final passive = periodTxs.where((t) => t.category == TransactionCategory.incomeInterest.value || t.category == TransactionCategory.incomeInvestments.value || t.category == TransactionCategory.incomeDividends.value).fold<double>(0.0, (s, t) => s + t.amount);
            final totalInc = periodTxs.where((t) => TransactionCategory.fromValue(t.category).isIncome && t.category != TransactionCategory.incomeTransfer.value).fold<double>(0.0, (s, t) => s + t.amount);
            final totalExp = periodTxs.where((t) => (t.amount < 0 || TransactionCategory.fromValue(t.category).isExpense) && t.category != TransactionCategory.incomeTransfer.value && t.category != TransactionCategory.expenseTransfer.value).fold<double>(0.0, (s, t) => s + t.amount.abs());
            
            final catMap = <String, double>{};
            for (final t in periodTxs) {
              final cat = TransactionCategory.fromValue(t.category);
              if (cat.isExpense && cat != TransactionCategory.expenseTransfer && cat != TransactionCategory.expenseTransferToCash) {
                catMap[cat.displayName] = (catMap[cat.displayName] ?? 0.0) + t.amount.abs();
              }
            }

              double newCashPos = 0.0;
              final allUserAccounts = state.bankAccounts;
              final fxRates = cashPositionAsync.asData?.value.fxRates ?? {};
              final statementsList = state.statements;

              for (final acc in allUserAccounts) {
                if (acc.id == 'manual_cash_account') continue;
                DateTime? stmtDate;
                if (acc.sourceStatementId != null) {
                  final matchedStmt = statementsList.where((s) => s.id == acc.sourceStatementId).firstOrNull;
                  if (matchedStmt != null && matchedStmt.periodEnd != null && matchedStmt.periodEnd! > 0) {
                    stmtDate = DateTime.fromMillisecondsSinceEpoch(matchedStmt.periodEnd! * 1000);
                  }
                }
                // If statement date not explicitly set on statement row, infer from account's balanceAsOf (createdAt) timestamp
                if (stmtDate == null && acc.createdAt > 0) {
                  stmtDate = DateTime.fromMillisecondsSinceEpoch(acc.createdAt * 1000);
                }

                if (stmtDate != null && stmtDate.year == targetMonth.year && stmtDate.month == targetMonth.month) {
                  final baseBal = acc.openingBalance > 0 ? acc.openingBalance : acc.currentBalance;
                  final currencyStr = acc.currency.trim().toUpperCase();
                  if (currencyStr == 'SGD') {
                    newCashPos += baseBal;
                  } else {
                    final rate = fxRates[currencyStr] ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
                    newCashPos += baseBal * rate;
                  }
                }
              }

              return {
                'salary': salary, 'passive': passive, 'other': totalInc - salary - passive,
                'totalInc': totalInc, 'totalExp': totalExp, 'netCash': totalInc - totalExp,
                'newCashPos': newCashPos, 'begCash': begCashVal, 'endCash': endCashVal, 'catMap': catMap,
              };
            }

          if (_periodType == 'Quarter') {
            final selectedYear = selectedMonth.year;
            final maxQuarter = ((selectedMonth.month - 1) ~/ 3) + 1;

            double runningBegCash = 0.0;

            for (int i = 0; i < maxQuarter; i++) {
              final qNum = i + 1;
              final startM = (qNum - 1) * 3 + 1;
              final endM = qNum == maxQuarter ? selectedMonth.month : qNum * 3;

              final lastDay = DateTime(selectedYear, endM + 1, 0).day;
              final label = 'Q$qNum\n$lastDay ${DateFormat('MMM yyyy').format(DateTime(selectedYear, endM))}';

              final periodTxs = txs.where((t) {
                final d = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
                return d.year == selectedYear && d.month >= startM && d.month <= endM;
              }).toList();

              final salary = periodTxs.where((t) => t.category == TransactionCategory.incomeSalary.value).fold<double>(0.0, (s, t) => s + t.amount);
              final passive = periodTxs.where((t) => t.category == TransactionCategory.incomeInterest.value || t.category == TransactionCategory.incomeInvestments.value || t.category == TransactionCategory.incomeDividends.value).fold<double>(0.0, (s, t) => s + t.amount);
              final totalInc = periodTxs.where((t) => TransactionCategory.fromValue(t.category).isIncome && t.category != TransactionCategory.incomeTransfer.value).fold<double>(0.0, (s, t) => s + t.amount);
              final otherInc = totalInc - salary - passive;
              final totalExp = periodTxs.where((t) => (t.amount < 0 || TransactionCategory.fromValue(t.category).isExpense) && t.category != TransactionCategory.incomeTransfer.value && t.category != TransactionCategory.expenseTransfer.value).fold<double>(0.0, (s, t) => s + t.amount.abs());
              final netCash = totalInc - totalExp;

              double newCashPos = 0.0;
              final allUserAccounts = state.bankAccounts;
              final fxRates = cashPositionAsync.asData?.value.fxRates ?? {};
              final statementsList = state.statements;

              for (final acc in allUserAccounts) {
                if (acc.id == 'manual_cash_account') continue;
                DateTime? stmtDate;
                if (acc.sourceStatementId != null) {
                  final matchedStmt = statementsList.where((s) => s.id == acc.sourceStatementId).firstOrNull;
                  if (matchedStmt != null && matchedStmt.periodEnd != null && matchedStmt.periodEnd! > 0) {
                    stmtDate = DateTime.fromMillisecondsSinceEpoch(matchedStmt.periodEnd! * 1000);
                  }
                }
                if (stmtDate == null && acc.createdAt > 0) {
                  stmtDate = DateTime.fromMillisecondsSinceEpoch(acc.createdAt * 1000);
                }

                if (stmtDate != null && stmtDate.year == selectedYear && stmtDate.month >= startM && stmtDate.month <= endM) {
                  final baseBal = acc.openingBalance > 0 ? acc.openingBalance : acc.currentBalance;
                  final currencyStr = acc.currency.trim().toUpperCase();
                  if (currencyStr == 'SGD') {
                    newCashPos += baseBal;
                  } else {
                    final rate = fxRates[currencyStr] ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
                    newCashPos += baseBal * rate;
                  }
                }
              }

              final catMap = <String, double>{};
              for (final t in periodTxs) {
                final cat = TransactionCategory.fromValue(t.category);
                if (cat.isExpense && cat != TransactionCategory.expenseTransfer && cat != TransactionCategory.expenseTransferToCash) {
                  catMap[cat.displayName] = (catMap[cat.displayName] ?? 0.0) + t.amount.abs();
                }
              }

              // Evaluate exact ending cash accumulated from all statements up to endM
              double cumulativeCash = 0.0;

              for (final acc in allUserAccounts) {
                if (acc.id == 'manual_cash_account') continue;
                DateTime? stmtDate;
                if (acc.sourceStatementId != null) {
                  final matchedStmt = statementsList.where((s) => s.id == acc.sourceStatementId).firstOrNull;
                  if (matchedStmt != null && matchedStmt.periodEnd != null && matchedStmt.periodEnd! > 0) {
                    stmtDate = DateTime.fromMillisecondsSinceEpoch(matchedStmt.periodEnd! * 1000);
                  }
                }
                if (stmtDate == null && acc.createdAt > 0) {
                  stmtDate = DateTime.fromMillisecondsSinceEpoch(acc.createdAt * 1000);
                }

                // If account statement date is on or before endM month, include its balance
                if (stmtDate != null) {
                  final stmtMonthStart = DateTime(stmtDate.year, stmtDate.month, 1);
                  final endMonthStart = DateTime(selectedYear, endM, 1);
                  if (!stmtMonthStart.isAfter(endMonthStart)) {
                    final baseBal = acc.openingBalance > 0 ? acc.openingBalance : acc.currentBalance;
                    final currencyStr = acc.currency.trim().toUpperCase();
                    if (currencyStr == 'SGD') {
                      cumulativeCash += baseBal;
                    } else {
                      final rate = fxRates[currencyStr] ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
                      cumulativeCash += baseBal * rate;
                    }
                  }
                }
              }

              final qEndCash = cumulativeCash;

              columns.add({
                'label': label,
                'salary': salary,
                'passive': passive,
                'other': otherInc,
                'totalInc': totalInc,
                'totalExp': totalExp,
                'netCash': netCash,
                'newCashPos': newCashPos,
                'begCash': runningBegCash,
                'endCash': qEndCash,
                'catMap': catMap,
              });

              runningBegCash = qEndCash;
            }
          } else if (_periodType == 'YTD') {
            final selectedYear = selectedMonth.year;
            final endMonth = selectedMonth.month;
            final lastDay = DateTime(selectedYear, endMonth + 1, 0).day;
            final ytdLabel = 'YTD\n$lastDay ${DateFormat('MMM yyyy').format(selectedMonth)}';

            final periodTxs = txs.where((t) {
              final d = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
              return d.year == selectedYear && d.month <= endMonth;
            }).toList();

            final salary = periodTxs.where((t) => t.category == TransactionCategory.incomeSalary.value).fold<double>(0.0, (s, t) => s + t.amount);
            final passive = periodTxs.where((t) => t.category == TransactionCategory.incomeInterest.value || t.category == TransactionCategory.incomeInvestments.value || t.category == TransactionCategory.incomeDividends.value).fold<double>(0.0, (s, t) => s + t.amount);
            final totalInc = periodTxs.where((t) => TransactionCategory.fromValue(t.category).isIncome && t.category != TransactionCategory.incomeTransfer.value).fold<double>(0.0, (s, t) => s + t.amount);
            final otherInc = totalInc - salary - passive;
            final totalExp = periodTxs.where((t) => (t.amount < 0 || TransactionCategory.fromValue(t.category).isExpense) && t.category != TransactionCategory.incomeTransfer.value && t.category != TransactionCategory.expenseTransfer.value).fold<double>(0.0, (s, t) => s + t.amount.abs());
            final netCash = totalInc - totalExp;

            double newCashPos = 0.0;
            final allUserAccounts = cashPositionAsync.asData?.value.accounts ?? [];
            final fxRates = cashPositionAsync.asData?.value.fxRates ?? {};
            final statementsList = state.statements;

            for (final acc in allUserAccounts) {
              if (acc.id == 'manual_cash_account') continue;
              DateTime? stmtDate;
              if (acc.sourceStatementId != null) {
                final matchedStmt = statementsList.where((s) => s.id == acc.sourceStatementId).firstOrNull;
                if (matchedStmt != null) {
                  final pEnd = matchedStmt.periodEnd ?? matchedStmt.periodStart ?? matchedStmt.uploadedAt;
                  stmtDate = DateTime.fromMillisecondsSinceEpoch(pEnd * 1000);
                }
              }
              if (stmtDate == null && acc.createdAt > 0) {
                stmtDate = DateTime.fromMillisecondsSinceEpoch(acc.createdAt * 1000);
              }

              if (stmtDate != null && stmtDate.year == selectedYear && stmtDate.month <= endMonth) {
                final baseBal = acc.openingBalance > 0 ? acc.openingBalance : acc.currentBalance;
                final currencyStr = acc.currency.trim().toUpperCase();
                if (currencyStr == 'SGD') {
                  newCashPos += baseBal;
                } else {
                  final rate = fxRates[currencyStr] ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
                  newCashPos += baseBal * rate;
                }
              }
            }

            final catMap = <String, double>{};
            for (final t in periodTxs) {
              final cat = TransactionCategory.fromValue(t.category);
              if (cat.isExpense && cat != TransactionCategory.expenseTransfer && cat != TransactionCategory.expenseTransferToCash) {
                catMap[cat.displayName] = (catMap[cat.displayName] ?? 0.0) + t.amount.abs();
              }
            }

            columns.add({
              'label': ytdLabel,
              'salary': salary,
              'passive': passive,
              'other': otherInc,
              'totalInc': totalInc,
              'totalExp': totalExp,
              'netCash': netCash,
              'newCashPos': newCashPos,
              'begCash': 0.0,
              'endCash': currentLiquidCash,
              'catMap': catMap,
            });
          } else {
            final m0Date = selectedMonth;
            final m1Date = DateTime(selectedMonth.year, selectedMonth.month - 1);
            final m2Date = DateTime(selectedMonth.year, selectedMonth.month - 2);
            final twoMonthsAgoCash = cashPositionAsync.when(data: (pos) => pos.twoMonthsAgoBalance, loading: () => 0.0, error: (_, __) => 0.0);
            final threeMonthsAgoCash = cashPositionAsync.when(data: (pos) => pos.threeMonthsAgoBalance, loading: () => 0.0, error: (_, __) => 0.0);

            columns = [
              {..._calcMonthMetrics(m2Date, twoMonthsAgoCash, threeMonthsAgoCash), 'label': DateFormat('MMM yyyy').format(m2Date)},
              {..._calcMonthMetrics(m1Date, prevMonthCash, twoMonthsAgoCash), 'label': DateFormat('MMM yyyy').format(m1Date)},
              {..._calcMonthMetrics(m0Date, currentLiquidCash, prevMonthCash), 'label': DateFormat('MMM yyyy').format(m0Date)},
            ];
          }

          final allCatNames = <String>{};
          for (final col in columns) {
            allCatNames.addAll((col['catMap'] as Map<String, double>).keys);
          }
          final sortedCatNames = allCatNames.toList()..sort();

          return Theme(
            data: Theme.of(context).copyWith(
              scrollbarTheme: ScrollbarThemeData(
                thumbColor: WidgetStateProperty.all(Colors.white),
                trackColor: WidgetStateProperty.all(Colors.white24),
                trackBorderColor: WidgetStateProperty.all(Colors.white38),
                radius: const Radius.circular(8),
                thickness: WidgetStateProperty.all(12.0),
                thumbVisibility: WidgetStateProperty.all(true),
                interactive: true,
              ),
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              interactive: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Controls & Business Toggle
                    _buildHeaderControls(),
                    const SizedBox(height: 16),

                    // Executive Summary Cards
                    _buildExecutiveSummary(
                      columns.last['netCash'] as double,
                      columns.last['totalInc'] as double,
                      columns.last['totalExp'] as double,
                      0.0,
                      currencyFormat,
                      columns.last['label'] as String,
                    ),
                    const SizedBox(height: 20),

                    // Statement Banner Info
                    _buildAccountingNoticeBanner(),
                    const SizedBox(height: 20),

                    // Part I: Operating Cash Flows (Personal)
                    _buildStatementSection(
                      title: 'PART I: OPERATING CASH FLOWS (PERSONAL)',
                      icon: Icons.account_balance_wallet_outlined,
                      accentColor: AppColors.proPrimary,
                      children: [
                        _buildDynamicHeader(columns),
                        const Divider(color: Colors.white24, height: 16),
                        _buildDynamicRow('Salary & Earned Income', columns, 'salary', currencyFormat, isPositive: true),
                        _buildDynamicRow('Interest & Investment Returns', columns, 'passive', currencyFormat, isPositive: true),
                        _buildDynamicRow('Other Inflows', columns, 'other', currencyFormat, isPositive: true),
                        const Divider(color: Colors.white24, height: 20),
                        _buildDynamicRow('Total Income', columns, 'totalInc', currencyFormat, isBold: true, isPositive: true),
                        const SizedBox(height: 12),
                        if (sortedCatNames.isNotEmpty) ...[
                          const Text('Expense Categories:', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...sortedCatNames.map((catName) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 2, bottom: 2),
                              child: _buildDynamicCategoryRow('• $catName', columns, catName, currencyFormat),
                            );
                          }),
                          const SizedBox(height: 6),
                        ],
                        _buildDynamicRow('Total Expenses', columns, 'totalExp', currencyFormat, isBold: true, isPositive: false, negate: true),
                        const Divider(color: Colors.white24, height: 20),
                        _buildDynamicSubtotalRow('NET CASH FLOW', columns, 'netCash', currencyFormat),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Total Cash Positions
                    _buildStatementSection(
                      title: 'TOTAL CASH POSITIONS',
                      icon: Icons.account_balance_outlined,
                      accentColor: Colors.cyanAccent,
                      children: [
                        _buildDynamicHeader(columns),
                        const Divider(color: Colors.white24, height: 16),
                        _buildDynamicRow('Beginning cash', columns, 'begCash', currencyFormat, isPositive: true),
                        _buildDynamicRow('New cash positions added', columns, 'newCashPos', currencyFormat, isPositive: true),
                        _buildDynamicRow('Total Income', columns, 'totalInc', currencyFormat, isPositive: true),
                        _buildDynamicRow('Total Expenses', columns, 'totalExp', currencyFormat, isPositive: false, negate: true),
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
                          _buildDynamicHeader(columns),
                          const Divider(color: Colors.white24, height: 16),
                          _buildDynamicRow('Business Operating Revenues', columns, 'zero', currencyFormat, isPositive: true),
                          _buildDynamicRow('Capital Expenditures & Property', columns, 'zero', currencyFormat, isPositive: false),
                          const Divider(color: Colors.white24, height: 20),
                          _buildDynamicSubtotalRow('NET BUSINESS CASH FLOW', columns, 'zero', currencyFormat),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Ending Reconciliation Section
                    _buildDynamicEndingCard(columns, currencyFormat),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDynamicHeader(List<Map<String, dynamic>> columns) {
    return Row(
      children: [
        const Expanded(
          flex: 4,
          child: Text('Line Item', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        ...columns.map((col) => Expanded(
          flex: 3,
          child: Text(col['label'] as String, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.proGold, fontSize: 11, fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }

  Widget _buildDynamicRow(String label, List<Map<String, dynamic>> columns, String key, NumberFormat fmt, {bool isPositive = true, bool isBold = false, bool negate = false}) {
    final activeColor = isPositive ? const Color(0xFF60A5FA) : const Color(0xFFF87171);
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
          ...columns.map((col) {
            double val = (col[key] as double? ?? 0.0);
            if (negate) val = -val;
            final c = val == 0 ? Colors.white38 : activeColor;
            return Expanded(
              flex: 3,
              child: Text(
                fmt.format(val),
                textAlign: TextAlign.right,
                style: TextStyle(color: c, fontSize: isBold ? 13.5 : 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDynamicCategoryRow(String label, List<Map<String, dynamic>> columns, String catName, NumberFormat fmt) {
    final activeColor = const Color(0xFFF87171);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          ...columns.map((col) {
            final catMap = col['catMap'] as Map<String, double>? ?? {};
            final val = -(catMap[catName] ?? 0.0);
            final c = val == 0 ? Colors.white38 : activeColor;
            return Expanded(
              flex: 3,
              child: Text(
                fmt.format(val),
                textAlign: TextAlign.right,
                style: TextStyle(color: c, fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDynamicSubtotalRow(String label, List<Map<String, dynamic>> columns, String key, NumberFormat fmt) {
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
          ...columns.map((col) {
            final val = col[key] as double? ?? 0.0;
            return Expanded(
              flex: 3,
              child: Text(
                fmt.format(val),
                textAlign: TextAlign.right,
                style: TextStyle(color: val >= 0 ? const Color(0xFF60A5FA) : const Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDynamicEndingCard(List<Map<String, dynamic>> columns, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.proCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.proGold.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL ENDING CASH', style: TextStyle(color: AppColors.proGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8)),
              Text('Sum of Bank Balances + Physical Cash on Hand', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          _buildDynamicSubtotalRow('TOTAL ENDING CASH', columns, 'endCash', fmt),
        ],
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

  Widget _buildExecutiveSummary(double netCash, double grossIn, double grossOut, double netTransfers, NumberFormat fmt, String monthLabel) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NET CASH FLOW · $monthLabel', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const Icon(Icons.verified_outlined, color: AppColors.proGold, size: 20),
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

  Widget _buildEndingReconciliationCard(double e2, double e1, double e0, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.proCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.proGold.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL ENDING CASH', style: TextStyle(color: AppColors.proGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8)),
              Text('Sum of Bank Balances + Physical Cash on Hand', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          _buildMultiColumnSubtotalRow('TOTAL ENDING CASH', e2, e1, e0, fmt),
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
    final activeColor = isPositive ? const Color(0xFF60A5FA) : const Color(0xFFF87171); // Blue for income, Red for expenses
    final c2 = v2 == 0 ? Colors.white38 : activeColor.withOpacity(0.8);
    final c1 = v1 == 0 ? Colors.white38 : activeColor.withOpacity(0.9);
    final c0 = v0 == 0 ? Colors.white54 : activeColor;

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
              style: TextStyle(color: v2 >= 0 ? const Color(0xFF60A5FA) : const Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt.format(v1),
              textAlign: TextAlign.right,
              style: TextStyle(color: v1 >= 0 ? const Color(0xFF60A5FA) : const Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              fmt.format(v0),
              textAlign: TextAlign.right,
              style: TextStyle(color: v0 >= 0 ? const Color(0xFF60A5FA) : const Color(0xFFF87171), fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
