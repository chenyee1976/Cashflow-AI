import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/database/app_database.dart';
import '../../../../data/secure_storage/secure_storage_service.dart';
import '../../../../core/constants/category_enum.dart';
import 'package:drift/drift.dart' as drift;

class CashFlowMonthData {
  final double totalIncome;
  final double totalExpenses;
  final double netCashFlow;
  final double transferMismatch; // If transfers do not net to 0
  final List<CategoryProgressItem> topCategories;
  final List<Transaction> transactions;
  final Map<String, String> accountNamesMap;

  const CashFlowMonthData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netCashFlow,
    required this.transferMismatch,
    required this.topCategories,
    required this.transactions,
    required this.accountNamesMap,
  });
}

class CategoryProgressItem {
  final String categoryName;
  final double amount;
  final double percentage;

  const CategoryProgressItem({
    required this.categoryName,
    required this.amount,
    required this.percentage,
  });
}

// Current Selected Month state
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// Category Filter: 'all' | 'income' | 'expense'
final cashFlowFilterProvider = StateProvider<String>((ref) => 'all');

// Core cashflow selector query
final cashFlowScreenProvider = FutureProvider.autoDispose<CashFlowMonthData>((ref) async {
  final selectedMonth = ref.watch(selectedMonthProvider);
  final filter = ref.watch(cashFlowFilterProvider);
  final db = ref.watch(appDatabaseProvider);
  const userId = 'chenyee_user';

  List<Transaction> allTxs = [];
  int retries = 20;
  while (true) {
    try {
      allTxs = await db.getTransactionsByUser(userId);
      break;
    } catch (e) {
      if (retries > 0) {
        retries--;
        await Future.delayed(const Duration(milliseconds: 200));
      } else {
        rethrow;
      }
    }
  }
  final monthTxs = allTxs.where((t) {
    final d = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
    return d.year == selectedMonth.year && d.month == selectedMonth.month;
  }).toList();

  double income = 0.0;
  double expenses = 0.0;
  double transfersIn = 0.0;
  double transfersOut = 0.0;

    Map<String, double> categorySums = {};

    for (var tx in monthTxs) {
      final category = TransactionCategory.fromValue(tx.category);
      if (category == TransactionCategory.incomeTransfer || category == TransactionCategory.expenseTransfer) {
        if (tx.amount > 0) {
          transfersIn += tx.amount;
        } else {
          transfersOut += tx.amount.abs();
        }
      } else if (tx.amount > 0) {
        income += tx.amount;
      } else {
        expenses += tx.amount.abs();
        // Group expenses for top category analysis
        final catName = category.displayName;
        categorySums[catName] = (categorySums[catName] ?? 0.0) + tx.amount.abs();
      }
    }

    // Transfers net check
    final mismatch = (transfersIn - transfersOut).abs();

    // Create progress bars list
    final totalExpensesForCategories = expenses > 0 ? expenses : 1.0;
    final categoriesList = categorySums.entries.map((e) {
      return CategoryProgressItem(
        categoryName: e.key,
        amount: e.value,
        percentage: e.value / totalExpensesForCategories,
      );
    }).toList();

    categoriesList.sort((a, b) => b.amount.compareTo(a.amount));

    // Fetch account details to sort by Bank Account Name (with retry for busy DB)
    List<BankAccount> bankAccounts = [];
    List<CreditCard> cardAccounts = [];
    int retries2 = 10;
    while (true) {
      try {
        bankAccounts = await db.getBankAccountsByUser(userId);
        cardAccounts = await db.getCreditCardsByUser(userId);
        break;
      } catch (e) {
        if (retries2 > 0) {
          retries2--;
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          rethrow;
        }
      }
    }

    // Map account ID to bank name / issuer name
    final accountNames = <String, String>{};
    accountNames['manual_cash'] = 'Cash on hand / Manual Entries';
    accountNames['manual'] = 'Cash on hand / Manual Entries';
    for (final b in bankAccounts) {
      accountNames[b.id] = '${b.bankName} ${b.accountType} (${b.accountNumber ?? ""})';
    }
    for (final c in cardAccounts) {
      accountNames[c.id] = '${c.bankName} ${c.cardName} (${c.lastFour ?? ""})';
    }

    // Sort transactions by bank account name, then descending by date
    final sortedTxs = List<Transaction>.from(monthTxs)
      ..sort((a, b) {
        final nameA = accountNames[a.accountId] ?? 'Cash on hand / Manual Entries';
        final nameB = accountNames[b.accountId] ?? 'Cash on hand / Manual Entries';
        final bankComp = nameA.compareTo(nameB);
        if (bankComp != 0) return bankComp;
        return b.date.compareTo(a.date); // Descending by date
      });

    // Filter transactions list
    final filteredTxs = sortedTxs.where((tx) {
      final category = TransactionCategory.fromValue(tx.category);
      final isTransferCat = category == TransactionCategory.incomeTransfer ||
          category == TransactionCategory.expenseTransfer ||
          category == TransactionCategory.expenseTransferToCash;

      if (filter == 'transfer') {
        return isTransferCat;
      }
      if (filter == 'income') return tx.amount > 0 && !isTransferCat;
      if (filter == 'expense') return tx.amount < 0 && !isTransferCat;
      return true;
    }).toList();


    return CashFlowMonthData(
      totalIncome: income,
      totalExpenses: expenses,
      netCashFlow: income - expenses,
      transferMismatch: mismatch > 0.01 ? mismatch : 0.0,
      topCategories: categoriesList,
      transactions: filteredTxs,
      accountNamesMap: accountNames,
    );
});

// Operations class for manual entries addition and removal
class CashFlowOperations {
  final AppDatabase _db;
  final Ref _ref;

  CashFlowOperations(this._db, this._ref);

  Future<void> addManualTransaction({
    required String merchant,
    required double amount,
    required TransactionCategory category,
    required DateTime date,
    String accountId = 'manual_cash',
  }) async {
    final storage = _ref.read(secureStorageProvider);
    final userId = await storage.getUserId() ?? 'unknown_user';

    await _db.insertTransactions([
      TransactionsCompanion.insert(
        id: const Uuid().v4(),
        userId: userId,
        accountId: accountId,
        accountType: 'manual',
        date: date.millisecondsSinceEpoch ~/ 1000,
        merchant: merchant,
        description: merchant,
        amount: amount,
        category: category.value,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      )
    ]);

    // Force refresh
    _ref.invalidate(cashFlowScreenProvider);
  }

  Future<void> deleteTransaction(String id) async {
    // Implement delete using transaction id via query update or delete
    // Drift provides delete queries directly
    final query = _db.delete(_db.transactions)..where((t) => t.id.equals(id));
    await query.go();
    
    // Force refresh
    _ref.invalidate(cashFlowScreenProvider);
  }
}

final cashFlowOperationsProvider = Provider((ref) {
  return CashFlowOperations(ref.watch(appDatabaseProvider), ref);
});
