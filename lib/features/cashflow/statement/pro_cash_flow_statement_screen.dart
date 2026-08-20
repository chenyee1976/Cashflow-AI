// Updated Pro Cash Flow Statement Screen with Net Savings Rate Tooltip
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data' show Uint8List;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

    // Helper to build the common AppBar (with or without PDF button)
    Widget buildAppBar({List<Widget>? actions}) {
      return AppBar(
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
        actions: actions,
      );
    }

    return cashFlowAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.proBackground,
        appBar: buildAppBar() as AppBar,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.proPrimary),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.proBackground,
        appBar: buildAppBar() as AppBar,
        body: Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
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

              // Step 1: Identify statement date & current balance for each account snapshot
              final accountDateMap = <String, DateTime>{};
              final accountBalanceMap = <String, double>{};
              final accountIdentityMap = <String, String>{}; // snapshotId -> normIdentity

              String _normKey(BankAccount a) => '${a.bankName.trim()}_${(a.accountNumber ?? '').trim()}'.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

              for (final acc in allUserAccounts) {
                if (acc.id == 'manual_cash_account') continue;
                DateTime? stmtDate;
                if (acc.sourceStatementId != null) {
                  final matchedStmt = statementsList.where((s) => s.id == acc.sourceStatementId).firstOrNull;
                  if (matchedStmt != null && matchedStmt.periodEnd != null && matchedStmt.periodEnd! > 0) {
                    stmtDate = DateTime.fromMillisecondsSinceEpoch(matchedStmt.periodEnd! * 1000);
                  }
                  if (stmtDate == null) {
                    final stmtTxs = txs.where((t) => t.statementId == acc.sourceStatementId).toList();
                    if (stmtTxs.isNotEmpty) {
                      stmtTxs.sort((a, b) => b.date.compareTo(a.date));
                      stmtDate = DateTime.fromMillisecondsSinceEpoch(stmtTxs.first.date * 1000);
                    }
                  }
                }
                if (stmtDate != null) {
                  accountDateMap[acc.id] = stmtDate;
                  accountBalanceMap[acc.id] = acc.currentBalance;
                  accountIdentityMap[acc.id] = _normKey(acc);
                }
              }

              // Step 2: Find earliest statement date per unique bank account identity
              final earliestDatePerIdentity = <String, DateTime>{};
              final earliestSnapshotPerIdentity = <String, String>{};

              for (final accId in accountDateMap.keys) {
                final date = accountDateMap[accId]!;
                final identity = accountIdentityMap[accId]!;
                if (!earliestDatePerIdentity.containsKey(identity) || date.isBefore(earliestDatePerIdentity[identity]!)) {
                  earliestDatePerIdentity[identity] = date;
                  earliestSnapshotPerIdentity[identity] = accId;
                }
              }

              // Step 3: Add to newCashPos ONLY if this snapshot is the earliest statement for that unique account, and occurs in targetMonth
              for (final identity in earliestSnapshotPerIdentity.keys) {
                final earliestDate = earliestDatePerIdentity[identity]!;
                if (earliestDate.year == targetMonth.year && earliestDate.month == targetMonth.month) {
                  final snapshotId = earliestSnapshotPerIdentity[identity]!;
                  final acc = allUserAccounts.firstWhere((a) => a.id == snapshotId);
                  final baseBal = acc.currentBalance;
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
                  if (stmtDate == null) {
                    final stmtTxs = txs.where((t) => t.statementId == acc.sourceStatementId).toList();
                    if (stmtTxs.isNotEmpty) {
                      stmtTxs.sort((a, b) => b.date.compareTo(a.date));
                      stmtDate = DateTime.fromMillisecondsSinceEpoch(stmtTxs.first.date * 1000);
                    }
                  }
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

              // Evaluate exact ending cash as of the quarter end month (endM)
              double cumulativeCash = 0.0;
              final endMonthStart = DateTime(selectedYear, endM, 1);

              final latestBalancePerIdentity = <String, double>{};
              final latestDatePerIdentity = <String, DateTime>{};

              String _normIdentity(BankAccount a) => '${a.bankName.trim()}_${(a.accountNumber ?? '').trim()}'.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

              for (final acc in allUserAccounts) {
                if (acc.id == 'manual_cash_account') continue;
                DateTime? stmtDate;
                if (acc.sourceStatementId != null) {
                  final matchedStmt = statementsList.where((s) => s.id == acc.sourceStatementId).firstOrNull;
                  if (matchedStmt != null && matchedStmt.periodEnd != null && matchedStmt.periodEnd! > 0) {
                    stmtDate = DateTime.fromMillisecondsSinceEpoch(matchedStmt.periodEnd! * 1000);
                  }
                  if (stmtDate == null) {
                    final stmtTxs = txs.where((t) => t.statementId == acc.sourceStatementId).toList();
                    if (stmtTxs.isNotEmpty) {
                      stmtTxs.sort((a, b) => b.date.compareTo(a.date));
                      stmtDate = DateTime.fromMillisecondsSinceEpoch(stmtTxs.first.date * 1000);
                    }
                  }
                }

                if (stmtDate != null) {
                  final stmtMonthStart = DateTime(stmtDate.year, stmtDate.month, 1);
                  if (!stmtMonthStart.isAfter(endMonthStart)) {
                    final identity = _normIdentity(acc);
                    if (!latestDatePerIdentity.containsKey(identity) || stmtDate.isAfter(latestDatePerIdentity[identity]!)) {
                      latestDatePerIdentity[identity] = stmtDate;
                      latestBalancePerIdentity[identity] = acc.currentBalance;
                    }
                  }
                }
              }

              for (final identity in latestBalancePerIdentity.keys) {
                final baseBal = latestBalancePerIdentity[identity]!;
                final sampleAcc = allUserAccounts.firstWhere((a) => _normIdentity(a) == identity);
                final currencyStr = sampleAcc.currency.trim().toUpperCase();
                if (currencyStr == 'SGD') {
                  cumulativeCash += baseBal;
                } else {
                  final rate = fxRates[currencyStr] ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
                  cumulativeCash += baseBal * rate;
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

          return Scaffold(
            backgroundColor: AppColors.proBackground,
            appBar: buildAppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.proGold, size: 24),
                  tooltip: 'Download PDF Statement',
                  onPressed: () async {
                    if (kIsWeb) {
                      try {
                        final fxRates = cashPositionAsync.asData?.value.fxRates ?? {};
                        final pdfBytes = await _generatePdfDocument(
                          _periodType,
                          selectedMonth,
                          columns,
                          sortedCatNames,
                          state.bankAccounts,
                          state.statements,
                          txs,
                          fxRates,
                          realCashBal,
                        );

                        final fileName = 'CashFlow_Statement_${_periodType}_${DateFormat('yyyyMMdd').format(selectedMonth)}.pdf';
                        final blob = html.Blob([pdfBytes], 'application/pdf');
                        final url = html.Url.createObjectUrlFromBlob(blob);

                        final anchor = html.AnchorElement(href: url)
                          ..setAttribute('download', fileName)
                          ..click();

                        Future.delayed(const Duration(seconds: 2), () {
                          html.Url.revokeObjectUrl(url);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloaded PDF: $fileName'),
                            backgroundColor: AppColors.proPrimary,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        debugPrint('Error generating PDF: $e');
                      }
                    }
                  },
                ),
              ],
            ) as AppBar,
            body: Theme(
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
                    _buildDynamicEndingCard(columns, currencyFormat, state.bankAccounts, state.statements, txs, selectedMonth.year, cashPositionAsync.asData?.value.fxRates ?? {}),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
          );
        },
      );
  }

  Widget _buildDynamicHeader(List<Map<String, dynamic>> columns) {
    final isMobile = MediaQuery.of(context).size.width < 480;
    final fontSize = isMobile ? 10.0 : 11.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text('Line Item', style: TextStyle(color: Colors.white54, fontSize: fontSize, fontWeight: FontWeight.bold)),
        ),
        ...columns.map((col) => Expanded(
          flex: 3,
          child: Text(col['label'] as String, textAlign: TextAlign.right, style: TextStyle(color: AppColors.proGold, fontSize: fontSize, fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }

  Widget _buildDynamicRow(String label, List<Map<String, dynamic>> columns, String key, NumberFormat fmt, {bool isPositive = true, bool isBold = false, bool negate = false}) {
    final activeColor = isPositive ? const Color(0xFF60A5FA) : const Color(0xFFF87171);
    final isMobile = MediaQuery.of(context).size.width < 480;
    final labelSize = isMobile ? (isBold ? 12.0 : 11.0) : (isBold ? 13.5 : 12.5);
    final valSize = isMobile ? (isBold ? 11.5 : 10.5) : (isBold ? 13.5 : 12.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: isBold ? Colors.white : Colors.white70,
                fontSize: labelSize,
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
                style: TextStyle(color: c, fontSize: valSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDynamicCategoryRow(String label, List<Map<String, dynamic>> columns, String catName, NumberFormat fmt) {
    final activeColor = const Color(0xFFF87171);
    final isMobile = MediaQuery.of(context).size.width < 480;
    final fontSize = isMobile ? 10.5 : 12.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: fontSize),
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
                style: TextStyle(color: c, fontSize: fontSize),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDynamicSubtotalRow(String label, List<Map<String, dynamic>> columns, String key, NumberFormat fmt) {
    final isMobile = MediaQuery.of(context).size.width < 480;
    final labelSize = isMobile ? 11.0 : 12.0;
    final valSize = isMobile ? 11.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: AppColors.proBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.proPrimary.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: labelSize)),
          ),
          ...columns.map((col) {
            final val = col[key] as double? ?? 0.0;
            return Expanded(
              flex: 3,
              child: Text(
                fmt.format(val),
                textAlign: TextAlign.right,
                style: TextStyle(color: val >= 0 ? const Color(0xFF60A5FA) : const Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: valSize),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDynamicEndingCard(
    List<Map<String, dynamic>> columns,
    NumberFormat fmt,
    List<BankAccount> allUserAccounts,
    List<Statement> statementsList,
    List<Transaction> txs,
    int selectedYear,
    Map<String, double> fxRates,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 480;
    final labelSize = isMobile ? 11.0 : 12.0;
    final valSize = isMobile ? 10.5 : 12.0;

    String _normIdentity(BankAccount a) => '${a.bankName.trim()}_${(a.accountNumber ?? '').trim()}'.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

    // Map column index to month end date
    List<DateTime> endMonthDates = [];
    for (int colIdx = 0; colIdx < columns.length; colIdx++) {
      final col = columns[colIdx];
      final label = col['label'] as String;
      if (_periodType == 'Month') {
        final m0Date = ref.watch(selectedMonthProvider);
        if (colIdx == 0) {
          endMonthDates.add(DateTime(m0Date.year, m0Date.month - 2));
        } else if (colIdx == 1) {
          endMonthDates.add(DateTime(m0Date.year, m0Date.month - 1));
        } else {
          endMonthDates.add(m0Date);
        }
      } else if (_periodType == 'Quarter') {
        int endM = 3;
        if (label.contains('Q1')) endM = 3;
        if (label.contains('Q2')) endM = 6;
        if (label.contains('Q3')) endM = 9;
        if (label.contains('Q4')) endM = 12;
        endMonthDates.add(DateTime(selectedYear, endM));
      } else {
        endMonthDates.add(DateTime(selectedYear, 12));
      }
    }

    // Collect all unique account identities
    final combinedAccounts = <BankAccount>[
      ...?ref.watch(cashPositionProvider).asData?.value.accounts,
      ...allUserAccounts,
    ];

    final Map<String, BankAccount> uniqueAccountSamples = {};
    for (final acc in combinedAccounts) {
      final key = _normIdentity(acc);
      if (!uniqueAccountSamples.containsKey(key)) {
        uniqueAccountSamples[key] = acc;
      }
    }

    final realCashAcc = ref.watch(cashPositionProvider).asData?.value.accounts.where((a) => a.id == 'manual_cash_account').firstOrNull;
    final realCashBal = realCashAcc?.currentBalance ?? 0.0;

    if (!uniqueAccountSamples.containsKey('physicalcashonhand_cash') &&
        !uniqueAccountSamples.values.any((a) => a.id == 'manual_cash_account')) {
      uniqueAccountSamples['physicalcashonhand_cash'] = BankAccount(
        id: 'manual_cash_account',
        userId: 'chenyee_user',
        bankName: 'Physical Cash on Hand',
        accountType: 'Physical Cash',
        accountNumber: 'Cash',
        currentBalance: realCashBal,
        openingBalance: 0.0,
        currency: 'SGD',
        sourceStatementId: null,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    // Build per-account row values across columns
    final List<Map<String, dynamic>> accountRows = [];
    for (final identity in uniqueAccountSamples.keys) {
      final sampleAcc = uniqueAccountSamples[identity]!;
      final accLabel = sampleAcc.id == 'manual_cash_account'
          ? 'Physical Cash on Hand'
          : '${sampleAcc.bankName} (${sampleAcc.accountNumber ?? ""})'.trim();

      final List<double> colValues = [];

      for (int i = 0; i < columns.length; i++) {
        final targetEndMonth = endMonthDates[i];
        final targetEndMonthStart = DateTime(targetEndMonth.year, targetEndMonth.month, 1);

        if (sampleAcc.id == 'manual_cash_account') {
          final posData = ref.watch(cashPositionProvider).asData?.value;
          double monthCashVal = 0.0;
          if (_periodType == 'Month') {
            if (i == 2) {
              monthCashVal = posData?.accounts.where((a) => a.id == 'manual_cash_account').firstOrNull?.currentBalance ?? 0.0;
            } else if (i == 1) {
              monthCashVal = posData?.prevMonthBalances['manual_cash_account'] ?? 0.0;
            } else {
              monthCashVal = posData?.twoMonthsAgoBalances['manual_cash_account'] ?? 0.0;
            }
          } else {
            monthCashVal = posData?.accounts.where((a) => a.id == 'manual_cash_account').firstOrNull?.currentBalance ?? 0.0;
          }
          colValues.add(monthCashVal);
          continue;
        }

        DateTime? latestDate;
        double latestBal = 0.0;

        for (final acc in allUserAccounts) {
          if (_normIdentity(acc) != identity) continue;

          DateTime? stmtDate;
          if (acc.sourceStatementId != null) {
            final matchedStmt = statementsList.where((s) => s.id == acc.sourceStatementId).firstOrNull;
            if (matchedStmt != null && matchedStmt.periodEnd != null && matchedStmt.periodEnd! > 0) {
              stmtDate = DateTime.fromMillisecondsSinceEpoch(matchedStmt.periodEnd! * 1000);
            }
            if (stmtDate == null) {
              final stmtTxs = txs.where((t) => t.statementId == acc.sourceStatementId).toList();
              if (stmtTxs.isNotEmpty) {
                stmtTxs.sort((a, b) => b.date.compareTo(a.date));
                stmtDate = DateTime.fromMillisecondsSinceEpoch(stmtTxs.first.date * 1000);
              }
            }
          }

          if (stmtDate != null) {
            final stmtMonthStart = DateTime(stmtDate.year, stmtDate.month, 1);
            if (!stmtMonthStart.isAfter(targetEndMonthStart)) {
              if (latestDate == null || stmtDate.isAfter(latestDate)) {
                latestDate = stmtDate;
                latestBal = acc.currentBalance;
              }
            }
          }
        }

        final currencyStr = sampleAcc.currency.trim().toUpperCase();
        if (currencyStr != 'SGD') {
          final rate = fxRates[currencyStr] ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
          colValues.add(latestBal * rate);
        } else {
          colValues.add(latestBal);
        }
      }

      accountRows.add({
        'label': accLabel,
        'values': colValues,
      });
    }

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
          const Text('TOTAL ENDING CASH', style: TextStyle(color: AppColors.proGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          const Text('Sum of Bank Balances + Physical Cash on Hand', style: TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 14),

          // Account Breakdown Sub-Header
          if (accountRows.isNotEmpty) ...[
            const Text('Account Breakdown:', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...accountRows.map((row) {
              final rowLabel = row['label'] as String;
              final values = row['values'] as List<double>;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        '• $rowLabel',
                        style: TextStyle(color: Colors.white70, fontSize: labelSize),
                      ),
                    ),
                    ...values.map((v) => Expanded(
                      flex: 3,
                      child: Text(
                        fmt.format(v),
                        textAlign: TextAlign.right,
                        style: TextStyle(color: v == 0 ? Colors.white38 : const Color(0xFF60A5FA), fontSize: valSize),
                      ),
                    )),
                  ],
                ),
              );
            }),
            const Divider(color: Colors.white24, height: 16),
          ],

          _buildDynamicSubtotalRow('TOTAL ENDING CASH', columns, 'endCash', fmt),
        ],
      ),
    );
  }

  Widget _buildHeaderControls() {
    final isMobile = MediaQuery.of(context).size.width < 480;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.proCardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.proPrimary.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            const Text('Period Horizon', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
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
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 4)),
                ),
              ),
            ),
          ] else ...[
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
          ],
        ],
      ),
    );
  }

  Widget _buildExecutiveSummary(double netCash, double grossIn, double grossOut, double netTransfers, NumberFormat fmt, String monthLabel) {
    final savingsRatio = grossIn > 0 ? ((netCash / grossIn) * 100).clamp(0.0, 100.0) : 0.0;
    final isMobile = MediaQuery.of(context).size.width < 480;

    Widget buildMetricColumn(String title, String valStr, Color valColor, {Widget? extraTitleWidget}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
              if (extraTitleWidget != null) extraTitleWidget,
            ],
          ),
          const SizedBox(height: 2),
          Text(valStr, style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 13)),
        ],
      );
    }

    const tooltipMessage = 'Formula: (Net Cash Flow / Total Income) × 100%\n\nMeasures the percentage of total income retained as net savings after deducting total expenses.';

    final savingsRateTooltip = Tooltip(
      message: tooltipMessage,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.proCardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.proGold),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.proCardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.proGold.withOpacity(0.6)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.proGold, size: 20),
                  SizedBox(width: 8),
                  Text('Net Savings Rate', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                tooltipMessage,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(color: AppColors.proGold, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.all(4.0),
          child: Icon(Icons.info_outline, color: Colors.white54, size: 14),
        ),
      ),
    );

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
            style: TextStyle(
              color: AppColors.white,
              fontSize: isMobile ? 26 : 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (isMobile) ...[
            Row(
              children: [
                Expanded(child: buildMetricColumn('TOTAL INCOME', fmt.format(grossIn), Colors.greenAccent)),
                const SizedBox(width: 8),
                Expanded(child: buildMetricColumn('TOTAL EXPENSES', fmt.format(grossOut), Colors.redAccent)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: buildMetricColumn('TOTAL NET TRANSFERS', fmt.format(netTransfers), Colors.cyanAccent)),
                const SizedBox(width: 8),
                Expanded(child: buildMetricColumn('NET SAVINGS RATE', '${savingsRatio.toStringAsFixed(1)}%', AppColors.proGold, extraTitleWidget: savingsRateTooltip)),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: buildMetricColumn('TOTAL INCOME', fmt.format(grossIn), Colors.greenAccent)),
                Expanded(child: buildMetricColumn('TOTAL EXPENSES', fmt.format(grossOut), Colors.redAccent)),
                Expanded(child: buildMetricColumn('TOTAL NET TRANSFERS', fmt.format(netTransfers), Colors.cyanAccent)),
                Expanded(child: buildMetricColumn('NET SAVINGS RATE', '${savingsRatio.toStringAsFixed(1)}%', AppColors.proGold, extraTitleWidget: savingsRateTooltip)),
              ],
            ),
          ],
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
  Future<Uint8List> _generatePdfDocument(
    String horizonName,
    DateTime selectedMonth,
    List<Map<String, dynamic>> columns,
    List<String> sortedCatNames,
    List<BankAccount> bankAccounts,
    List<Statement> statements,
    List<Transaction> txs,
    Map<String, double> fxRates,
    double realCashBal,
  ) async {
    final pdf = pw.Document();
    final currencyFmt = NumberFormat.currency(symbol: 'S\$', decimalDigits: 2);
    final lastCol = columns.last;
    final netCashFlow = lastCol['netCash'] as double;
    final totalIncome = lastCol['totalInc'] as double;
    final totalExpenses = lastCol['totalExp'] as double;
    final savingsRate = totalIncome > 0 ? ((netCashFlow / totalIncome) * 100).clamp(0.0, 100.0) : 0.0;

    String _normIdentity(BankAccount a) => '${a.bankName.trim()}_${(a.accountNumber ?? '').trim()}'.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

    final Map<String, BankAccount> uniqueAccountSamples = {};
    for (final acc in bankAccounts) {
      final key = _normIdentity(acc);
      if (!uniqueAccountSamples.containsKey(key)) {
        uniqueAccountSamples[key] = acc;
      }
    }

    if (!uniqueAccountSamples.containsKey('physicalcashonhand_cash') &&
        !uniqueAccountSamples.values.any((a) => a.id == 'manual_cash_account')) {
      uniqueAccountSamples['physicalcashonhand_cash'] = BankAccount(
        id: 'manual_cash_account',
        userId: 'chenyee_user',
        bankName: 'Physical Cash on Hand',
        accountType: 'Physical Cash',
        accountNumber: 'Cash',
        currentBalance: realCashBal,
        openingBalance: 0.0,
        currency: 'SGD',
        sourceStatementId: null,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PRO Cash Flow Statement', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800)),
                    pw.SizedBox(height: 2),
                    pw.Text('Period Horizon: $horizonName View', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple800,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Executive Net Cash Flow Card
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey900,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('NET CASH FLOW (${DateFormat('MMM yyyy').format(selectedMonth).toUpperCase()})', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  pw.Text(currencyFmt.format(netCashFlow), style: pw.TextStyle(color: netCashFlow >= 0 ? PdfColors.green300 : PdfColors.red300, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Income: ${currencyFmt.format(totalIncome)}', style: pw.TextStyle(color: PdfColors.green300, fontSize: 8)),
                      pw.Text('Total Expenses: ${currencyFmt.format(totalExpenses)}', style: pw.TextStyle(color: PdfColors.red300, fontSize: 8)),
                      pw.Text('Net Savings Rate: ${savingsRate.toStringAsFixed(1)}%', style: pw.TextStyle(color: PdfColors.amber300, fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // PART I: OPERATING CASH FLOWS (PERSONAL)
            pw.Text('PART I: OPERATING CASH FLOWS (PERSONAL)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.SizedBox(height: 4),

            pw.TableHelper.fromTextArray(
              headers: ['LINE ITEM', ...columns.map((c) => c['label'].toString().replaceAll('\n', ' '))],
              data: [
                ['Salary & Earned Income', ...columns.map((c) => currencyFmt.format(c['salary'] ?? 0.0))],
                ['Interest & Investment Returns', ...columns.map((c) => currencyFmt.format(c['passive'] ?? 0.0))],
                ['Other Inflows', ...columns.map((c) => currencyFmt.format(c['other'] ?? 0.0))],
                ['Total Income', ...columns.map((c) => currencyFmt.format(c['totalInc'] ?? 0.0))],
                ...sortedCatNames.map((cat) => ['  • $cat', ...columns.map((c) => currencyFmt.format(-((c['catMap'] as Map<String, double>)[cat] ?? 0.0)))]),
                ['Total Expenses', ...columns.map((c) => currencyFmt.format(-(c['totalExp'] as double? ?? 0.0)))],
                ['NET CASH FLOW', ...columns.map((c) => currencyFmt.format(c['netCash'] ?? 0.0))],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              headerAlignment: pw.Alignment.centerRight,
              cellAlignment: pw.Alignment.centerRight,
              cellAlignments: {0: pw.Alignment.centerLeft},
              headerAlignments: {0: pw.Alignment.centerLeft},
              columnWidths: {0: const pw.FlexColumnWidth(3)},
            ),
            pw.SizedBox(height: 14),

            // TOTAL ENDING CASH (ACCOUNT BREAKDOWN)
            pw.Text('TOTAL ENDING CASH (ACCOUNT BREAKDOWN)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
            pw.SizedBox(height: 4),

            pw.TableHelper.fromTextArray(
              headers: ['ACCOUNT', ...columns.map((c) => c['label'].toString().replaceAll('\n', ' '))],
              data: [
                ...uniqueAccountSamples.values.map((acc) {
                  final accName = acc.id == 'manual_cash_account' ? 'Physical Cash on Hand' : '${acc.bankName} (${acc.accountNumber ?? ""})';
                  final colVals = columns.asMap().entries.map((entry) {
                    final i = entry.key;
                    if (acc.id == 'manual_cash_account') {
                      final posData = ref.watch(cashPositionProvider).asData?.value;
                      double monthCashVal = 0.0;
                      if (_periodType == 'Month') {
                        if (i == 2) {
                          monthCashVal = posData?.accounts.where((a) => a.id == 'manual_cash_account').firstOrNull?.currentBalance ?? 0.0;
                        } else if (i == 1) {
                          monthCashVal = posData?.prevMonthBalances['manual_cash_account'] ?? 0.0;
                        } else {
                          monthCashVal = posData?.twoMonthsAgoBalances['manual_cash_account'] ?? 0.0;
                        }
                      } else {
                        monthCashVal = posData?.accounts.where((a) => a.id == 'manual_cash_account').firstOrNull?.currentBalance ?? 0.0;
                      }
                      return currencyFmt.format(monthCashVal);
                    }
                    return currencyFmt.format(acc.currentBalance);
                  });
                  return [accName, ...colVals];
                }),
                ['TOTAL ENDING CASH', ...columns.map((c) => currencyFmt.format(c['endCash'] ?? 0.0))],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              headerAlignment: pw.Alignment.centerRight,
              cellAlignment: pw.Alignment.centerRight,
              cellAlignments: {0: pw.Alignment.centerLeft},
              headerAlignments: {0: pw.Alignment.centerLeft},
              columnWidths: {0: const pw.FlexColumnWidth(3)},
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  String _generatePrintableHtmlDoc(
    String horizonName,
    DateTime selectedMonth,
    List<Map<String, dynamic>> columns,
    List<String> sortedCatNames,
    List<BankAccount> bankAccounts,
    List<Statement> statements,
    List<Transaction> txs,
    Map<String, double> fxRates,
  ) {
    final currencyFmt = NumberFormat.currency(symbol: 'S\$', decimalDigits: 2);
    final lastCol = columns.last;
    final netCashFlow = lastCol['netCash'] as double;
    final totalIncome = lastCol['totalInc'] as double;
    final totalExpenses = lastCol['totalExp'] as double;
    final savingsRate = totalIncome > 0 ? ((netCashFlow / totalIncome) * 100).clamp(0.0, 100.0) : 0.0;

    final headerColsHtml = columns.map((col) => '<th style="color: #F59E0B; text-align: right;">${col['label'].toString().replaceAll('\n', '<br/>')}</th>').join('');

    String _buildHtmlRow(String label, String key, {bool isBold = false, bool isPositive = true, bool negate = false}) {
      final cells = columns.map((col) {
        final val = (col[key] as double? ?? 0.0) * (negate ? -1.0 : 1.0);
        final color = val == 0 ? '#94A3B8' : (val > 0 ? '#60A5FA' : '#F87171');
        final weight = isBold ? 'bold' : 'normal';
        return '<td style="text-align: right; color: $color; font-weight: $weight;">${currencyFmt.format(val)}</td>';
      }).join('');

      final rowStyle = isBold ? 'background: #0F172A; font-weight: bold;' : '';
      return '<tr style="$rowStyle"><td>$label</td>$cells</tr>';
    }

    String _buildHtmlCategoryRow(String catName) {
      final cells = columns.map((col) {
        final catMap = col['catMap'] as Map<String, double>? ?? {};
        final val = -(catMap[catName] ?? 0.0);
        final color = val == 0 ? '#94A3B8' : '#F87171';
        return '<td style="text-align: right; color: $color;">${currencyFmt.format(val)}</td>';
      }).join('');
      return '<tr><td style="padding-left: 20px; color: #CBD5E1;">&bull; $catName</td>$cells</tr>';
    }

    final categoryRowsHtml = sortedCatNames.map((cat) => _buildHtmlCategoryRow(cat)).join('');

    // Compute Account Breakdown for Total Ending Cash Section
    final selectedYear = selectedMonth.year;
    final List<DateTime> endMonthDates = [];
    for (int colIdx = 0; colIdx < columns.length; colIdx++) {
      final label = columns[colIdx]['label'] as String;
      if (_periodType == 'Month') {
        if (colIdx == 0) {
          endMonthDates.add(DateTime(selectedMonth.year, selectedMonth.month - 2));
        } else if (colIdx == 1) {
          endMonthDates.add(DateTime(selectedMonth.year, selectedMonth.month - 1));
        } else {
          endMonthDates.add(selectedMonth);
        }
      } else if (_periodType == 'Quarter') {
        int endM = 3;
        if (label.contains('Q1')) endM = 3;
        if (label.contains('Q2')) endM = 6;
        if (label.contains('Q3')) endM = 9;
        if (label.contains('Q4')) endM = 12;
        endMonthDates.add(DateTime(selectedYear, endM));
      } else {
        endMonthDates.add(DateTime(selectedYear, 12));
      }
    }

    String _normIdentity(BankAccount a) => '${a.bankName.trim()}_${(a.accountNumber ?? '').trim()}'.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

    final Map<String, BankAccount> uniqueAccountSamples = {};
    for (final acc in bankAccounts) {
      final key = _normIdentity(acc);
      if (!uniqueAccountSamples.containsKey(key)) {
        uniqueAccountSamples[key] = acc;
      }
    }

    final realCashAcc = bankAccounts.where((a) => a.id == 'manual_cash_account').firstOrNull;
    final realCashBal = realCashAcc?.currentBalance ?? 30.0;

    if (!uniqueAccountSamples.containsKey('physicalcashonhand_cash') &&
        !uniqueAccountSamples.values.any((a) => a.id == 'manual_cash_account')) {
      uniqueAccountSamples['physicalcashonhand_cash'] = BankAccount(
        id: 'manual_cash_account',
        userId: 'chenyee_user',
        bankName: 'Physical Cash on Hand',
        accountType: 'Physical Cash',
        accountNumber: 'Cash',
        currentBalance: realCashBal,
        openingBalance: 0.0,
        currency: 'SGD',
        sourceStatementId: null,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    String accountBreakdownRowsHtml = '';
    for (final identity in uniqueAccountSamples.keys) {
      final sampleAcc = uniqueAccountSamples[identity]!;
      final accLabel = sampleAcc.id == 'manual_cash_account'
          ? 'Physical Cash on Hand'
          : '${sampleAcc.bankName} (${sampleAcc.accountNumber ?? ""})'.trim();

      final cells = columns.asMap().entries.map((entry) {
        final i = entry.key;
        final targetEndMonth = endMonthDates[i];
        final targetEndMonthStart = DateTime(targetEndMonth.year, targetEndMonth.month, 1);

        double latestBal = 0.0;
        if (sampleAcc.id == 'manual_cash_account') {
          latestBal = sampleAcc.currentBalance > 0 ? sampleAcc.currentBalance : realCashBal;
        } else {
          DateTime? latestDate;
          for (final acc in bankAccounts) {
            if (_normIdentity(acc) != identity) continue;
            DateTime? stmtDate;
            if (acc.sourceStatementId != null) {
              final matchedStmt = statements.where((s) => s.id == acc.sourceStatementId).firstOrNull;
              if (matchedStmt != null && matchedStmt.periodEnd != null && matchedStmt.periodEnd! > 0) {
                stmtDate = DateTime.fromMillisecondsSinceEpoch(matchedStmt.periodEnd! * 1000);
              }
              if (stmtDate == null) {
                final stmtTxs = txs.where((t) => t.statementId == acc.sourceStatementId).toList();
                if (stmtTxs.isNotEmpty) {
                  stmtTxs.sort((a, b) => b.date.compareTo(a.date));
                  stmtDate = DateTime.fromMillisecondsSinceEpoch(stmtTxs.first.date * 1000);
                }
              }
            }
            if (stmtDate != null) {
              final stmtMonthStart = DateTime(stmtDate.year, stmtDate.month, 1);
              if (!stmtMonthStart.isAfter(targetEndMonthStart)) {
                if (latestDate == null || stmtDate.isAfter(latestDate)) {
                  latestDate = stmtDate;
                  latestBal = acc.currentBalance;
                }
              }
            }
          }
        }

        final currencyStr = sampleAcc.currency.trim().toUpperCase();
        double val = latestBal;
        if (currencyStr != 'SGD') {
          final rate = fxRates[currencyStr] ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
          val = latestBal * rate;
        }
        final color = val == 0 ? '#94A3B8' : '#60A5FA';
        return '<td style="text-align: right; color: $color;">${currencyFmt.format(val)}</td>';
      }).join('');

      accountBreakdownRowsHtml += '<tr><td style="padding-left: 20px; color: #CBD5E1;">&bull; $accLabel</td>$cells</tr>';
    }

    final totalEndingCashCells = columns.map((col) {
      final val = col['endCash'] as double? ?? 0.0;
      return '<td style="text-align: right; color: #60A5FA; font-weight: bold;">${currencyFmt.format(val)}</td>';
    }).join('');

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>CashFlow AI - $horizonName Statement (${DateFormat('yyyy-MM').format(selectedMonth)})</title>
  <style>
    @page { size: A4 landscape; margin: 8mm; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #0F172A; color: #FFFFFF; padding: 16px; font-size: 11px; }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #7C3AED; padding-bottom: 10px; margin-bottom: 16px; }
    .title { font-size: 20px; font-weight: bold; color: #F59E0B; }
    .badge { background: #7C3AED; color: #FFF; padding: 4px 10px; border-radius: 6px; font-size: 11px; font-weight: bold; }
    .summary-card { background: #1E293B; border: 1px solid #7C3AED; border-radius: 10px; padding: 12px; margin-bottom: 16px; }
    .section-title { color: #A78BFA; font-size: 13px; font-weight: bold; margin: 14px 0 6px 0; border-bottom: 1px solid #334155; padding-bottom: 4px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 16px; background: #1E293B; border-radius: 8px; overflow: hidden; }
    th { background: #0F172A; color: #94A3B8; font-size: 10px; text-transform: uppercase; padding: 8px; border-bottom: 1px solid #334155; }
    th:first-child { text-align: left; }
    td { padding: 6px 8px; border-bottom: 1px solid #334155; color: #E2E8F0; }
    td:first-child { text-align: left; font-weight: 500; }
    .footer { text-align: center; color: #64748B; font-size: 9px; margin-top: 16px; }
    @media print {
      body { background: #0F172A !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
    }
  </style>
</head>
<body>
  <div class="header">
    <div>
      <div class="title">PRO Cash Flow Statement</div>
      <div style="color: #94A3B8; font-size: 11px; margin-top: 2px;">Period Horizon: $horizonName View</div>
    </div>
    <div class="badge">${DateFormat('MMMM yyyy').format(selectedMonth)}</div>
  </div>

  <div class="summary-card">
    <div style="font-size: 10px; color: #94A3B8; text-transform: uppercase; font-weight: bold;">NET CASH FLOW (${lastCol['label'].toString().replaceAll('\n', ' ')})</div>
    <div style="font-size: 22px; font-weight: bold; color: #F59E0B; margin: 4px 0;">${currencyFmt.format(netCashFlow)}</div>
    <div style="display: flex; gap: 20px; font-size: 10.5px; color: #E2E8F0; margin-top: 8px; flex-wrap: wrap;">
      <div>Total Income: <span style="color: #4ADE80; font-weight: bold;">${currencyFmt.format(totalIncome)}</span></div>
      <div>Total Expenses: <span style="color: #F87171; font-weight: bold;">${currencyFmt.format(totalExpenses)}</span></div>
      <div>Total Net Transfers: <span style="color: #60A5FA; font-weight: bold;">S\$0.00</span></div>
      <div>Net Savings Rate: <span style="color: #38BDF8; font-weight: bold;">${savingsRate.toStringAsFixed(1)}%</span></div>
    </div>
  </div>

  <div class="section-title">PART I: OPERATING CASH FLOWS (PERSONAL)</div>
  <table>
    <thead>
      <tr>
        <th>Line Item</th>
        $headerColsHtml
      </tr>
    </thead>
    <tbody>
      ${_buildHtmlRow('Salary & Earned Income', 'salary')}
      ${_buildHtmlRow('Interest & Investment Returns', 'passive')}
      ${_buildHtmlRow('Other Inflows', 'other')}
      ${_buildHtmlRow('Total Income', 'totalInc', isBold: true)}
      $categoryRowsHtml
      ${_buildHtmlRow('Total Expenses', 'totalExp', isBold: true, negate: true)}
      ${_buildHtmlRow('NET CASH FLOW', 'netCash', isBold: true)}
    </tbody>
  </table>

  <div class="section-title">TOTAL CASH POSITIONS</div>
  <table>
    <thead>
      <tr>
        <th>Line Item</th>
        $headerColsHtml
      </tr>
    </thead>
    <tbody>
      ${_buildHtmlRow('Beginning cash', 'begCash')}
      ${_buildHtmlRow('New cash positions added', 'newCashPos')}
      ${_buildHtmlRow('Total Income', 'totalInc')}
      ${_buildHtmlRow('Total Expenses', 'totalExp', negate: true)}
      ${_buildHtmlRow('Ending cash balance', 'endCash', isBold: true)}
    </tbody>
  </table>

  <div class="section-title">TOTAL ENDING CASH</div>
  <div style="font-size: 10px; color: #94A3B8; margin-bottom: 6px;">Sum of Bank Balances + Physical Cash on Hand</div>
  <table>
    <thead>
      <tr>
        <th>Line Item</th>
        $headerColsHtml
      </tr>
    </thead>
    <tbody>
      ${accountBreakdownRowsHtml.isNotEmpty ? '<tr><td colspan="${columns.length + 1}" style="font-weight: bold; color: #94A3B8; background: #0F172A;">Account Breakdown:</td></tr>' + accountBreakdownRowsHtml : ''}
      <tr style="background: #0F172A; font-weight: bold;">
        <td style="color: #F59E0B;">TOTAL ENDING CASH</td>
        $totalEndingCashCells
      </tr>
    </tbody>
  </table>

  <div class="footer">Generated by CashFlow AI™ &bull; ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}</div>
  <script>
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 500);
    };
  </script>
</body>
</html>''';
  }

  Future<List<int>> _generateBinaryPdfBytes(
    String horizonName,
    DateTime selectedMonth,
    List<Map<String, dynamic>> columns,
    List<String> sortedCatNames,
  ) async {
    final pdf = pw.Document();
    final currencyFmt = NumberFormat.currency(symbol: 'S\$', decimalDigits: 2);
    final lastCol = columns.last;
    final netCashFlow = lastCol['netCash'] as double;
    final totalIncome = lastCol['totalInc'] as double;
    final totalExpenses = lastCol['totalExp'] as double;
    final savingsRate = totalIncome > 0 ? ((netCashFlow / totalIncome) * 100).clamp(0.0, 100.0) : 0.0;

    final primaryColor = PdfColor.fromHex('7C3AED');
    final darkBg = PdfColor.fromHex('0F172A');
    final cardBg = PdfColor.fromHex('1E293B');
    final goldColor = PdfColor.fromHex('F59E0B');
    final textWhite = PdfColor.fromHex('FFFFFF');
    final textMuted = PdfColor.fromHex('94A3B8');
    final greenColor = PdfColor.fromHex('4ADE80');
    final redColor = PdfColor.fromHex('F87171');
    final cyanColor = PdfColor.fromHex('38BDF8');

    List<pw.Widget> buildTableSection(String title, List<Map<String, String>> rowDefs) {
      return [
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
          child: pw.Text(
            title,
            style: pw.TextStyle(color: primaryColor, fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('334155'), width: 0.5),
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: darkBg),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Line Item', style: pw.TextStyle(color: textMuted, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
                ...columns.map((col) => pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        col['label'].toString().replaceAll('\n', ' '),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(color: goldColor, fontSize: 8, fontWeight: pw.FontWeight.bold),
                      ),
                    )),
              ],
            ),
            // Data rows
            ...rowDefs.map((def) {
              final label = def['label']!;
              final key = def['key']!;
              final isBold = def['isBold'] == 'true';
              final negate = def['negate'] == 'true';

              return pw.TableRow(
                decoration: pw.BoxDecoration(color: isBold ? darkBg : cardBg),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      label,
                      style: pw.TextStyle(
                        color: textWhite,
                        fontSize: 7.5,
                        fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                      ),
                    ),
                  ),
                  ...columns.map((col) {
                    double val = 0.0;
                    if (key.startsWith('cat_')) {
                      final catName = key.replaceFirst('cat_', '');
                      final catMap = col['catMap'] as Map<String, double>? ?? {};
                      val = -(catMap[catName] ?? 0.0);
                    } else {
                      val = (col[key] as double? ?? 0.0) * (negate ? -1.0 : 1.0);
                    }
                    final color = val == 0 ? textMuted : (val > 0 ? cyanColor : redColor);
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        currencyFmt.format(val),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          color: color,
                          fontSize: 7.5,
                          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ];
    }

    // Build Part I row definitions
    final part1Rows = <Map<String, String>>[
      {'label': 'Salary & Earned Income', 'key': 'salary'},
      {'label': 'Interest & Investment Returns', 'key': 'passive'},
      {'label': 'Other Inflows', 'key': 'other'},
      {'label': 'Total Income', 'key': 'totalInc', 'isBold': 'true'},
    ];

    for (final cat in sortedCatNames) {
      part1Rows.add({'label': '  • $cat', 'key': 'cat_$cat', 'negate': 'true'});
    }
    part1Rows.add({'label': 'Total Expenses', 'key': 'totalExp', 'isBold': 'true', 'negate': 'true'});
    part1Rows.add({'label': 'NET CASH FLOW', 'key': 'netCash', 'isBold': 'true'});

    // Part II row definitions
    final part2Rows = <Map<String, String>>[
      {'label': 'Beginning cash', 'key': 'begCash'},
      {'label': 'New cash positions added', 'key': 'newCashPos'},
      {'label': 'Total Income', 'key': 'totalInc'},
      {'label': 'Total Expenses', 'key': 'totalExp', 'negate': 'true'},
      {'label': 'Ending cash balance', 'key': 'endCash', 'isBold': 'true'},
    ];

    // Use MultiPage so content flows across pages automatically
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PRO Cash Flow Statement', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: goldColor)),
                    pw.SizedBox(height: 2),
                    pw.Text('Period Horizon: $horizonName View', style: pw.TextStyle(fontSize: 9, color: textMuted)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Text(DateFormat('MMMM yyyy').format(selectedMonth), style: pw.TextStyle(color: textWhite, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Executive Summary box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: cardBg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: primaryColor, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('NET CASH FLOW', style: pw.TextStyle(color: textMuted, fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(currencyFmt.format(netCashFlow), style: pw.TextStyle(color: goldColor, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Text('Total Income: ', style: pw.TextStyle(color: textMuted, fontSize: 8)),
                      pw.Text(currencyFmt.format(totalIncome), style: pw.TextStyle(color: greenColor, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 16),
                      pw.Text('Total Expenses: ', style: pw.TextStyle(color: textMuted, fontSize: 8)),
                      pw.Text(currencyFmt.format(totalExpenses), style: pw.TextStyle(color: redColor, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 16),
                      pw.Text('Net Savings Rate: ', style: pw.TextStyle(color: textMuted, fontSize: 8)),
                      pw.Text('${savingsRate.toStringAsFixed(1)}%', style: pw.TextStyle(color: cyanColor, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            // Part I Table
            ...buildTableSection('PART I: OPERATING CASH FLOWS (PERSONAL)', part1Rows),

            // Part II Table
            ...buildTableSection('TOTAL CASH POSITIONS', part2Rows),

            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text('Generated by CashFlow AI\u2122 \u2022 ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: pw.TextStyle(color: textMuted, fontSize: 7)),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
