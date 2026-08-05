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
  final double prevYearBalance;
  final String currentDateStr;
  final String prevMonthDateStr;
  final String prevYearDateStr;
  final List<BankAccount> accounts;
  final Map<String, double> prevMonthBalances;
  final Map<String, double> prevYearBalances;
  final Map<String, double> fxRates;

  const CashPositionModel({
    required this.currentBalance,
    required this.prevMonthBalance,
    required this.prevYearBalance,
    required this.currentDateStr,
    required this.prevMonthDateStr,
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

double _calculateBalanceAsOf(List<BankAccount> consolidatedAccounts, List<BankAccount> allAccounts, List<Transaction> transactions, DateTime date) {
  final targetTimestamp = date.millisecondsSinceEpoch ~/ 1000;

  String _normalize(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();

  double balance = 0.0;
  for (final acc in consolidatedAccounts) {
    double accBalance = acc.currentBalance;
    final key = '${_normalize(acc.bankName)}_${_normalize(acc.accountNumber ?? '')}';
    final familyIds = allAccounts
        .where((a) => '${_normalize(a.bankName)}_${_normalize(a.accountNumber ?? '')}' == key)
        .map((a) => a.id)
        .toSet();

    final familyTxs = transactions.where((t) => familyIds.contains(t.accountId));
    final validTxs = familyTxs.where((t) => t.date > 946684800); // Filter for year >= 2000

    if (validTxs.isEmpty) {
      if (date.year < DateTime.now().year) {
        continue;
      }
      balance += accBalance;
      continue;
    }

    final earliestFamilyTx = validTxs.map((t) => t.date).reduce((a, b) => a < b ? a : b);
    if (targetTimestamp < earliestFamilyTx) {
      // Target date is before the account's earliest activity, so balance was 0.0
      continue;
    }

    // Find all transactions for this account family that occurred AFTER the target date
    final afterTxs = validTxs.where((t) => t.date > targetTimestamp);
    for (final tx in afterTxs) {
      // Subtract incoming amount, add outgoing amount to backtrack
      accBalance -= tx.amount;
    }
    balance += accBalance;
  }
  return balance;
}

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

    // Check if a statement exists for this account family that covers or precedes the target month
    final key = '${_normalize(acc.bankName)}_${_normalize(acc.accountNumber ?? '')}';
    final familyAccIds = allAccounts
        .where((a) => '${_normalize(a.bankName)}_${_normalize(a.accountNumber ?? '')}' == key)
        .map((a) => a.id)
        .toSet();

    final familyStatementIds = allAccounts
        .where((a) => familyAccIds.contains(a.id))
        .map((a) => a.sourceStatementId)
        .whereType<String>()
        .toSet();

    final familyStatements = statements.where((s) => familyStatementIds.contains(s.id) || (s.bankOrCard != null && _normalize(s.bankOrCard!) == _normalize(acc.bankName)));

    int earliestStatementStart = 9999999999;
    for (final s in familyStatements) {
      final pStart = s.periodStart ?? s.uploadedAt;
      if (pStart < earliestStatementStart) {
        earliestStatementStart = pStart;
      }
    }

    final familyTxs = transactions.where((t) => familyAccIds.contains(t.accountId));
    final validTxs = familyTxs.where((t) => t.date > 946684800);

    if (validTxs.isNotEmpty) {
      final earliestTxDate = validTxs.map((t) => t.date).reduce((a, b) => a < b ? a : b);
      if (earliestTxDate < earliestStatementStart) {
        earliestStatementStart = earliestTxDate;
      }
    }

    // If target month is prior to the earliest uploaded statement start (or 1st of statement month), return 0.0
    if (targetTimestamp < earliestStatementStart && startOfMonthTimestamp < (earliestStatementStart - 86400 * 25)) {
      balances[acc.id] = 0.0;
      continue;
    }

    double accBalance = acc.currentBalance;
    if (validTxs.isEmpty) {
      balances[acc.id] = accBalance;
      continue;
    }

    // Find transactions for this account family that occurred AFTER the target date
    final afterTxs = validTxs.where((t) => t.date > targetTimestamp);
    for (final tx in afterTxs) {
      // Subtract incoming amount, add outgoing amount to backtrack
      accBalance -= tx.amount;
    }
    balances[acc.id] = accBalance;
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
  final endOfLastYear = DateTime(targetMonth.year - 1, 12, 31, 23, 59, 59);

  final prevMonthBase = await storage.getCashOnHandBaseForMonth(year: endOfLastMonth.year, month: endOfLastMonth.month) ?? 0.0;
  final prevYearBase = await storage.getCashOnHandBaseForMonth(year: endOfLastYear.year, month: endOfLastYear.month) ?? 0.0;

  final monthBases = {
    '${targetMonth.year}_${targetMonth.month}': targetMonthBase,
    '${endOfLastMonth.year}_${endOfLastMonth.month}': prevMonthBase,
    '${endOfLastYear.year}_${endOfLastYear.month}': prevYearBase,
  };

  // Calculate balances converting non-SGD on the fly:
  double prevMonthBalance = 0.0;
  final prevMonthBalances = _calculateIndividualBalancesAsOf(consolidatedAccounts, accounts, transactions, statements, endOfLastMonth, monthCashBases: monthBases);
  for (final item in consolidatedAccounts) {
    final bal = prevMonthBalances[item.id] ?? 0.0;
    final currencyStr = item.currency.trim().toUpperCase();
    if (currencyStr == 'SGD') {
      prevMonthBalance += bal;
    } else {
      final savedRate = await storage.getFxRate(currencyStr);
      final rate = double.tryParse(savedRate ?? '') ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
      prevMonthBalance += bal * rate;
    }
  }

  double prevYearBalance = 0.0;
  final prevYearBalances = _calculateIndividualBalancesAsOf(consolidatedAccounts, accounts, transactions, statements, endOfLastYear, monthCashBases: monthBases);
  for (final item in consolidatedAccounts) {
    final bal = prevYearBalances[item.id] ?? 0.0;
    final currencyStr = item.currency.trim().toUpperCase();
    if (currencyStr == 'SGD') {
      prevYearBalance += bal;
    } else {
      final savedRate = await storage.getFxRate(currencyStr);
      final rate = double.tryParse(savedRate ?? '') ?? (currencyStr == 'USD' ? 1.30 : (currencyStr == 'JPY' ? 0.0080 : 1.0));
      prevYearBalance += bal * rate;
    }
  }

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
    prevYearBalance: prevYearBalance,
    currentDateStr: _formatDate(endOfTargetMonth),
    prevMonthDateStr: _formatDate(endOfLastMonth),
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
    prevYearBalance: 0.0,
    currentDateStr: _formatDate(now),
    prevMonthDateStr: _formatDate(DateTime(now.year, now.month, 0)),
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
