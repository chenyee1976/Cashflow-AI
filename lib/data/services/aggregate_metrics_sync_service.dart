import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      // Fetch all statements, bank accounts, transactions, and miles for this user
      final statements = await _db.getStatementsByUser(rawUserId);
      final allAccounts = await _db.getBankAccountsByUser(rawUserId);
      final allTxs = await _db.getTransactionsByUser(rawUserId);
      final milesList = await _db.getMilesWalletByUser(rawUserId);

      // Consolidate unique accounts by bankName + accountNumber
      String normalize(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      final Map<String, BankAccount> uniqueAccounts = {};
      for (final acc in allAccounts) {
        final key = '${normalize(acc.bankName)}_${normalize(acc.accountNumber ?? '')}';
        uniqueAccounts[key] = acc;
      }
      final consolidatedAccounts = uniqueAccounts.values.toList();

      // Collect all active months from statements and transactions (e.g. 2026-06, 2026-07, 2026-08)
      final Set<String> activeMonths = {};
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

        // 2. Net Cash Position (SGD Equivalent with proper FX conversion and deduplication)
        double monthNetCash = 0.0;
        for (final acc in consolidatedAccounts) {
          // Find matching snapshot on or closest-before target month end
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
            final rate = double.tryParse(savedRate ?? '') ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
            monthNetCash += rawBal * rate;
          }
        }

        // Add Physical Cash pool if defined
        final cashOnHandBase = await _storage.getCashOnHandBaseForMonth(year: year, month: month) ?? 0.0;
        monthNetCash += cashOnHandBase;

        // 3. Monthly Income, Expenses & Category Breakdown for this specific month
        final monthTxs = allTxs.where((tx) => tx.date >= startTimestamp && tx.date <= endTimestamp).toList();
        double monthlyIncome = 0.0;
        double monthlyExpenses = 0.0;
        final Map<String, double> categoryBreakdown = {};

        for (final tx in monthTxs) {
          if (tx.amount > 0) {
            monthlyIncome += tx.amount;
            final cat = 'income_${tx.category}';
            categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0.0) + tx.amount;
          } else {
            monthlyExpenses += tx.amount.abs();
            final cat = 'expense_${tx.category}';
            categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0.0) + tx.amount.abs();
          }
        }

        // 4. Miles & Cashback for this month
        double totalMiles = 0.0;
        for (final m in milesList) {
          totalMiles += m.balance;
        }

        double totalCashback = 0.0;
        for (final tx in monthTxs) {
          totalCashback += tx.cashbackEarned;
        }

        payloadRows.add({
          'userHash': userEmail, // Store readable User Email
          'monthYear': mStr,
          'bankStatementsCount': monthBankCount,
          'cardStatementsCount': monthCardCount,
          'netCashPosition': double.parse(monthNetCash.toStringAsFixed(2)),
          'monthlyIncome': double.parse(monthlyIncome.toStringAsFixed(2)),
          'monthlyExpenses': double.parse(monthlyExpenses.toStringAsFixed(2)),
          'categoryBreakdown': categoryBreakdown,
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
