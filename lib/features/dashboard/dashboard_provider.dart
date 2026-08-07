import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../data/secure_storage/secure_storage_service.dart';
import '../../core/constants/category_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../cashflow/statement/cashflow_provider.dart';

// Cash Position display model
class CashPositionModel {
  final double currentBalance;
  final double prevMonthBalance;
  final double twoMonthsAgoBalance;
  final double threeMonthsAgoBalance;
  final double prevYearBalance;
  final String currentDateStr;
  final String prevMonthDateStr;
  final String twoMonthsAgoDateStr;
  final String threeMonthsAgoDateStr;
  final String prevYearDateStr;
  final List<BankAccount> accounts;
  final Map<String, double> prevMonthBalances;
  final Map<String, double> prevYearBalances;
  final Map<String, double> fxRates;

  const CashPositionModel({
    required this.currentBalance,
    required this.prevMonthBalance,
    required this.twoMonthsAgoBalance,
    required this.threeMonthsAgoBalance,
    required this.prevYearBalance,
    required this.currentDateStr,
    required this.prevMonthDateStr,
    required this.twoMonthsAgoDateStr,
    required this.threeMonthsAgoDateStr,
    required this.prevYearDateStr,
    this.accounts = const [],
    this.prevMonthBalances = const {},
    this.prevYearBalances = const {},
    this.fxRates = const {},
  });
}

// Income/Expense months model
class MonthSummaryModel {
  final double currentMonthAmount;
  final double lastMonthAmount;
  final double twoMonthsAgoAmount;
  final String currentMonthStr;
  final String lastMonthStr;
  final String twoMonthsAgoStr;
  
  final Map<String, double> currentMonthBreakdown;
  final Map<String, double> lastMonthBreakdown;
  final Map<String, double> twoMonthsAgoBreakdown;

  const MonthSummaryModel({
    required this.currentMonthAmount,
    required this.lastMonthAmount,
    required this.twoMonthsAgoAmount,
    required this.currentMonthStr,
    required this.lastMonthStr,
    required this.twoMonthsAgoStr,
    this.currentMonthBreakdown = const {},
    this.lastMonthBreakdown = const {},
    this.twoMonthsAgoBreakdown = const {},
  });
}

// User Profile Provider
final userProfileProvider = FutureProvider.autoDispose<User?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final db = ref.watch(appDatabaseProvider);
  final prefs = await SharedPreferences.getInstance();
  final testerEmail = prefs.getString('tester_email') ?? '';
  var userId = await storage.getUserId();
  if (userId == null || userId.isEmpty || userId == 'unknown_user') {
    userId = testerEmail.contains('@') ? 'tester_${testerEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}' : 'chenyee_user';
  }
  return db.getUserById(userId!);
});


Map<String, double> _calculateIndividualBalancesAsOf(
    List<BankAccount> consolidatedAccounts,
    List<BankAccount> allAccounts,
    List<Transaction> transactions,
    List<Statement> statements,
    DateTime date,
    {Map<String, double> monthCashBases = const {}}) {
  final targetTimestamp = date.millisecondsSinceEpoch ~/ 1000;
  final startOfMonthTimestamp = DateTime(date.year, date.month, 1).millisecondsSinceEpoch ~/ 1000;
  String _normalize(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

  final Map<String, double> balances = {};
  for (final acc in consolidatedAccounts) {
    if (acc.id == 'manual_cash_account') {
      // Calculate total cash expenses + ATM cash withdrawals up to target date:
      double cashTxsUpToDate = 0.0;
      bool hasCashTxs = false;
      for (final tx in transactions) {
        if (tx.date <= targetTimestamp) {
          if (tx.accountId == 'manual_cash' || tx.accountId == 'manual') {
            cashTxsUpToDate += tx.amount;
            hasCashTxs = true;
          } else if (tx.category == TransactionCategory.expenseTransferToCash.value) {
            cashTxsUpToDate += tx.amount.abs();
            hasCashTxs = true;
          }
        }
      }
      final base = monthCashBases['${date.year}_${date.month}'] ?? 0.0;
      if (base == 0.0 && !hasCashTxs) {
        balances[acc.id] = 0.0;
      } else {
        balances[acc.id] = base + cashTxsUpToDate;
      }
      continue;
    }

    // Find all bank account snapshot records matching this physical bank/account number
    final sameAccountSnapshots = allAccounts.where((a) =>
      _normalize(a.bankName) == _normalize(acc.bankName) &&
      _normalize(a.accountNumber ?? '') == _normalize(acc.accountNumber ?? '')
    ).toList();

    // Find the snapshot whose statement date is on or closest-before target month
    BankAccount? bestMatchAccount;
    DateTime? bestMatchDate;

    final targetMonthStart = DateTime(date.year, date.month, 1);

    for (final snap in sameAccountSnapshots) {
      final matchedStmt = statements.where((s) => s.id == snap.sourceStatementId).firstOrNull;
      if (snap.sourceStatementId != null && matchedStmt == null) continue;

      DateTime? stmtDate;
      if (matchedStmt != null && matchedStmt.periodEnd != null) {
        stmtDate = DateTime.fromMillisecondsSinceEpoch(matchedStmt.periodEnd! * 1000);
      } else if (snap.createdAt > 0) {
        stmtDate = DateTime.fromMillisecondsSinceEpoch(snap.createdAt * 1000);
      }

      if (stmtDate == null) continue;
      final snapMonthStart = DateTime(stmtDate.year, stmtDate.month, 1);

      // Must be on or before target month
      if (!snapMonthStart.isAfter(targetMonthStart)) {
        if (bestMatchDate == null || snapMonthStart.isAfter(bestMatchDate)) {
          bestMatchDate = snapMonthStart;
          bestMatchAccount = snap;
        }
      }
    }

    if (bestMatchAccount == null) {
      balances[acc.id] = 0.0;
    } else {
      balances[acc.id] = bestMatchAccount.currentBalance;
    }
  }
  return balances;
}

// Cash Position Provider (Stream-based - synchronous user query to prevent OperationError)
final cashPositionProvider = FutureProvider.autoDispose<CashPositionModel>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final storage = ref.read(secureStorageProvider);
  final prefs = await SharedPreferences.getInstance();
  final testerEmail = prefs.getString('tester_email') ?? '';
  var userId = await storage.getUserId();
  if (userId == null || userId.isEmpty || userId == 'unknown_user') {
    userId = testerEmail.contains('@') ? 'tester_${testerEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}' : 'chenyee_user';
  }

  List<BankAccount> accounts = [];
  List<Transaction> transactions = [];
  List<Statement> statements = [];
  int retries = 20;

  while (true) {
    try {
      accounts = await DatabaseMutex.run(() => db.getBankAccountsByUser(userId!));
      transactions = await DatabaseMutex.run(() => db.getTransactionsByUser(userId!));
      statements = await DatabaseMutex.run(() => db.getStatementsByUser(userId!));
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

  String _normalize(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  final Map<String, BankAccount> uniqueAccounts = {};
  for (final acc in accounts) {
    final key = '${_normalize(acc.bankName)}_${_normalize(acc.accountNumber ?? '')}';
    if (!uniqueAccounts.containsKey(key)) {
      uniqueAccounts[key] = acc;
    } else {
      uniqueAccounts[key] = acc;
    }
  }
  final consolidatedAccounts = uniqueAccounts.values.toList();

  // Calculate net cash adjustments:
  // 1) Manual cash expenses (negative)
  // 2) ATM cash withdrawals categorized as 'expense_transfer_to_cash' (adds to cash on hand)
  double cashAdjustmentsTotal = 0.0;
  for (final tx in transactions) {
    if (tx.accountId == 'manual_cash' || tx.accountId == 'manual') {
      cashAdjustmentsTotal += tx.amount; // Negative for expense
    } else if (tx.category == TransactionCategory.expenseTransferToCash.value) {
      cashAdjustmentsTotal += tx.amount.abs(); // Positive addition to Cash on hand
    }
  }

  final targetMonth = ref.watch(selectedMonthProvider);
  final endOfTargetMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

  final targetMonthBase = await storage.getCashOnHandBaseForMonth(year: targetMonth.year, month: targetMonth.month) ?? 0.0;
  final currentCashOnHand = targetMonthBase + cashAdjustmentsTotal;

  final cashOnHandAcc = BankAccount(
    id: 'manual_cash_account',
    userId: userId,
    bankName: 'Cash on hand',
    accountType: 'Physical Cash Pool',
    accountNumber: 'Wallet',
    currentBalance: currentCashOnHand,
    openingBalance: targetMonthBase,
    currency: 'SGD',
    sourceStatementId: null,
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
  consolidatedAccounts.add(cashOnHandAcc);

  // Compute per-account individual balances as of the end of the targetMonth
  final targetBalances = _calculateIndividualBalancesAsOf(
    consolidatedAccounts,
    accounts,
    transactions,
    statements,
    endOfTargetMonth,
    monthCashBases: {'${targetMonth.year}_${targetMonth.month}': targetMonthBase},
  );

  final updatedConsolidatedAccounts = consolidatedAccounts.map((acc) {
    final bal = targetBalances[acc.id] ?? 0.0;
    return BankAccount(
      id: acc.id,
      userId: acc.userId,
      bankName: acc.bankName,
      accountType: acc.accountType,
      accountNumber: acc.accountNumber,
      currentBalance: bal,
      openingBalance: acc.openingBalance,
      currency: acc.currency,
      sourceStatementId: acc.sourceStatementId,
      createdAt: acc.createdAt,
    );
  }).toList();

  double current = 0.0;
  for (final item in updatedConsolidatedAccounts) {
    final currencyStr = item.currency.trim().toUpperCase();
    if (currencyStr == 'SGD') {
      current += item.currentBalance;
    } else {
      final savedRate = await storage.getFxRate(currencyStr);
      final rate = double.tryParse(savedRate ?? '') ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
      current += item.currentBalance * rate;
    }
  }

  final endOfLastMonth = DateTime(targetMonth.year, targetMonth.month, 0, 23, 59, 59);
  final endOfTwoMonthsAgo = DateTime(targetMonth.year, targetMonth.month - 1, 0, 23, 59, 59);
  final endOfThreeMonthsAgo = DateTime(targetMonth.year, targetMonth.month - 2, 0, 23, 59, 59);
  final endOfLastYear = DateTime(targetMonth.year - 1, 12, 31, 23, 59, 59);

  final prevMonthBase = await storage.getCashOnHandBaseForMonth(year: endOfLastMonth.year, month: endOfLastMonth.month) ?? 0.0;
  final twoMonthsAgoBase = await storage.getCashOnHandBaseForMonth(year: endOfTwoMonthsAgo.year, month: endOfTwoMonthsAgo.month) ?? 0.0;
  final threeMonthsAgoBase = await storage.getCashOnHandBaseForMonth(year: endOfThreeMonthsAgo.year, month: endOfThreeMonthsAgo.month) ?? 0.0;
  final prevYearBase = await storage.getCashOnHandBaseForMonth(year: endOfLastYear.year, month: endOfLastYear.month) ?? 0.0;

  final monthBases = {
    '${targetMonth.year}_${targetMonth.month}': targetMonthBase,
    '${endOfLastMonth.year}_${endOfLastMonth.month}': prevMonthBase,
    '${endOfTwoMonthsAgo.year}_${endOfTwoMonthsAgo.month}': twoMonthsAgoBase,
    '${endOfThreeMonthsAgo.year}_${endOfThreeMonthsAgo.month}': threeMonthsAgoBase,
    '${endOfLastYear.year}_${endOfLastYear.month}': prevYearBase,
  };

  // Helper to sum balances with FX conversion
  Future<double> _sumBalancesWithFx(Map<String, double> balMap) async {
    double total = 0.0;
    for (final item in consolidatedAccounts) {
      final bal = balMap[item.id] ?? 0.0;
      final currencyStr = item.currency.trim().toUpperCase();
      if (currencyStr == 'SGD') {
        total += bal;
      } else {
        final savedRate = await storage.getFxRate(currencyStr);
        final rate = double.tryParse(savedRate ?? '') ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
        total += bal * rate;
      }
    }
    return total;
  }

  // Calculate balances for all comparison periods:
  final prevMonthBalances = _calculateIndividualBalancesAsOf(consolidatedAccounts, accounts, transactions, statements, endOfLastMonth, monthCashBases: monthBases);
  final double prevMonthBalance = await _sumBalancesWithFx(prevMonthBalances);

  final twoMonthsAgoBalances = _calculateIndividualBalancesAsOf(consolidatedAccounts, accounts, transactions, statements, endOfTwoMonthsAgo, monthCashBases: monthBases);
  final double twoMonthsAgoBalance = await _sumBalancesWithFx(twoMonthsAgoBalances);

  final threeMonthsAgoBalances = _calculateIndividualBalancesAsOf(consolidatedAccounts, accounts, transactions, statements, endOfThreeMonthsAgo, monthCashBases: monthBases);
  final double threeMonthsAgoBalance = await _sumBalancesWithFx(threeMonthsAgoBalances);

  final prevYearBalances = _calculateIndividualBalancesAsOf(consolidatedAccounts, accounts, transactions, statements, endOfLastYear, monthCashBases: monthBases);
  final double prevYearBalance = await _sumBalancesWithFx(prevYearBalances);

  final Map<String, double> fxRatesMap = {};
  for (final item in consolidatedAccounts) {
    final currencyStr = item.currency.trim().toUpperCase();
    if (currencyStr != 'SGD') {
      final savedRate = await storage.getFxRate(currencyStr);
      final rate = double.tryParse(savedRate ?? '') ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
      fxRatesMap[currencyStr] = rate;
    }
  }

  return CashPositionModel(
    currentBalance: current,
    prevMonthBalance: prevMonthBalance,
    twoMonthsAgoBalance: twoMonthsAgoBalance,
    threeMonthsAgoBalance: threeMonthsAgoBalance,
    prevYearBalance: prevYearBalance,
    currentDateStr: _formatDate(endOfTargetMonth),
    prevMonthDateStr: _formatDate(endOfLastMonth),
    twoMonthsAgoDateStr: _formatDate(endOfTwoMonthsAgo),
    threeMonthsAgoDateStr: _formatDate(endOfThreeMonthsAgo),
    prevYearDateStr: _formatDate(endOfLastYear),
    accounts: updatedConsolidatedAccounts,
    prevMonthBalances: prevMonthBalances,
    prevYearBalances: prevYearBalances,
    fxRates: fxRatesMap,
  );
});

CashPositionModel _emptyCashPosition() {
  final now = DateTime.now();
  return CashPositionModel(
    currentBalance: 0.0,
    prevMonthBalance: 0.0,
    twoMonthsAgoBalance: 0.0,
    threeMonthsAgoBalance: 0.0,
    prevYearBalance: 0.0,
    currentDateStr: _formatDate(now),
    prevMonthDateStr: _formatDate(DateTime(now.year, now.month, 0)),
    twoMonthsAgoDateStr: _formatDate(DateTime(now.year, now.month - 1, 0)),
    threeMonthsAgoDateStr: _formatDate(DateTime(now.year, now.month - 2, 0)),
    prevYearDateStr: _formatDate(DateTime(now.year - 1, 12, 31)),
  );
}

// Monthly Income Provider (Inflows: amount > 0, Future-based)
final monthlyIncomeProvider = FutureProvider.autoDispose<MonthSummaryModel>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final storage = ref.read(secureStorageProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final prefs = await SharedPreferences.getInstance();
  final testerEmail = prefs.getString('tester_email') ?? '';
  var userId = await storage.getUserId();
  if (userId == null || userId.isEmpty || userId == 'unknown_user') {
    userId = testerEmail.contains('@') ? 'tester_${testerEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}' : 'chenyee_user';
  }

  List<Transaction> txs = [];
  int retries = 20;
  while (true) {
    try {
      txs = await db.getTransactionsByUser(userId!);
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

  final refDate = selectedMonth;

  final currentMonthTxs = txs.where((t) => _isSameMonth(t.date, refDate) && t.amount > 0 && t.category != 'income_transfer' && t.category != 'expense_transfer');
  final lastMonthTxs = txs.where((t) => _isSameMonth(t.date, DateTime(refDate.year, refDate.month - 1)) && t.amount > 0 && t.category != 'income_transfer' && t.category != 'expense_transfer');
  final twoMonthsAgoTxs = txs.where((t) => _isSameMonth(t.date, DateTime(refDate.year, refDate.month - 2)) && t.amount > 0 && t.category != 'income_transfer' && t.category != 'expense_transfer');

  return MonthSummaryModel(
    currentMonthAmount: currentMonthTxs.fold<double>(0.0, (sum, item) => sum + item.amount),
    lastMonthAmount: lastMonthTxs.fold<double>(0.0, (sum, item) => sum + item.amount),
    twoMonthsAgoAmount: twoMonthsAgoTxs.fold<double>(0.0, (sum, item) => sum + item.amount),
    currentMonthStr: _getMonthName(refDate),
    lastMonthStr: _getMonthName(DateTime(refDate.year, refDate.month - 1)),
    twoMonthsAgoStr: _getMonthName(DateTime(refDate.year, refDate.month - 2)),
    currentMonthBreakdown: _getSummaryBreakdown(currentMonthTxs),
    lastMonthBreakdown: _getSummaryBreakdown(lastMonthTxs),
    twoMonthsAgoBreakdown: _getSummaryBreakdown(twoMonthsAgoTxs),
  );
});

// Monthly Expenses Provider (Outflows: amount < 0, Future-based)
final monthlyExpensesProvider = FutureProvider.autoDispose<MonthSummaryModel>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final storage = ref.read(secureStorageProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);
  final prefs = await SharedPreferences.getInstance();
  final testerEmail = prefs.getString('tester_email') ?? '';
  var userId = await storage.getUserId();
  if (userId == null || userId.isEmpty || userId == 'unknown_user') {
    userId = testerEmail.contains('@') ? 'tester_${testerEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}' : 'chenyee_user';
  }

  List<Transaction> txs = [];
  int retries = 20;
  while (true) {
    try {
      txs = await db.getTransactionsByUser(userId!);
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

  final refDate = selectedMonth;

  final currentMonthTxs = txs.where((t) => _isSameMonth(t.date, refDate) && t.amount < 0 && t.category != 'income_transfer' && t.category != 'expense_transfer');
  final lastMonthTxs = txs.where((t) => _isSameMonth(t.date, DateTime(refDate.year, refDate.month - 1)) && t.amount < 0 && t.category != 'income_transfer' && t.category != 'expense_transfer');
  final twoMonthsAgoTxs = txs.where((t) => _isSameMonth(t.date, DateTime(refDate.year, refDate.month - 2)) && t.amount < 0 && t.category != 'income_transfer' && t.category != 'expense_transfer');

  return MonthSummaryModel(
    currentMonthAmount: currentMonthTxs.fold<double>(0.0, (sum, item) => sum + item.amount.abs()),
    lastMonthAmount: lastMonthTxs.fold<double>(0.0, (sum, item) => sum + item.amount.abs()),
    twoMonthsAgoAmount: twoMonthsAgoTxs.fold<double>(0.0, (sum, item) => sum + item.amount.abs()),
    currentMonthStr: _getMonthName(refDate),
    lastMonthStr: _getMonthName(DateTime(refDate.year, refDate.month - 1)),
    twoMonthsAgoStr: _getMonthName(DateTime(refDate.year, refDate.month - 2)),
    currentMonthBreakdown: _getSummaryBreakdown(currentMonthTxs),
    lastMonthBreakdown: _getSummaryBreakdown(lastMonthTxs),
    twoMonthsAgoBreakdown: _getSummaryBreakdown(twoMonthsAgoTxs),
  );
});

MonthSummaryModel _emptySummary() {
  final now = DateTime.now();
  return MonthSummaryModel(
    currentMonthAmount: 0.0,
    lastMonthAmount: 0.0,
    twoMonthsAgoAmount: 0.0,
    currentMonthStr: _getMonthName(now),
    lastMonthStr: _getMonthName(DateTime(now.year, now.month - 1)),
    twoMonthsAgoStr: _getMonthName(DateTime(now.year, now.month - 2)),
  );
}

bool _isSameMonth(int timestampSeconds, DateTime date) {
  final txDate = DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000);
  return txDate.year == date.year && txDate.month == date.month;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}

String _getMonthName(DateTime date) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[date.month - 1]} ${date.year}';
}

Map<String, double> _getSummaryBreakdown(Iterable<Transaction> items) {
  final breakdown = <String, double>{};
  for (final tx in items) {
    final cat = TransactionCategory.fromValue(tx.category).displayName;
    breakdown[cat] = (breakdown[cat] ?? 0.0) + tx.amount.abs();
  }
  return breakdown;
}
