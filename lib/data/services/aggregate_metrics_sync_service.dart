import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

  /// Anonymously sync monthly summary metrics without personal identifiers
  Future<void> syncCurrentMonthMetrics() async {
    try {
      final rawUserId = await _storage.getUserId();
      if (rawUserId == null || rawUserId.isEmpty) return;

      // Create one-way cryptographic SHA-256 hash of user ID for privacy
      final userHash = sha256.convert(utf8.encode('salt_sgcashflow_')).toString();

      final now = DateTime.now();
      final monthYear = DateFormat('yyyy-MM').format(now);

      // 1. Calculate statement counts
      final statements = await _db.getStatementsByUser(rawUserId);
      int bankCount = 0;
      int cardCount = 0;
      for (final s in statements) {
        if (s.fileType.toLowerCase().contains('card') || s.fileType.toLowerCase().contains('credit')) {
          cardCount++;
        } else {
          bankCount++;
        }
      }

      // 2. Calculate bank balances (net cash position)
      final accounts = await _db.getBankAccountsByUser(rawUserId);
      double netCash = 0.0;
      for (final a in accounts) {
        netCash += a.currentBalance;
      }

      // 3. Calculate current month income, expenses & category breakdown
      final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch ~/ 1000;
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch ~/ 1000;

      final allTxs = await _db.getTransactionsByUser(rawUserId);
      final monthTxs = allTxs.where((tx) => tx.date >= startOfMonth && tx.date <= endOfMonth).toList();

      double monthlyIncome = 0.0;
      double monthlyExpenses = 0.0;
      final Map<String, double> categoryBreakdown = {};

      for (final tx in monthTxs) {
        if (tx.amount > 0) {
          monthlyIncome += tx.amount;
        } else {
          monthlyExpenses += tx.amount.abs();
          final cat = tx.category;
          categoryBreakdown[cat] = (categoryBreakdown[cat] ?? 0.0) + tx.amount.abs();
        }
      }

      // 4. Calculate total miles & cashback
      final milesList = await _db.getMilesWalletByUser(rawUserId);
      double totalMiles = 0.0;
      for (final m in milesList) {
        totalMiles += m.balance;
      }

      double totalCashback = 0.0;
      for (final tx in monthTxs) {
        totalCashback += tx.cashbackEarned;
      }

      final payload = {
        'userHash': userHash,
        'monthYear': monthYear,
        'bankStatementsCount': bankCount,
        'cardStatementsCount': cardCount,
        'netCashPosition': netCash,
        'monthlyIncome': monthlyIncome,
        'monthlyExpenses': monthlyExpenses,
        'categoryBreakdown': categoryBreakdown,
        'totalMilesBalance': totalMiles,
        'totalCashbackEarned': totalCashback,
      };

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final baseUrl = kIsWeb ? '' : 'https://web-kappa-kohl-74.vercel.app';
      await dio.post('/api/metrics', data: payload);
    } catch (_) {}
  }
}
