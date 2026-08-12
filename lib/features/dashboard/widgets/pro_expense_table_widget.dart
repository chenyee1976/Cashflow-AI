import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/category_enum.dart';
import '../../cashflow/statement/cashflow_provider.dart';

class ProExpenseTableWidget extends ConsumerWidget {
  final bool isCompact;
  const ProExpenseTableWidget({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final cashFlowAsync = ref.watch(cashFlowScreenProvider);
    final currencyFormat = NumberFormat.currency(locale: 'en_SG', symbol: 'S\$', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.proCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.proBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: cashFlowAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: AppColors.proPrimary)),
        ),
        error: (err, stack) => SizedBox(
          height: 200,
          child: Center(child: Text('Error loading expense table: $err', style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
        ),
        data: (state) {
          final txs = state.allTransactions;

          // 1. Current Month Expenses by Category
          final currentMonthTxs = txs.where((t) {
            final d = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
            return d.year == selectedMonth.year && d.month == selectedMonth.month;
          }).toList();

          final Map<String, double> currentCategoryExpenses = {};
          for (final t in currentMonthTxs) {
            if ((t.amount < 0 || TransactionCategory.fromValue(t.category).isExpense) &&
                t.category != TransactionCategory.incomeTransfer.value &&
                t.category != TransactionCategory.expenseTransfer.value) {
              final name = TransactionCategory.fromValue(t.category).displayName;
              currentCategoryExpenses[name] = (currentCategoryExpenses[name] ?? 0.0) + t.amount.abs();
            }
          }

          // 2. Compute 6-Month Baseline Averages per Category
          final Map<String, double> category6MoTotals = {};
          final now = selectedMonth;
          for (int i = 0; i < 6; i++) {
            final targetM = DateTime(now.year, now.month - i, 1);
            final mTransactions = txs.where((t) {
              final d = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
              return d.year == targetM.year && d.month == targetM.month;
            });
            for (final t in mTransactions) {
              if ((t.amount < 0 || TransactionCategory.fromValue(t.category).isExpense) &&
                  t.category != TransactionCategory.incomeTransfer.value &&
                  t.category != TransactionCategory.expenseTransfer.value) {
                final name = TransactionCategory.fromValue(t.category).displayName;
                category6MoTotals[name] = (category6MoTotals[name] ?? 0.0) + t.amount.abs();
              }
            }
          }

          final List<_ExpenseRowItem> rows = [];
          currentCategoryExpenses.forEach((catName, currentVal) {
            final total6Mo = category6MoTotals[catName] ?? currentVal;
            final avg6Mo = total6Mo / 6.0;
            final variancePct = avg6Mo > 0 ? ((currentVal - avg6Mo) / avg6Mo) * 100 : 0.0;
            rows.add(_ExpenseRowItem(
              category: catName,
              currentAmount: currentVal,
              avg6MonthAmount: avg6Mo,
              variancePercentage: variancePct,
            ));
          });

          // Sort by highest expense
          rows.sort((a, b) => b.currentAmount.compareTo(a.currentAmount));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: AppColors.proGoldGradient,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Categorized Expense Variance',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.proSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.proBorder),
                    ),
                    child: const Text(
                      'vs 6-Mo Baseline',
                      style: TextStyle(color: AppColors.proSubtext, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 14),
              if (rows.isEmpty)
                const SizedBox(
                  height: 120,
                  child: Center(
                    child: Text(
                      'No expenses recorded for this month.',
                      style: TextStyle(color: AppColors.proSubtext, fontSize: 13),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.proBorder, width: 1)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('CATEGORY', style: TextStyle(color: AppColors.proSubtext, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('CURRENT', textAlign: TextAlign.right, style: TextStyle(color: AppColors.proSubtext, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('6-MO AVG', textAlign: TextAlign.right, style: TextStyle(color: AppColors.proSubtext, fontSize: 10, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('VARIANCE', textAlign: TextAlign.right, style: TextStyle(color: AppColors.proSubtext, fontSize: 10, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    // Rows
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: isCompact && rows.length > 5 ? 5 : rows.length,
                      itemBuilder: (context, idx) {
                        final item = rows[idx];
                        final isAlert = item.variancePercentage > 15.0;
                        final isPositive = item.variancePercentage < 0;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.category,
                                  style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  currencyFormat.format(item.currentAmount),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  currencyFormat.format(item.avg6MonthAmount),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: AppColors.proSubtext, fontSize: 11),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isAlert)
                                      const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFEF4444)),
                                    Text(
                                      '${item.variancePercentage > 0 ? "+" : ""}${item.variancePercentage.toStringAsFixed(0)}%',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: isAlert
                                            ? const Color(0xFFEF4444)
                                            : isPositive
                                                ? const Color(0xFF10B981)
                                                : AppColors.proSubtext,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ExpenseRowItem {
  final String category;
  final double currentAmount;
  final double avg6MonthAmount;
  final double variancePercentage;

  const _ExpenseRowItem({
    required this.category,
    required this.currentAmount,
    required this.avg6MonthAmount,
    required this.variancePercentage,
  });
}
