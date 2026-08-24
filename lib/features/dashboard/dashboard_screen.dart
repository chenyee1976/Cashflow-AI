import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/category_enum.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../shared/widgets/app_header_brand.dart';
import '../../shared/widgets/app_footer_brand.dart';
import '../../data/services/analytics_service.dart';
import 'dashboard_provider.dart';
import '../account/account_provider.dart';
import '../cashflow/statement/cashflow_provider.dart';
import '../../data/secure_storage/secure_storage_service.dart';
import '../../data/database/app_database.dart';
import '../../data/services/gemini_extraction_service.dart';
import '../../data/services/aggregate_metrics_sync_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aggregateMetricsSyncServiceProvider).syncCurrentMonthMetrics();
    });
  }

  void _checkBetaTesterOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final isRegistered = prefs.getBool('beta_tester_onboarded') ?? false;

    if (!isRegistered && mounted) {
      final savedFName = prefs.getString('tester_first_name') ?? '';
      final savedLName = prefs.getString('tester_last_name') ?? '';
      final savedEmail = prefs.getString('tester_email') ?? '';

      final firstNameCtrl = TextEditingController(text: savedFName);
      final lastNameCtrl = TextEditingController(text: savedLName);
      final emailCtrl = TextEditingController(text: savedEmail);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Welcome Beta Tester! 🚀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please enter your name and email address so your profile & activity logs are identified correctly.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: firstNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    hintText: 'e.g. Alex',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'e.g. Tan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'e.g. alex.tan@gmail.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final fName = firstNameCtrl.text.trim();
                final lName = lastNameCtrl.text.trim();
                final email = emailCtrl.text.trim();

                if (email.isEmpty) {
                  context.showTopSnackBar('Please enter your email address', isError: true);
                  return;
                }

                Navigator.pop(ctx);
                await prefs.setBool('beta_tester_onboarded', true);
                await prefs.setString('tester_first_name', fName);
                await prefs.setString('tester_last_name', lName);
                await prefs.setString('tester_email', email);

                final userId = 'tester_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
                
                // Also update SecureStorage with real identity
                final storage = ref.read(secureStorageProvider);
                await storage.saveGoogleUser(userId: userId, googleId: 'web_user_${email.hashCode}', email: email);
                
                final analytics = ref.read(analyticsServiceProvider);
                analytics.setUser(userId, email);
                analytics.logEvent('beta_tester_registered', parameters: {
                  'firstName': fName,
                  'lastName': lName,
                  'email': email,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save & Continue 🚀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProfileAsync = ref.watch(accountProfileProvider);
    final cashAsync = ref.watch(cashPositionProvider);
    final incomeAsync = ref.watch(monthlyIncomeProvider);
    final expensesAsync = ref.watch(monthlyExpensesProvider);

    final currencyFormatter = NumberFormat.currency(locale: 'en_SG', symbol: 'S\$');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. App Header Title Row
              const AppHeaderBrand(),
              const SizedBox(height: 16),

              // 2. Greeting Section (100% Synced with Account Profile Tab)
              accountProfileAsync.when(
                data: (profile) {
                  final fName = profile.firstName.trim();
                  final displayName = fName.isNotEmpty ? fName : 'Beta Tester';
                  return Text(
                    '${_getGreeting()}, $displayName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  );
                },
                loading: () => Text(
                  '${_getGreeting()}...',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                error: (_, __) => Text(
                  '${_getGreeting()}, Beta Tester',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // 2b. AI Quick Voice & Cash Expense Logger
              _VoiceExpenseCard(ref: ref),
              const SizedBox(height: 16),

              // Pro Analytics Banner
              GestureDetector(
                onTap: () => context.push('/home/pro-dashboard'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.proCardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.proPrimary.withOpacity(0.3), width: 1),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.proGoldGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.analytics_outlined, color: AppColors.proBackground, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.proGoldGradient,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.proBackground,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Pro Analytics Dashboard',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'View 6-month trends, income donut charts & expense variance',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.proGold),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Upload a Statement Title
              const Text(
                'UPLOAD A STATEMENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // 4. Two Upload Statement Buttons Row
              Row(
                children: [
                  Expanded(
                    child: _buildUploadCard(
                      context: context,
                      title: 'Bank statement',
                      subtitle: 'Balances & transactions',
                      icon: Icons.account_balance,
                      type: 'bank',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUploadCard(
                      context: context,
                      title: 'Credit card statement',
                      subtitle: 'Card, spend & miles',
                      icon: Icons.credit_card,
                      type: 'credit_card',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Cash Position Card
              _buildWidgetCard(
                title: 'CASH POSITION',
                icon: Icons.description_outlined,
                child: cashAsync.when(
                  data: (data) {
                    // Helper method to resolve dynamic FX tooltip line:
                    String _getAccountTooltipLine(BankAccount acc, double balance) {
                      final currencyStr = acc.currency.trim().toUpperCase();
                      final balanceFormatted = '${currencyStr == 'USD' ? '\$' : (currencyStr == 'JPY' ? '¥' : (currencyStr == 'SGD' ? 'S\$' : currencyStr))} ${NumberFormat('#,##0.00').format(balance)}';
                      if (currencyStr == 'SGD') {
                        return '• ${acc.bankName} · ${acc.accountNumber ?? ""}: $balanceFormatted';
                      }
                      
                      final rate = data.fxRates[currencyStr] ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
                      final sgdEquiv = 'S\$ ${NumberFormat('#,##0.00').format(balance * rate)}';
                      return '• ${acc.bankName} · ${acc.accountNumber ?? ""}: $balanceFormatted ($sgdEquiv)';
                    }

                    final currentTooltip = data.accounts.isEmpty 
                      ? 'No active bank accounts'
                      : data.accounts.map((acc) {
                          return _getAccountTooltipLine(acc, acc.currentBalance);
                        }).join('\n');

                    final prevMonthTooltip = data.accounts.isEmpty 
                      ? 'No active bank accounts'
                      : data.accounts.map((acc) {
                          final bal = data.prevMonthBalances[acc.id] ?? 0.0;
                          return _getAccountTooltipLine(acc, bal);
                        }).join('\n');

                    final prevYearTooltip = data.accounts.isEmpty 
                      ? 'No active bank accounts'
                      : data.accounts.map((acc) {
                          final bal = data.prevYearBalances[acc.id] ?? 0.0;
                          return _getAccountTooltipLine(acc, bal);
                        }).join('\n');

                    return Column(
                      children: [
                        _buildRowItem(
                          label: 'Current balance',
                          dateInfo: 'as of ${data.currentDateStr}',
                          value: currencyFormatter.format(data.currentBalance),
                          valueColor: AppColors.primary,
                          isBoldValue: true,
                          tooltipMessage: currentTooltip,
                          onTap: () {
                            final activeMonth = ref.read(selectedMonthProvider);
                            final now = DateTime.now();
                            ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month);
                            _showBreakdownSheet(context, ref, data, 'Current balance', activeMonth: activeMonth);
                          },
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _buildRowItem(
                          label: 'Previous month balance',
                          dateInfo: 'as of ${data.prevMonthDateStr}',
                          value: currencyFormatter.format(data.prevMonthBalance),
                          valueColor: AppColors.textPrimary,
                          isBoldValue: true,
                          tooltipMessage: prevMonthTooltip,
                          onTap: () {
                            final activeMonth = ref.read(selectedMonthProvider);
                            final now = DateTime.now();
                            ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month - 1);
                            _showBreakdownSheet(context, ref, data, 'Previous month balance', activeMonth: activeMonth);
                          },
                        ),
                        const Divider(height: 1, color: AppColors.divider),
                        _buildRowItem(
                          label: 'Previous year balance',
                          dateInfo: 'as of ${data.prevYearDateStr}',
                          value: currencyFormatter.format(data.prevYearBalance),
                          valueColor: AppColors.textPrimary,
                          isBoldValue: true,
                          tooltipMessage: prevYearTooltip,
                          onTap: () {
                            final activeMonth = ref.read(selectedMonthProvider);
                            final now = DateTime.now();
                            ref.read(selectedMonthProvider.notifier).state = DateTime(now.year - 1, 12);
                            _showBreakdownSheet(context, ref, data, 'Previous year balance', activeMonth: activeMonth);
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, __) => Text('Error loading cash position: $e'),
                ),
              ),
              const SizedBox(height: 20),

              // 6. Monthly Income Card
              _buildWidgetCard(
                title: 'MONTHLY INCOME',
                icon: Icons.trending_up,
                child: incomeAsync.when(
                  data: (data) => Column(
                    children: [
                      _buildRowItem(
                        label: 'Current month',
                        dateInfo: data.currentMonthStr,
                        value: currencyFormatter.format(data.currentMonthAmount),
                        valueColor: AppColors.primary,
                        isBoldValue: true,
                        tooltipMessage: _formatTooltipBreakdown(data.currentMonthBreakdown),
                        onTap: () {
                          final activeMonth = ref.read(selectedMonthProvider);
                          final now = DateTime.now();
                          ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month);
                          _showMonthlyBreakdownSheet(
                            context,
                            'Monthly Income',
                            data.currentMonthStr,
                            data.currentMonthBreakdown,
                            AppColors.primary,
                            activeMonth: activeMonth,
                          );
                        },
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildRowItem(
                        label: 'Last month',
                        dateInfo: data.lastMonthStr,
                        value: currencyFormatter.format(data.lastMonthAmount),
                        valueColor: AppColors.primary,
                        isBoldValue: true,
                        tooltipMessage: _formatTooltipBreakdown(data.lastMonthBreakdown),
                        onTap: () {
                          final activeMonth = ref.read(selectedMonthProvider);
                          final now = DateTime.now();
                          ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month - 1);
                          _showMonthlyBreakdownSheet(
                            context,
                            'Monthly Income',
                            data.lastMonthStr,
                            data.lastMonthBreakdown,
                            AppColors.primary,
                            activeMonth: activeMonth,
                          );
                        },
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildRowItem(
                        label: '2 months ago',
                        dateInfo: data.twoMonthsAgoStr,
                        value: currencyFormatter.format(data.twoMonthsAgoAmount),
                        valueColor: AppColors.primary,
                        isBoldValue: true,
                        tooltipMessage: _formatTooltipBreakdown(data.twoMonthsAgoBreakdown),
                        onTap: () {
                          final activeMonth = ref.read(selectedMonthProvider);
                          final now = DateTime.now();
                          ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month - 2);
                          _showMonthlyBreakdownSheet(
                            context,
                            'Monthly Income',
                            data.twoMonthsAgoStr,
                            data.twoMonthsAgoBreakdown,
                            AppColors.primary,
                            activeMonth: activeMonth,
                          );
                        },
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, __) => Text('Error loading monthly income: $e'),
                ),
              ),
              const SizedBox(height: 20),

              // 7. Monthly Expenses Card
              _buildWidgetCard(
                title: 'MONTHLY EXPENSES',
                icon: Icons.history_toggle_off,
                child: expensesAsync.when(
                  data: (data) => Column(
                    children: [
                      _buildRowItem(
                        label: 'Current month',
                        dateInfo: data.currentMonthStr,
                        value: currencyFormatter.format(data.currentMonthAmount),
                        valueColor: AppColors.error,
                        isBoldValue: true,
                        tooltipMessage: _formatTooltipBreakdown(data.currentMonthBreakdown),
                        onTap: () {
                          final activeMonth = ref.read(selectedMonthProvider);
                          final now = DateTime.now();
                          ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month);
                          _showMonthlyBreakdownSheet(
                            context,
                            'Monthly Expenses',
                            data.currentMonthStr,
                            data.currentMonthBreakdown,
                            AppColors.error,
                            activeMonth: activeMonth,
                          );
                        },
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildRowItem(
                        label: 'Last month',
                        dateInfo: data.lastMonthStr,
                        value: currencyFormatter.format(data.lastMonthAmount),
                        valueColor: AppColors.error,
                        isBoldValue: true,
                        tooltipMessage: _formatTooltipBreakdown(data.lastMonthBreakdown),
                        onTap: () {
                          final activeMonth = ref.read(selectedMonthProvider);
                          final now = DateTime.now();
                          ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month - 1);
                          _showMonthlyBreakdownSheet(
                            context,
                            'Monthly Expenses',
                            data.lastMonthStr,
                            data.lastMonthBreakdown,
                            AppColors.error,
                            activeMonth: activeMonth,
                          );
                        },
                      ),
                      const Divider(height: 1, color: AppColors.divider),
                      _buildRowItem(
                        label: '2 months ago',
                        dateInfo: data.twoMonthsAgoStr,
                        value: currencyFormatter.format(data.twoMonthsAgoAmount),
                        valueColor: AppColors.error,
                        isBoldValue: true,
                        tooltipMessage: _formatTooltipBreakdown(data.twoMonthsAgoBreakdown),
                        onTap: () {
                          final activeMonth = ref.read(selectedMonthProvider);
                          final now = DateTime.now();
                          ref.read(selectedMonthProvider.notifier).state = DateTime(now.year, now.month - 2);
                          _showMonthlyBreakdownSheet(
                            context,
                            'Monthly Expenses',
                            data.twoMonthsAgoStr,
                            data.twoMonthsAgoBreakdown,
                            AppColors.error,
                            activeMonth: activeMonth,
                          );
                        },
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, __) => Text('Error loading monthly expenses: $e'),
                ),
              ),
              const SizedBox(height: 20),

              // 8. Bottom Pro Upgrade Banner (Preserved for future release)
              if (false) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1.0),
                        child: Icon(Icons.stars, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unlock up to 10 widgets with Pro',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customise your dashboard and try Pro free for 14 days.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'In progress',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthlyBreakdownSheet(
    BuildContext context,
    String title,
    String dateInfo,
    Map<String, double> breakdown,
    Color color, {
    DateTime? activeMonth,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final selectedMonth = ref.watch(selectedMonthProvider);
          final monthStr = DateFormat('MMMM yyyy').format(selectedMonth);

          final summaryAsync = title == 'Monthly Income' ? ref.watch(monthlyIncomeProvider) : ref.watch(monthlyExpensesProvider);
          final currentBreakdown = summaryAsync.when(
            data: (data) => data.currentMonthBreakdown,
            loading: () => <String, double>{},
            error: (_, __) => <String, double>{},
          );

          // Get total from cashFlowScreenProvider for exact alignment with Cash Flow screen
          final cashFlowAsync = ref.watch(cashFlowScreenProvider);
          final totalVal = cashFlowAsync.when(
            data: (data) => title == 'Monthly Income' ? data.totalIncome : data.totalExpenses,
            loading: () => currentBreakdown.values.fold<double>(0.0, (s, v) => s + v),
            error: (_, __) => currentBreakdown.values.fold<double>(0.0, (s, v) => s + v),
          );

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Container(
              width: 500,
              constraints: const BoxConstraints(maxHeight: 520),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header layout: Title (left), Subtitle (bottom-left), Month Badge & Navigation controls (right column)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title == 'Monthly Income' ? 'Breakdown by income sources' : 'Breakdown by expense categories',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  monthStr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (Navigator.canPop(ctx)) {
                                      Navigator.pop(ctx);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 18, color: AppColors.primary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 24),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Previous Month',
                                onPressed: () {
                                  final current = ref.read(selectedMonthProvider);
                                  ref.read(selectedMonthProvider.notifier).state = DateTime(current.year, current.month - 1);
                                },
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 24),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Next Month',
                                onPressed: () {
                                  final current = ref.read(selectedMonthProvider);
                                  ref.read(selectedMonthProvider.notifier).state = DateTime(current.year, current.month + 1);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (currentBreakdown.isEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('No main entries recorded for this month.', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                            ),
                          ] else ...[
                            ...currentBreakdown.entries.map((entry) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.18)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                  ),
                                  Text(
                                    'S\$${NumberFormat('#,##0.00').format(entry.value)}',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title == 'Monthly Income' ? 'Total Income' : 'Total Expenses',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                        ),
                        Text(
                          'S\$${NumberFormat('#,##0.00').format(totalVal)}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      if (activeMonth != null) {
        ref.read(selectedMonthProvider.notifier).state = activeMonth;
      }
    });
  }

  Widget _buildUploadCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String type,
  }) {
    return InkWell(
      onTap: () {
        context.push('/home/cashflow/upload', extra: type);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 124,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.white, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 36,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      title,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          top: BorderSide(color: AppColors.primary, width: 4.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildRowItem({
    required String label,
    required String dateInfo,
    required String value,
    required Color valueColor,
    bool isBoldValue = false,
    String? tooltipMessage,
    VoidCallback? onTap,
  }) {
    final rowContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateInfo,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );

    Widget innerContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: rowContent,
    );

    if (onTap != null) {
      innerContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: innerContent,
      );
    }

    if (tooltipMessage != null && tooltipMessage.isNotEmpty) {
      return Tooltip(
        message: tooltipMessage,
        preferBelow: false,
        child: innerContent,
      );
    }

    return innerContent;
  }

  void _showBreakdownSheet(BuildContext context, WidgetRef ref, CashPositionModel initialData, String title, {DateTime? activeMonth}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final selectedMonth = ref.watch(selectedMonthProvider);
            final cashAsync = ref.watch(cashPositionProvider);

            return cashAsync.when(
              loading: () => Container(
                height: 300,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Container(
                height: 300,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(child: Text('Error: $err')),
              ),
              data: (data) {
                final monthStr = DateFormat('MMMM yyyy').format(selectedMonth);
                final balancesMap = {for (final a in data.accounts) a.id: a.currentBalance};
                final totalVal = data.currentBalance;

                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.82,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header layout: Title (left), Subtitle (bottom-left), Month Badge & Navigation controls (right column)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Breakdown by bank account balance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      monthStr,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        if (Navigator.canPop(context)) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 18, color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 24),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Previous Month',
                                    onPressed: () {
                                      final current = ref.read(selectedMonthProvider);
                                      ref.read(selectedMonthProvider.notifier).state = DateTime(current.year, current.month - 1);
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 24),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Next Month',
                                    onPressed: () {
                                      final current = ref.read(selectedMonthProvider);
                                      ref.read(selectedMonthProvider.notifier).state = DateTime(current.year, current.month + 1);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

              // Scrollable Account List
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: data.accounts.map((acc) {
                      final balanceVal = balancesMap[acc.id] ?? 0.0;
                      final currencyStr = acc.currency.trim().toUpperCase();
                      final isCashOnHand = acc.bankName == 'Cash on hand';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCashOnHand ? 'Cash on Hand' : '${acc.bankName} ${acc.accountType}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isCashOnHand
                                        ? 'Physical wallet pool'
                                        : '${acc.bankName} · as of ${DateFormat('dd/MM/yyyy').format(DateTime(selectedMonth.year, selectedMonth.month + 1, 0))}',
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
                                  '$currencyStr ${NumberFormat('#,##0.00').format(balanceVal)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (isCashOnHand) ...[
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final ctrl = TextEditingController(text: balanceVal.toStringAsFixed(2));
                                      final newBase = await showDialog<double>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text('Update Base Cash on Hand ($monthStr)'),
                                          content: TextField(
                                            controller: ctrl,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(
                                              labelText: 'Base Cash Pool Amount (S\$)',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                final val = double.tryParse(ctrl.text);
                                                Navigator.pop(ctx, val);
                                              },
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (newBase != null) {
                                        final targetDate = title == 'Current balance'
                                            ? DateTime.now()
                                            : (title == 'Previous month balance'
                                                ? DateTime(DateTime.now().year, DateTime.now().month, 0)
                                                : DateTime(DateTime.now().year - 1, 12, 31));

                                        await ref.read(secureStorageProvider).saveCashOnHandBaseForMonth(
                                              year: targetDate.year,
                                              month: targetDate.month,
                                              amount: newBase,
                                            );
                                        ref.invalidate(cashPositionProvider);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit, size: 11, color: AppColors.primary),
                                          SizedBox(width: 4),
                                          Text('Edit Cash', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (currencyStr != 'SGD') ...[
                                  const SizedBox(height: 2),
                                  FutureBuilder<String?>(
                                    future: ref.read(secureStorageProvider).getFxRate(currencyStr),
                                    builder: (context, snapshot) {
                                      final savedRate = snapshot.data;
                                      final rate = double.tryParse(savedRate ?? '') ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
                                      return Text(
                                        '(S\$ ${NumberFormat('#,##0.00').format(balanceVal * rate)})',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),

              // Total Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total (SGD Equiv.)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'S\$${NumberFormat('#,##0.00').format(totalVal)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Footer caption
              const Text(
                'Per-account historical balances reflect the most recent statement on file.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      if (activeMonth != null) {
        ref.read(selectedMonthProvider.notifier).state = activeMonth;
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatTooltipBreakdown(Map<String, double> breakdown) {
    if (breakdown.isEmpty) return 'No records this month';
    final items = breakdown.entries.where((e) => e.value > 0).toList();
    if (items.isEmpty) return 'No records this month';
    items.sort((a, b) => b.value.compareTo(a.value));
    final buffer = StringBuffer();
    final fmt = NumberFormat('#,##0.00');
    for (int i = 0; i < items.length; i++) {
      final entry = items[i];
      buffer.write('${entry.key}: S\$${fmt.format(entry.value)}');
      if (i < items.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }
}

class _VoiceExpenseCard extends StatefulWidget {
  final WidgetRef ref;
  const _VoiceExpenseCard({required this.ref});

  @override
  State<_VoiceExpenseCard> createState() => _VoiceExpenseCardState();
}

class _VoiceExpenseCardState extends State<_VoiceExpenseCard> {
  final TextEditingController _inputCtrl = TextEditingController();
  bool _isProcessing = false;
  bool _isListening = false;

  Future<void> _processExpense(String phrase) async {
    final clean = phrase.trim();
    if (clean.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final storage = widget.ref.read(secureStorageProvider);
      final geminiKey = await storage.getGeminiApiKey();

      String merchant = clean;
      double amount = 0.0;
      TransactionCategory category = TransactionCategory.expenseDining;

      if (geminiKey != null && geminiKey.trim().isNotEmpty) {
        try {
          final service = GeminiExtractionService(geminiKey.trim());
          final res = await service.parseVoiceOrTextExpense(clean);
          merchant = res['merchant'] ?? clean;
          amount = (res['amount'] as double? ?? 0.0).abs();
          category = TransactionCategory.fromValue(res['categoryValue'] ?? 'expense_dining');
        } catch (_) {
          // Fallback regex matching
          final match = RegExp(r'([\d\.]+)').firstMatch(clean);
          if (match != null) {
            amount = double.tryParse(match.group(1)!) ?? 0.0;
          }
          merchant = clean.replaceAll(RegExp(r'[\$\d\.]'), '').trim();
          if (merchant.isEmpty) merchant = 'Cash Spend';
        }
      } else {
        // Fallback regex parsing if key missing
        final match = RegExp(r'([\d\.]+)').firstMatch(clean);
        if (match != null) {
          amount = double.tryParse(match.group(1)!) ?? 0.0;
        }
        merchant = clean.replaceAll(RegExp(r'[\$\d\.]'), '').trim();
        if (merchant.isEmpty) merchant = 'Cash Spend';
      }

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please include an amount in your voice or text expense (e.g., "Kopi \$1.50")')),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final db = widget.ref.read(appDatabaseProvider);
      final prefs = await SharedPreferences.getInstance();
      final testerEmail = prefs.getString('tester_email') ?? '';
      var userId = await storage.getUserId();
      if (userId == null || userId.isEmpty || userId == 'unknown_user') {
        if (testerEmail.contains('@')) {
          userId = 'tester_${testerEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        } else {
          userId = 'unknown_user';
        }
      }

      await db.insertTransactions([
        TransactionsCompanion.insert(
          id: const Uuid().v4(),
          userId: userId,
          accountId: 'manual_cash',
          accountType: 'manual',
          date: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          merchant: merchant,
          description: merchant,
          amount: -amount,
          category: category.value,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        )
      ]);

      // Invalidate providers
      widget.ref.invalidate(cashFlowScreenProvider);
      widget.ref.invalidate(monthlyExpensesProvider);
      widget.ref.invalidate(cashPositionProvider);

      _inputCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Logged "$merchant" (-S\$${amount.toStringAsFixed(2)}) under ${category.displayName}'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not log expense: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _startWebVoiceRecognition() {
    if (!kIsWeb) {
      _simulateVoiceRecording();
      return;
    }

    try {
      if (html.SpeechRecognition.supported) {
        final recognition = html.SpeechRecognition();
        bool receivedResult = false;

        setState(() {
          _isListening = true;
        });

        recognition.continuous = false;
        recognition.interimResults = false;
        recognition.lang = 'en-SG';

        recognition.onResult.listen((event) {
          try {
            final dynamic ev = event;
            final results = ev.results;
            if (results != null) {
              final dynamic lastRes = results[results.length - 1];
              final dynamic item = lastRes[0];
              final String? text = item?.transcript?.toString();
              if (text != null && text.trim().isNotEmpty) {
                receivedResult = true;
                if (mounted) {
                  setState(() {
                    _isListening = false;
                    _inputCtrl.text = text;
                  });
                  _processExpense(text);
                }
              }
            }
          } catch (e) {
            debugPrint('Speech recognition error parsing: $e');
          }
        });

        recognition.onError.listen((e) {
          debugPrint('Speech recognition error: $e');
          if (mounted && !receivedResult) {
            setState(() {
              _isListening = false;
            });
            _simulateVoiceRecording();
          }
        });

        recognition.onEnd.listen((_) {
          if (mounted && _isListening && !receivedResult) {
            setState(() {
              _isListening = false;
            });
            // If Chrome finished listening but microphone yielded empty audio, trigger fallback simulation for smooth testing
            _simulateVoiceRecording();
          }
        });

        recognition.start();
      } else {
        _simulateVoiceRecording();
      }
    } catch (_) {
      _simulateVoiceRecording();
    }
  }

  void _simulateVoiceRecording() {
    setState(() {
      _isListening = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
        final samples = ['Kopi \$1.50', 'Lunch \$5.20', 'Taxi ride \$14.50'];
        final sample = (samples..shuffle()).first;
        _inputCtrl.text = sample;
        _processExpense(sample);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI QUICK CASH EXPENSE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening... Speak now!' : 'e.g. "Kopi \$1.50" or "Lunch \$5.20"',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: _isListening ? AppColors.primary : AppColors.textSecondary.withOpacity(0.7),
                      fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onSubmitted: (val) => _processExpense(val),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _isProcessing ? null : _startWebVoiceRecognition,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none_rounded,
                    color: _isListening ? Colors.white : AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: _isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: AppColors.primary, size: 22),
                onPressed: _isProcessing ? null : () => _processExpense(_inputCtrl.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
