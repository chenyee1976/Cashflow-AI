import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/category_enum.dart';
import '../../cashflow/statement/cashflow_provider.dart';

class Pro6MonthCashflowChartWidget extends ConsumerWidget {
  final bool isCompact;
  const Pro6MonthCashflowChartWidget({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: Center(child: Text('Error loading chart: $err', style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
        ),
        data: (state) {
          final txs = state.allTransactions;
          final now = DateTime.now();

          // Collect last 6 months
          final List<DateTime> months = [];
          for (int i = 5; i >= 0; i--) {
            months.add(DateTime(now.year, now.month - i, 1));
          }

          double maxAmount = 1000;
          final List<BarChartGroupData> barGroups = [];

          for (int i = 0; i < months.length; i++) {
            final m = months[i];
            final mTransactions = txs.where((t) {
              final d = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
              return d.year == m.year && d.month == m.month;
            }).toList();

            final income = mTransactions
                .where((t) => TransactionCategory.fromValue(t.category).isIncome && t.category != TransactionCategory.incomeTransfer.value)
                .fold<double>(0.0, (sum, t) => sum + t.amount);

            final expense = mTransactions
                .where((t) => (t.amount < 0 || TransactionCategory.fromValue(t.category).isExpense) && t.category != TransactionCategory.incomeTransfer.value && t.category != TransactionCategory.expenseTransfer.value)
                .fold<double>(0.0, (sum, t) => sum + t.amount.abs());

            if (income > maxAmount) maxAmount = income;
            if (expense > maxAmount) maxAmount = expense;

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: income,
                    color: const Color(0xFF10B981), // Green for Income
                    width: isCompact ? 8 : 12,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  BarChartRodData(
                    toY: expense,
                    color: const Color(0xFFEF4444), // Red for Expense
                    width: isCompact ? 8 : 12,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            );
          }

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
                        '6-Month Cash Flow Trend',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _legendItem('Income', const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _legendItem('Expenses', const Color(0xFFEF4444)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: isCompact ? 180 : 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxAmount * 1.15,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.proSurface,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label = rodIndex == 0 ? 'Income' : 'Expense';
                          return BarTooltipItem(
                            '$label: ${currencyFormat.format(rod.toY)}',
                            const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < months.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('MMM').format(months[idx]),
                                  style: const TextStyle(color: AppColors.proSubtext, fontSize: 11),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Text(
                              NumberFormat.compactCurrency(symbol: 'S\$').format(value),
                              style: const TextStyle(color: AppColors.proSubtext, fontSize: 9),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.proBorder.withOpacity(0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.proSubtext, fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
