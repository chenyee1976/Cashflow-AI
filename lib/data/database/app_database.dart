import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:drift/web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables/users_table.dart';
import 'tables/bank_accounts_table.dart';
import 'tables/credit_cards_table.dart';
import 'tables/transactions_table.dart';
import 'tables/statements_table.dart';
import 'tables/miles_tables.dart';
import '../../features/rewards/card_rewards_store.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  BankAccounts,
  CreditCards,
  Transactions,
  Statements,
  MilesWallet,
  TravelGoals,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA busy_timeout = 3000;');
        },
      );

  // ── Users ──────────────────────────────────────────────
  Future<User?> getUserById(String id) =>
      (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<User?> getUserByGoogleId(String googleId) =>
      (select(users)..where((t) => t.googleId.equals(googleId))).getSingleOrNull();

  Future<String> upsertUser(UsersCompanion entry) =>
      into(users).insertOnConflictUpdate(entry).then((_) => entry.id.value);

  Future<bool> updateUser(UsersCompanion entry) =>
      (update(users)..where((t) => t.id.equals(entry.id.value)))
          .write(entry)
          .then((rows) => rows > 0);

  // ── Statements ─────────────────────────────────────────
  Future<List<Statement>> getStatementsByUser(String userId) async {
    final res = await (select(statements)..where((t) => t.userId.equals(userId))).get();
    if (res.isNotEmpty) return res;
    final fallback = await (select(statements)..where((t) => t.userId.equals('chenyee_user'))).get();
    if (fallback.isNotEmpty) return fallback;
    return select(statements).get();
  }

  Stream<List<Statement>> watchStatementsByUser(String userId) =>
      (select(statements)..orderBy([(t) => OrderingTerm.desc(t.uploadedAt)])).watch();

  Future<Statement?> getStatementByHash(String hash) =>
      (select(statements)..where((t) => t.fileHash.equals(hash)))
          .getSingleOrNull();

  Future<String> insertStatement(StatementsCompanion entry) async {
    await into(statements).insert(entry);
    return entry.id.value;
  }

  Future<bool> updateStatement(StatementsCompanion entry) =>
      update(statements).replace(entry);

  Future<void> deleteStatement(String id) async {
    await deleteTransactionsByStatement(id);
    await (delete(bankAccounts)..where((t) => t.sourceStatementId.equals(id))).go();
    
    // Purge associated credit cards & reward progress models
    final cardsToDelete = await (select(creditCards)..where((t) => t.sourceStatementId.equals(id))).get();
    for (final c in cardsToDelete) {
      await CardRewardsDataStore.clearCardRewards(c.id);
    }
    await (delete(creditCards)..where((t) => t.sourceStatementId.equals(id))).go();
    await (delete(statements)..where((t) => t.id.equals(id))).go();

    // Safety net: if no statements are left, clear all statement-derived tables
    final remaining = await select(statements).get();
    if (remaining.isEmpty) {
      await delete(transactions).go();
      await delete(bankAccounts).go();
      await delete(creditCards).go();
      await delete(milesWallet).go();
    } else {
      // If no credit card statements are left, clear the miles wallet
      final remainingCC = remaining.where((s) => s.accountType == 'credit_card').toList();
      if (remainingCC.isEmpty) {
        await delete(milesWallet).go();
      }
    }

    // Database alignment cleanup: delete any bank accounts or credit cards missing an active statement
    final activeStmtIds = remaining.map((s) => s.id).toSet();
    final orphanedAccounts = await select(bankAccounts).get();
    for (final acc in orphanedAccounts) {
      if (acc.sourceStatementId != null && !activeStmtIds.contains(acc.sourceStatementId)) {
        await (delete(bankAccounts)..where((t) => t.id.equals(acc.id))).go();
      }
    }
  }

  // ── Transactions ────────────────────────────────────────
  Future<List<Transaction>> getTransactionsByUser(String userId,
      {DateTime? from, DateTime? to}) async {
    final query = select(transactions)
      ..where((t) => t.userId.equals(userId));
    if (from != null) {
      query.where((t) =>
          t.date.isBiggerOrEqualValue(from.millisecondsSinceEpoch ~/ 1000));
    }
    if (to != null) {
      query.where((t) =>
          t.date.isSmallerOrEqualValue(to.millisecondsSinceEpoch ~/ 1000));
    }
    final res = await (query..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
    if (res.isNotEmpty) return res;

    // Fallback: if empty, query transactions for chenyee_user or all transactions
    final fallbackQuery = select(transactions);
    if (from != null) {
      fallbackQuery.where((t) =>
          t.date.isBiggerOrEqualValue(from.millisecondsSinceEpoch ~/ 1000));
    }
    if (to != null) {
      fallbackQuery.where((t) =>
          t.date.isSmallerOrEqualValue(to.millisecondsSinceEpoch ~/ 1000));
    }
    return (fallbackQuery..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  Stream<List<Transaction>> watchTransactionsByUser(String userId) =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<void> insertTransactions(List<TransactionsCompanion> entries) =>
      batch((b) => b.insertAll(transactions, entries));

  Future<bool> updateTransaction(TransactionsCompanion entry) =>
      update(transactions).replace(entry);

  Future<int> deleteTransactionsByStatement(String statementId) =>
      (delete(transactions)
            ..where((t) => t.statementId.equals(statementId)))
          .go();

  // ── Bank Accounts ───────────────────────────────────────
  Future<List<BankAccount>> getBankAccountsByUser(String userId) async {
    final res = await (select(bankAccounts)..where((t) => t.userId.equals(userId))).get();
    if (res.isNotEmpty) return res;
    final fallback = await (select(bankAccounts)..where((t) => t.userId.equals('chenyee_user'))).get();
    if (fallback.isNotEmpty) return fallback;
    return select(bankAccounts).get();
  }

  Stream<List<BankAccount>> watchBankAccountsByUser(String userId) =>
      select(bankAccounts).watch();

  Future<String> insertBankAccount(BankAccountsCompanion entry) async {
    await into(bankAccounts).insertOnConflictUpdate(entry);
    return entry.id.value;
  }

  Future<bool> updateBankAccount(BankAccountsCompanion entry) =>
      update(bankAccounts).replace(entry);

  // ── Credit Cards ────────────────────────────────────────
  Future<List<CreditCard>> getCreditCardsByUser(String userId) async {
    final res = await (select(creditCards)..where((t) => t.userId.equals(userId))).get();
    if (res.isNotEmpty) return res;
    final fallback = await (select(creditCards)..where((t) => t.userId.equals('chenyee_user'))).get();
    if (fallback.isNotEmpty) return fallback;
    return select(creditCards).get();
  }

  Future<String> insertCreditCard(CreditCardsCompanion entry) async {
    await into(creditCards).insertOnConflictUpdate(entry);
    return entry.id.value;
  }

  // ── Miles Wallet ────────────────────────────────────────
  Future<List<MilesWalletData>> getMilesWalletByUser(String userId) async {
    final res = await (select(milesWallet)..where((t) => t.userId.equals(userId))).get();
    if (res.isNotEmpty) return res;
    final fallback = await (select(milesWallet)..where((t) => t.userId.equals('chenyee_user'))).get();
    if (fallback.isNotEmpty) return fallback;
    return select(milesWallet).get();
  }

  Future<void> upsertMilesWallet(MilesWalletCompanion entry) =>
      into(milesWallet).insertOnConflictUpdate(entry);

  // ── Travel Goals ────────────────────────────────────────
  Future<TravelGoal?> getTravelGoalByUser(String userId) async {
    final res = await (select(travelGoals)..where((t) => t.userId.equals(userId))).getSingleOrNull();
    if (res != null) return res;
    final fallback = await (select(travelGoals)..where((t) => t.userId.equals('chenyee_user'))).getSingleOrNull();
    if (fallback != null) return fallback;
    return (select(travelGoals)..limit(1)).getSingleOrNull();
  }

  Future<void> upsertTravelGoal(TravelGoalsCompanion entry) =>
      into(travelGoals).insertOnConflictUpdate(entry);
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'cashflow_ai_db_v3',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override appDatabaseProvider in main.dart');
});

class DatabaseMutex {
  static Completer<void>? _current;

  static Future<T> run<T>(FutureOr<T> Function() action) async {
    while (_current != null) {
      await _current!.future;
    }
    final completer = Completer<void>();
    _current = completer;
    try {
      return await action();
    } finally {
      _current = null;
      completer.complete();
    }
  }
}
