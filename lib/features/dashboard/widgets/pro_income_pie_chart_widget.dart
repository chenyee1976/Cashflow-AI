import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/category_enum.dart';
import '../../cashflow/statement/cashflow_provider.dart';

class ProIncomePieChartWidget extends ConsumerStatefulWidget {
  final bool isCompact;
  const ProIncomePieChartWidget({super.key, this.isCompact = false});

  @override
  ConsumerState<ProIncomePieChartWidget> createState() => _ProIncomePieChartWidgetState();
}

class _ProIncomePieChartWidgetState extends ConsumerState<ProIncomePieChartWidget> {
  int _touchedIndex = -1;

  static const List<Color> _sliceColors = [
    Color(0xFF10B981), // Emerald Green
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
  ];

  @override
  Widget build(BuildContext context) {
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
      padding: EdgeInsets.all(widget.isCompact ? 12 : 16),
      child: cashFlowAsync.when(
        loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: AppColors.proPrimary)),
        ),
        error: (err, stack) => SizedBox(
          height: 200,
          child: Center(child: Text('Error loading income breakdown: $err', style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
        ),
        data: (state) {
          final txs = state.allTransactions;

          final monthTxs = txs.where((t) {
            final d = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
            return d.year == selectedMonth.year && d.month == selectedMonth.month;
          }).toList();

          final incomeTxs = monthTxs.where((t) =>
              TransactionCategory.fromValue(t.category).isIncome &&
              t.category != TransactionCategory.incomeTransfer.value).toList();

          final Map<String, double> categoryTotals = {};
          double totalIncome = 0.0;

          for (final t in incomeTxs) {
            final catEnum = TransactionCategory.fromValue(t.category);
            final name = catEnum.displayName;
            categoryTotals[name] = (categoryTotals[name] ?? 0.0) + t.amount;
            totalIncome += t.amount;
          }

          final entries = categoryTotals.entries.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                    'Income Sources Breakdown',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: widget.isCompact ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (entries.isEmpty || totalIncome <= 0)
                const SizedBox(
                  height: 160,
                  child: Center(
                    child: Text(
                      'No income records found for this period.',
                      style: TextStyle(color: AppColors.proSubtext, fontSize: 13),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    SizedBox(
                      height: widget.isCompact ? 160 : 190,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 3,
                              centerSpaceRadius: widget.isCompact ? 45 : 55,
                              sections: List.generate(entries.length, (i) {
                                final isTouched = i == _touchedIndex;
                                final radius = isTouched ? (widget.isCompact ? 35.0 : 42.0) : (widget.isCompact ? 28.0 : 35.0);
                                final entry = entries[i];
                                final pct = (entry.value / totalIncome) * 100;
                                final color = _sliceColors[i % _sliceColors.length];

                                return PieChartSectionData(
                                  color: color,
                                  value: entry.value,
                                  title: '${pct.toStringAsFixed(0)}%',
                                  radius: radius,
                                  titleStyle: TextStyle(
                                    fontSize: isTouched ? 13 : 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                );
                              }),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Total Income', style: TextStyle(color: AppColors.proSubtext, fontSize: 10)),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormat.format(totalIncome),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: List.generate(entries.length, (i) {
                        final entry = entries[i];
                        final color = _sliceColors[i % _sliceColors.length];
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(
                              '${entry.key}: ${currencyFormat.format(entry.value)}',
                              style: const TextStyle(color: AppColors.proSubtext, fontSize: 11),
                            ),
                          ],
                        );
                      }),
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
