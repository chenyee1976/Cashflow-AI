import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/category_enum.dart';
import '../database/app_database.dart';
import '../secure_storage/secure_storage_service.dart';

final aggregateMetricsSyncServiceProvider = Provider<AggregateMetricsSyncService>((ref) {
  return AggregateMetricsSyncService(
    db: ref.watch(appDatabaseProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

class AggregateMetricsSyncService {
  final AppDatabase _db;
  final SecureStorageService _storage;

  AggregateMetricsSyncService({
    required AppDatabase db,
    required SecureStorageService storage,
  })  : _db = db,
        _storage = storage;

  /// Sync monthly summary metrics for current and historical months (June, July, August, etc.)
  Future<void> syncCurrentMonthMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final testerEmail = prefs.getString('tester_email') ?? '';
      
      var rawUserId = await _storage.getUserId();
      if (rawUserId == null || rawUserId.isEmpty || rawUserId == 'unknown_user') {
        rawUserId = testerEmail.contains('@') 
            ? 'tester_${testerEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}' 
            : 'chenyee_user';
      }

      var userEmail = await _storage.getGoogleEmail() ?? testerEmail;
      if (userEmail.isEmpty) {
        userEmail = rawUserId;
      }

      // Collect all possible user ID aliases to ensure 100% of real user data is retrieved
      final candidateUserIds = <String>{};
      if (rawUserId.isNotEmpty) candidateUserIds.add(rawUserId);
      if (testerEmail.isNotEmpty) {
        candidateUserIds.add(testerEmail);
        candidateUserIds.add('tester_${testerEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}');
      }
      final googleEmail = await _storage.getGoogleEmail();
      if (googleEmail != null && googleEmail.isNotEmpty) {
        candidateUserIds.add(googleEmail);
        candidateUserIds.add('tester_${googleEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}');
      }
      candidateUserIds.add('chenyee_user');

      final List<Statement> statements = [];
      final List<BankAccount> allAccounts = [];
      final List<Transaction> allTxs = [];
      final List<MilesWallet> milesList = [];

      for (final uid in candidateUserIds) {
        final stmts = await _db.getStatementsByUser(uid);
        for (final s in stmts) {
          if (!statements.any((existing) => existing.id == s.id)) statements.add(s);
        }
        final accs = await _db.getBankAccountsByUser(uid);
        for (final a in accs) {
          if (!allAccounts.any((existing) => existing.id == a.id)) allAccounts.add(a);
        }
        final txs = await _db.getTransactionsByUser(uid);
        for (final t in txs) {
          if (!allTxs.any((existing) => existing.id == t.id)) allTxs.add(t);
        }
        final mls = await _db.getMilesWalletByUser(uid);
        for (final m in mls) {
          if (!milesList.any((existing) => existing.id == m.id)) milesList.add(m);
        }
      }

      // Consolidate unique accounts by bankName + accountNumber
      String normalize(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final Map<String, BankAccount> uniqueAccounts = {};
      for (final acc in allAccounts) {
        final key = '${normalize(acc.bankName)}_${normalize(acc.accountNumber ?? '')}';
        uniqueAccounts[key] = acc;
      }
      final consolidatedAccounts = uniqueAccounts.values.toList();

      // Collect all active months from statements, transactions, and standard window (June, July, August, September 2026)
      final Set<String> activeMonths = {
        '2026-06',
        '2026-07',
        '2026-08',
        '2026-09',
      };
      final now = DateTime.now();
      activeMonths.add(DateFormat('yyyy-MM').format(now));
      activeMonths.add(DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1))); // Last month
      activeMonths.add(DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 2))); // 2 months ago

      for (final s in statements) {
        if (s.periodEnd != null && s.periodEnd! > 0) {
          activeMonths.add(DateFormat('yyyy-MM').format(DateTime.fromMillisecondsSinceEpoch(s.periodEnd! * 1000)));
        } else if (s.periodStart != null && s.periodStart! > 0) {
          activeMonths.add(DateFormat('yyyy-MM').format(DateTime.fromMillisecondsSinceEpoch(s.periodStart! * 1000)));
        }
      }

      for (final tx in allTxs) {
        if (tx.date > 0) {
          activeMonths.add(DateFormat('yyyy-MM').format(DateTime.fromMillisecondsSinceEpoch(tx.date * 1000)));
        }
      }

      final sortedMonths = activeMonths.toList()..sort();
      final List<Map<String, dynamic>> payloadRows = [];

      for (final mStr in sortedMonths) {
        final parts = mStr.split('-');
        if (parts.length != 2) continue;
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year == null || month == null) continue;

        final targetMonthStart = DateTime(year, month, 1);
        final targetMonthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
        final startTimestamp = targetMonthStart.millisecondsSinceEpoch ~/ 1000;
        final endTimestamp = targetMonthEnd.millisecondsSinceEpoch ~/ 1000;

        // 1. Statements Count for this month & to-date
        int monthBankCount = 0;
        int monthCardCount = 0;
        for (final s in statements) {
          final isCard = s.fileType.toLowerCase().contains('card') || s.fileType.toLowerCase().contains('credit');
          if (isCard) {
            monthCardCount++;
          } else {
            monthBankCount++;
          }
        }

        // 2. Net Cash Position (Exact match with Cash Position card on Dashboard)
        double monthNetCash = 0.0;
        for (final acc in consolidatedAccounts) {
          final sameSnapshots = allAccounts.where((a) =>
            normalize(a.bankName) == normalize(acc.bankName) &&
            normalize(a.accountNumber ?? '') == normalize(acc.accountNumber ?? '')
          ).toList();

          BankAccount? bestMatch;
          DateTime? bestMatchDate;

          for (final snap in sameSnapshots) {
            final matchedStmt = statements.where((s) => s.id == snap.sourceStatementId).firstOrNull;
            DateTime? stmtDate;
            if (matchedStmt != null && matchedStmt.periodEnd != null) {
              stmtDate = DateTime.fromMillisecondsSinceEpoch(matchedStmt.periodEnd! * 1000);
            } else if (snap.createdAt > 0) {
              stmtDate = DateTime.fromMillisecondsSinceEpoch(snap.createdAt * 1000);
            }

            if (stmtDate == null) continue;
            final snapMonthStart = DateTime(stmtDate.year, stmtDate.month, 1);
            if (!snapMonthStart.isAfter(targetMonthStart)) {
              if (bestMatchDate == null || snapMonthStart.isAfter(bestMatchDate)) {
                bestMatchDate = snapMonthStart;
                bestMatch = snap;
              }
            }
          }

          final rawBal = bestMatch?.currentBalance ?? 0.0;
          final currencyStr = acc.currency.trim().toUpperCase();
          if (currencyStr == 'SGD') {
            monthNetCash += rawBal;
          } else {
            final savedRate = await _storage.getFxRate(currencyStr);
            final defaultFx = currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : (currencyStr == 'MYR' ? 0.30 : (currencyStr == 'IDR' ? 0.000083 : 1.0)));
            final rate = double.tryParse(savedRate ?? '') ?? defaultFx;
            monthNetCash += rawBal * rate;
          }
        }

        // Net cash adjustments from cash-on-hand transactions up to target month end
        double cashAdjustmentsTotal = 0.0;
        bool hasCashTxs = false;
        for (final tx in allTxs) {
          if (tx.date <= endTimestamp) {
            if (tx.accountId == 'manual_cash' || tx.accountId == 'manual') {
              cashAdjustmentsTotal += tx.amount;
              hasCashTxs = true;
            } else if (tx.category == TransactionCategory.expenseTransferToCash.value) {
              cashAdjustmentsTotal += tx.amount.abs();
              hasCashTxs = true;
            }
          }
        }

        final cashOnHandBase = await _storage.getCashOnHandBaseForMonth(year: year, month: month) ?? 0.0;
        if (cashOnHandBase > 0.0 || hasCashTxs) {
          monthNetCash += (cashOnHandBase + cashAdjustmentsTotal);
        }

        // 3. Monthly Income, Expenses, Transfers & Structured Category Breakdown
        final monthTxs = allTxs.where((tx) => tx.date >= startTimestamp && tx.date <= endTimestamp).toList();
        double monthlyIncome = 0.0;
        double monthlyExpenses = 0.0;
        double monthlyTransfers = 0.0;
        final Map<String, double> incomeCategoryMap = {};
        final Map<String, double> expenseCategoryMap = {};
        int manualInputCount = 0;

        for (final tx in monthTxs) {
          if (tx.accountId == 'manual' || tx.accountId == 'manual_cash') {
            manualInputCount++;
          }

          // Track internal bank transfers separately
          final isTransfer = TransactionCategory.fromValue(tx.category).isTransfer;
          if (isTransfer) {
            monthlyTransfers += tx.amount.abs();
            continue;
          }

          if (tx.amount > 0) {
            monthlyIncome += tx.amount;
            final cat = tx.category.replaceAll('income_', '').replaceAll('_', ' ');
            final displayCat = cat.isNotEmpty ? '${cat[0].toUpperCase()}${cat.substring(1)}' : 'Other';
            incomeCategoryMap[displayCat] = (incomeCategoryMap[displayCat] ?? 0.0) + tx.amount;
          } else {
            monthlyExpenses += tx.amount.abs();
            final cat = tx.category.replaceAll('expense_', '').replaceAll('_', ' ');
            final displayCat = cat.isNotEmpty ? '${cat[0].toUpperCase()}${cat.substring(1)}' : 'Other';
            expenseCategoryMap[displayCat] = (expenseCategoryMap[displayCat] ?? 0.0) + tx.amount.abs();
          }
        }

        final Map<String, dynamic> structuredBreakdown = {
          'income': incomeCategoryMap,
          'expenses': expenseCategoryMap,
          'telemetry': {
            'manual_inputs': manualInputCount,
          },
        };

        // 4. Miles & Cashback for this month
        double totalMiles = 0.0;
        for (final m in milesList) {
          totalMiles += m.balance;
        }

        double totalCashback = 0.0;
        for (final tx in monthTxs) {
          totalCashback += tx.cashbackEarned;
        }

        final urlString = kIsWeb ? Uri.base.toString().toLowerCase() : '';
        final appEnvironment = kIsWeb
            ? (urlString.contains('web-kappa')
                ? 'Preview (web-kappa)'
                : (urlString.contains('sgcashflowai') ? 'Live / Production (sgcashflowai)' : 'Preview (web-kappa)'))
            : 'Mobile / Native';

        payloadRows.add({
          'userHash': userEmail, // Store readable User Email
          'monthYear': mStr,
          'environment': appEnvironment,
          'bankStatementsCount': monthBankCount,
          'cardStatementsCount': monthCardCount,
          'netCashPosition': double.parse(monthNetCash.toStringAsFixed(2)),
          'monthlyIncome': double.parse(monthlyIncome.toStringAsFixed(2)),
          'monthlyExpenses': double.parse(monthlyExpenses.toStringAsFixed(2)),
          'monthlyTransfers': double.parse(monthlyTransfers.toStringAsFixed(2)),
          'categoryBreakdown': structuredBreakdown,
          'totalMilesBalance': totalMiles,
          'totalCashbackEarned': double.parse(totalCashback.toStringAsFixed(2)),
        });
      }

      if (payloadRows.isEmpty) return;

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      await dio.post('$baseUrl/api/metrics', data: payloadRows);
      debugPrint('✅ [AggregateMetrics] synced ${payloadRows.length} months successfully for $userEmail');
    } catch (e) {
      debugPrint('⚠️ [AggregateMetrics] sync failed: $e');
    }
  }
}
