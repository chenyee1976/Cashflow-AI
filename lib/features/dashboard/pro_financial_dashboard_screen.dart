import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../cashflow/statement/cashflow_provider.dart';
import 'widgets/pro_6month_cashflow_chart_widget.dart';
import 'widgets/pro_income_pie_chart_widget.dart';
import 'widgets/pro_expense_table_widget.dart';

class ProFinancialDashboardScreen extends ConsumerStatefulWidget {
  const ProFinancialDashboardScreen({super.key});

  @override
  ConsumerState<ProFinancialDashboardScreen> createState() => _ProFinancialDashboardScreenState();
}

class _ProFinancialDashboardScreenState extends ConsumerState<ProFinancialDashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
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
              'Pro Financial Analytics',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector bar matching Pro statement
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.proCardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.proBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.proGold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM yyyy').format(selectedMonth),
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/home/cashflow/statement'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.proGoldGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.article_outlined, size: 14, color: AppColors.proBackground),
                          SizedBox(width: 4),
                          Text(
                            'Full Statement',
                            style: TextStyle(
                              color: AppColors.proBackground,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 1. 6-Month Cash Flow Bar Chart
            const Pro6MonthCashflowChartWidget(),
            const SizedBox(height: 20),

            // 2. Income Pie Chart Widget
            const ProIncomePieChartWidget(),
            const SizedBox(height: 20),

            // 3. Categorized Expense Table Widget
            const ProExpenseTableWidget(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
