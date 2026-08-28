import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/category_enum.dart';
import '../../../data/services/analytics_service.dart';
import '../../../shared/widgets/app_header_brand.dart';
import '../../../shared/widgets/app_footer_brand.dart';
import 'cashflow_provider.dart';
import '../../../data/database/app_database.dart';
import '../../dashboard/dashboard_provider.dart';
import '../../../data/secure_storage/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CashFlowHomeScreen extends ConsumerWidget {
  const CashFlowHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final currentFilter = ref.watch(cashFlowFilterProvider);
    final cashFlowAsync = ref.watch(cashFlowScreenProvider);
    final operations = ref.read(cashFlowOperationsProvider);

    final currencyFormatter = NumberFormat.currency(locale: 'en_SG', symbol: 'S\$');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0),
              child: const AppHeaderBrand(),
            ),
            // 1. Header Title & Add Button
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Cash Flow',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push('/home/cashflow/statement'),
                        icon: const Icon(Icons.verified, size: 13, color: AppColors.proGold),
                        label: const Text('Pro Statement', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.proBackground,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: AppColors.proPrimary, width: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton.icon(
                        onPressed: () => _showAddTransactionBottomSheet(context, ref),
                        icon: const Icon(Icons.add, size: 14, color: AppColors.white),
                        label: const Text('Add', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Static Month Navigation Slider (Always visible regardless of async state)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                      onPressed: () {
                        ref.read(selectedMonthProvider.notifier).state =
                            DateTime(selectedMonth.year, selectedMonth.month - 1);
                      },
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(selectedMonth),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      onPressed: () {
                        ref.read(selectedMonthProvider.notifier).state =
                            DateTime(selectedMonth.year, selectedMonth.month + 1);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Main scrollable content
            Expanded(
              child: cashFlowAsync.when(
                data: (data) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 3. Side-by-side Income & Expense cards
                      // 3. Summary Cards (Income / Expenses)
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'INCOME',
                              value: currencyFormatter.format(data.totalIncome),
                              icon: Icons.arrow_downward,
                              iconColor: AppColors.primary,
                              bgColor: const Color(0xFFF1F8FF),
                              textColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              label: 'EXPENSES',
                              value: '-S\$${NumberFormat('#,##0.00').format(data.totalExpenses.abs())}',
                              icon: Icons.arrow_upward,
                              iconColor: AppColors.error,
                              bgColor: const Color(0xFFFFF5F5),
                              textColor: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 4. Net Cash Flow
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.description, size: 16, color: AppColors.textSecondary),
                                SizedBox(width: 8),
                                Text(
                                  'NET CASH FLOW',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormatter.format(data.netCashFlow),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: data.netCashFlow >= 0 ? AppColors.primary : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Transfer Mismatch Warning (if transfers don't offset to 0)
                      if (data.transferMismatch > 0) ...[
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
                                  'Internal transfers do not net to zero (S\$${data.transferMismatch.toStringAsFixed(2)} mismatch). Tap "+ Add" to manually offset.',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 6. Top Categories Card
                      if (data.topCategories.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOP CATEGORIES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...data.topCategories.take(3).map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item.categoryName,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              currencyFormatter.format(item.amount),
                                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: item.percentage,
                                            minHeight: 6,
                                            backgroundColor: const Color(0xFFE2E8F0),
                                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 7. Pill segmented selector filters with (+) and (📥) icon buttons
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: _buildFilterTab(ref, 'All', 'all', currentFilter)),
                                  const SizedBox(width: 2),
                                  Expanded(child: _buildFilterTab(ref, 'Income', 'income', currentFilter)),
                                  const SizedBox(width: 2),
                                  Expanded(child: _buildFilterTab(ref, 'Expenses', 'expense', currentFilter)),
                                  const SizedBox(width: 2),
                                  Expanded(child: _buildFilterTab(ref, 'Transfers', 'transfer', currentFilter)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // 7b. Inline Circular Action Icons: (+) Add Manual & (📥) Export CSV
                          Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _showAddTransactionBottomSheet(context, ref),
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  tooltip: 'Add Manual Transaction',
                                ),
                                IconButton(
                                  onPressed: () async {
                                    final buffer = StringBuffer();
                                    buffer.writeln('Date,Merchant,Amount,Category,Transaction Type');
                                    for (final tx in data.transactions) {
                                      final isInc = tx.amount > 0;
                                      final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(tx.date * 1000));
                                      final merchantEscaped = tx.merchant.replaceAll('"', '""');
                                      final cat = TransactionCategory.fromValue(tx.category).displayName;
                                      final typeStr = isInc ? 'Income' : 'Expense';
                                      buffer.writeln('"$dateStr","$merchantEscaped",${tx.amount},"$cat","$typeStr"');
                                    }

                                    final bytes = const Utf8Encoder().convert(buffer.toString());
                                    final fileName = 'CashFlow_${currentFilter.toUpperCase()}_${selectedMonth.year}_${selectedMonth.month}.csv';

                                    try {
                                      if (kIsWeb) {
                                        final blob = html.Blob([bytes], 'text/csv');
                                        final url = html.Url.createObjectUrlFromBlob(blob);
                                        final anchor = html.AnchorElement(href: url)
                                          ..setAttribute('download', fileName)
                                          ..click();
                                        html.Url.revokeObjectUrl(url);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Downloaded: $fileName')),
                                        );
                                      } else {
                                        final dir = await getApplicationDocumentsDirectory();
                                        final file = File('${dir.path}/$fileName');
                                        await file.writeAsBytes(bytes);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Saved to: ${file.path}')),
                                        );
                                      }
                                      ref.read(analyticsServiceProvider).logEvent('csv_exported', parameters: {
                                        'filter': currentFilter,
                                        'month': '${selectedMonth.year}-${selectedMonth.month}',
                                        'count': data.transactions.length,
                                      });
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Download failed: $e')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download_for_offline_outlined, size: 20, color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  tooltip: 'Export CSV Data',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 7b. Transfer net-off check warning message inside Transfers tab view
                      if (currentFilter == 'transfer' && data.transferMismatch > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Transfers do not net to zero',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'You have an imbalance of S\$${data.transferMismatch.toStringAsFixed(2)}. Tap "+ Add" to input manually the netting transaction.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                       // 8. Dynamic Transactions detail items
                      if (data.transactions.isEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'No transactions in this period.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddTransactionBottomSheet(context, ref),
                                    icon: const Icon(Icons.add, size: 16, color: AppColors.white),
                                    label: const Text('Add manual transaction', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      context.go('/home/cashflow/upload');
                                    },
                                    icon: const Icon(Icons.upload_file_rounded, size: 16, color: AppColors.primary),
                                    label: const Text(
                                      'Upload a statement',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      else
                        Builder(
                          builder: (context) {
                            // Group filtered transactions by account name:
                            final grouped = <String, List<Transaction>>{};
                            for (final tx in data.transactions) {
                              final name = data.accountNamesMap[tx.accountId] ?? 'Cash on hand / Manual Entries';
                              grouped.putIfAbsent(name, () => []).add(tx);
                            }

                            final sortedGroupNames = grouped.keys.toList()..sort();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sortedGroupNames.map<Widget>((groupName) {
                                final txs = grouped[groupName]!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 4.0),
                                      child: Text(
                                        groupName.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    ...txs.map((tx) {
                                      final isIncome = tx.amount > 0;
                                      final amountColor = isIncome ? AppColors.primary : Colors.red;
                                      final amountSign = isIncome ? '+' : '-';
                                      final category = TransactionCategory.fromValue(tx.category);

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.divider),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: const BoxDecoration(
                                                color: AppColors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                                color: isIncome ? AppColors.primary : AppColors.textSecondary,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tx.merchant,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      height: 1.2,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${DateFormat('d MMM').format(DateTime.fromMillisecondsSinceEpoch(tx.date * 1000))} · ${category.displayName}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '$amountSign${currencyFormatter.format(tx.amount.abs())}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: amountColor,
                                                    fontSize: 14,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        _showEditTransactionBottomSheet(context, ref, tx);
                                                      },
                                                    ),
                                                    const SizedBox(width: 8),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () async {
                                                        final confirm = await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) => AlertDialog(
                                                            title: const Text('Delete Transaction'),
                                                            content: const Text('Are you sure you want to delete this transaction?'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.of(ctx).pop(false),
                                                                child: const Text('Cancel'),
                                                              ),
                                                              TextButton(
                                                                onPressed: () => Navigator.of(ctx).pop(true),
                                                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                                child: const Text('Delete'),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                        if (confirm == true) {
                                                          ref.read(analyticsServiceProvider).logEvent('transaction_deleted', parameters: {
                                                            'transactionId': tx.id,
                                                            'category': tx.category,
                                                          });
                                                          operations.deleteTransaction(tx.id);
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }).toList(),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      const AppFooterBrand(),
                    ],
                  ),
                ),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
                error: (e, stackTrace) {
                  // Print full error for debugging
                  debugPrint('CashFlow Error: $e');
                  debugPrint('CashFlow StackTrace: $stackTrace');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading cash flow data:\n$e',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(cashFlowScreenProvider),
                            icon: const Icon(Icons.refresh, color: AppColors.white),
                            label: const Text('Retry', style: TextStyle(color: AppColors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          const AppFooterBrand(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    Color textColor = AppColors.textPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Icon(icon, size: 12, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(WidgetRef ref, String title, String value, String currentValue) {
    final isSelected = currentValue == value;
    return InkWell(
      onTap: () {
        ref.read(cashFlowFilterProvider.notifier).state = value;
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: AppColors.primary.withOpacity(0.35), width: 1) : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTransactionBottomSheet(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final storage = ref.read(secureStorageProvider);
    final prefs = await SharedPreferences.getInstance();
    final testerEmail = prefs.getString('tester_email') ?? '';
    var cfUserId = await storage.getUserId();
    if (cfUserId == null || cfUserId.isEmpty || cfUserId == 'unknown_user') {
      cfUserId = testerEmail.contains('@') ? 'tester_${testerEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}' : 'chenyee_user';
    }
    final bankAccounts = await db.getBankAccountsByUser(cfUserId);
    final creditCards = await db.getCreditCardsByUser(cfUserId);

    final accountOptions = <Map<String, String>>[
      {'id': 'manual_cash', 'name': 'Cash on hand / Physical Cash'},
    ];
    for (final acc in bankAccounts) {
      accountOptions.add({'id': acc.id, 'name': '${acc.bankName} ${acc.accountType} (${acc.accountNumber ?? ""})'});
    }
    for (final card in creditCards) {
      accountOptions.add({'id': card.id, 'name': '${card.bankName} ${card.cardName} (${card.lastFour ?? ""})'});
    }

    final formKey = GlobalKey<FormState>();
    final merchantController = TextEditingController();
    final amountController = TextEditingController();
    String selectedAccountId = 'manual_cash';
    TransactionCategory selectedCategory = TransactionCategory.expenseOther;
    DateTime selectedDate = DateTime.now();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isIncomeTx = (double.tryParse(amountController.text) ?? -1.0) > 0;
            final allowedCategories = isIncomeTx
                ? TransactionCategory.incomeCategories
                : TransactionCategory.expenseCategories;

            if (!allowedCategories.contains(selectedCategory)) {
              selectedCategory = isIncomeTx ? TransactionCategory.incomeOther : TransactionCategory.expenseOther;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Add Manual Transaction',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 1. Account / Target Selector
                      DropdownButtonFormField<String>(
                        value: selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Account / Card',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: accountOptions
                            .map((acc) => DropdownMenuItem(
                                  value: acc['id'],
                                  child: Text(acc['name']!, style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedAccountId = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // 2. Date Selector with Native Calendar View
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Merchant / Description
                      TextFormField(
                        controller: merchantController,
                        decoration: const InputDecoration(
                          labelText: 'Merchant / Description',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // 4. Amount Field
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (S\$) (Negative = Outflow/Expense, Positive = Income)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setModalState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Must be a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // 5. Category Dropdown
                      DropdownButtonFormField<TransactionCategory>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: allowedCategories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.displayName, style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  final amt = double.parse(amountController.text);
                                  await ref.read(cashFlowOperationsProvider).addManualTransaction(
                                        merchant: merchantController.text.trim(),
                                        amount: amt,
                                        category: selectedCategory,
                                        date: selectedDate,
                                        accountId: selectedAccountId,
                                      );
                                  ref.invalidate(cashPositionProvider);
                                  
                                  // Track manual transaction event
                                  ref.read(analyticsServiceProvider).logEvent('manual_transaction_added', parameters: {
                                    'merchant': merchantController.text.trim(),
                                    'amount': amt,
                                    'category': selectedCategory.value,
                                    'accountId': selectedAccountId,
                                  });

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              child: const Text('Add Entry'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTransactionBottomSheet(BuildContext context, WidgetRef ref, Transaction tx) async {
    final db = ref.read(appDatabaseProvider);
    final storage = ref.read(secureStorageProvider);
    final prefs = await SharedPreferences.getInstance();
    final testerEmail = prefs.getString('tester_email') ?? '';
    var cfUserId = await storage.getUserId();
    if (cfUserId == null || cfUserId.isEmpty || cfUserId == 'unknown_user') {
      cfUserId = testerEmail.contains('@') ? 'tester_${testerEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}' : 'chenyee_user';
    }
    final bankAccounts = await db.getBankAccountsByUser(cfUserId);
    final creditCards = await db.getCreditCardsByUser(cfUserId);

    final accountOptions = <Map<String, String>>[
      {'id': 'manual_cash', 'name': 'Cash on hand / Physical Cash'},
    ];
    for (final acc in bankAccounts) {
      accountOptions.add({'id': acc.id, 'name': '${acc.bankName} ${acc.accountType} (${acc.accountNumber ?? ""})'});
    }
    for (final card in creditCards) {
      accountOptions.add({'id': card.id, 'name': '${card.bankName} ${card.cardName} (${card.lastFour ?? ""})'});
    }

    final formKey = GlobalKey<FormState>();
    final merchantController = TextEditingController(text: tx.merchant);
    final amountController = TextEditingController(text: tx.amount.toStringAsFixed(2));
    String selectedAccountId = tx.accountId;
    if (!accountOptions.any((a) => a['id'] == selectedAccountId)) {
      selectedAccountId = 'manual_cash';
    }
    TransactionCategory selectedCategory = TransactionCategory.fromValue(tx.category);
    DateTime selectedDate = DateTime.fromMillisecondsSinceEpoch(tx.date * 1000);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isIncomeTx = (double.tryParse(amountController.text) ?? -1.0) > 0;
            final allowedCategories = isIncomeTx
                ? TransactionCategory.incomeCategories
                : TransactionCategory.expenseCategories;

            if (!allowedCategories.contains(selectedCategory)) {
              selectedCategory = isIncomeTx ? TransactionCategory.incomeOther : TransactionCategory.expenseOther;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit Transaction',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 1. Account / Target Selector
                      DropdownButtonFormField<String>(
                        value: selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Account / Card',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: accountOptions
                            .map((acc) => DropdownMenuItem(
                                  value: acc['id'],
                                  child: Text(acc['name']!, style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedAccountId = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // 2. Date Selector with Native Calendar View
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Merchant / Description
                      TextFormField(
                        controller: merchantController,
                        decoration: const InputDecoration(
                          labelText: 'Merchant / Description',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // 4. Amount Field
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (S\$) (Negative = Outflow/Expense, Positive = Income)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setModalState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Must be a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // 5. Category Dropdown
                      DropdownButtonFormField<TransactionCategory>(
                        value: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: allowedCategories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat.displayName, style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  final amt = double.parse(amountController.text);
                                  await ref.read(cashFlowOperationsProvider).updateTransaction(
                                        id: tx.id,
                                        merchant: merchantController.text.trim(),
                                        amount: amt,
                                        category: selectedCategory,
                                        date: selectedDate,
                                        accountId: selectedAccountId,
                                      );
                                  ref.invalidate(cashPositionProvider);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
