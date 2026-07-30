import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/database/app_database.dart';
import '../../../data/secure_storage/secure_storage_service.dart';
import 'package:drift/drift.dart';
import '../cashflow/statement/cashflow_provider.dart';
import '../dashboard/dashboard_provider.dart';

class AccountProfileData {
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String email;
  final String rewardFocus;
  final String currency;
  final int bankCount;
  final int cardCount;
  final List<BankAccount> bankAccounts;
  final List<CreditCard> creditCards;

  const AccountProfileData({
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.email,
    required this.rewardFocus,
    required this.currency,
    required this.bankCount,
    required this.cardCount,
    this.bankAccounts = const [],
    this.creditCards = const [],
  });
}

final accountProfileProvider = FutureProvider.autoDispose<AccountProfileData>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final storage = ref.watch(secureStorageProvider);
  const userId = 'chenyee_user';

  List<BankAccount> banks = [];
  User? user;
  List<CreditCard> cards = [];

  int retries = 20;
  while (true) {
    try {
      banks = await db.getBankAccountsByUser(userId);
      user = await db.getUserById(userId);
      cards = await db.getCreditCardsByUser(userId);
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

  final prefs = await SharedPreferences.getInstance();
  final prefFName = prefs.getString('tester_first_name');
  final prefLName = prefs.getString('tester_last_name');
  final prefEmail = prefs.getString('tester_email');

  final mobile = await storage.getMobileNumber() ?? '';
  final rawRewardFocus = await storage.getRewardFocus() ?? 'both';
  // Capitalize first letter to match dropdown options ('Miles', 'Cashback', 'Both')
  final rewardFocus = rawRewardFocus.toLowerCase() == 'both' 
      ? 'Both' 
      : (rawRewardFocus.toLowerCase() == 'miles' ? 'Miles' : 'Cashback');

  String _normalize(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  final Map<String, BankAccount> uniqueAccounts = {};
  for (final acc in banks) {
    final key = '${_normalize(acc.bankName)}_${_normalize(acc.accountNumber ?? '')}';
    uniqueAccounts[key] = acc;
  }
  final consolidatedAccounts = uniqueAccounts.values.toList();

  final Map<String, CreditCard> uniqueCards = {};
  for (final card in cards) {
    final key = '${_normalize(card.bankName)}_${_normalize(card.cardName)}_${_normalize(card.lastFour ?? '')}';
    uniqueCards[key] = card;
  }
  final consolidatedCards = uniqueCards.values.toList();

  String fName = prefFName?.isNotEmpty == true ? prefFName! : (user?.firstName.isNotEmpty == true && user?.firstName != 'SG' ? user!.firstName : 'Beta');
  String lName = prefLName?.isNotEmpty == true ? prefLName! : (user?.lastName.isNotEmpty == true && user?.lastName != 'Individual' ? user!.lastName : 'Tester');
  String email = prefEmail?.isNotEmpty == true ? prefEmail! : (user?.email.isNotEmpty == true && user?.email != 'user@cashflowai.sg' ? user!.email : 'beta.tester@example.com');

  return AccountProfileData(
    firstName: fName,
    lastName: lName,
    mobileNumber: mobile,
    email: email,
    rewardFocus: rewardFocus,
    currency: 'SGD',
    bankCount: consolidatedAccounts.length,
    cardCount: consolidatedCards.length,
    bankAccounts: consolidatedAccounts,
    creditCards: consolidatedCards,
  );
});

class AccountOperations {
  final AppDatabase _db;
  final SecureStorageService _storage;
  final Ref _ref;

  AccountOperations(this._db, this._storage, this._ref);

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String mobileNumber,
    required String rewardFocus,
  }) async {
    final userId = await _storage.getUserId();
    if (userId != null) {
      await DatabaseMutex.run(() => _db.updateUser(
        UsersCompanion(
          id: Value(userId),
          firstName: Value(firstName),
          lastName: Value(lastName),
        ),
      ));
    }
    await _storage.saveMobileNumber(mobileNumber);
    await _storage.saveRewardFocus(rewardFocus);
    _ref.invalidate(accountProfileProvider);
  }

  Future<void> clearAllData() async {
    var userId = await _storage.getUserId();
    if (userId == null || userId.isEmpty || userId == 'unknown_user') {
      userId = 'chenyee_user';
    }

    int retries = 20;
    while (true) {
      try {
        await (_db.delete(_db.transactions)..where((t) => t.userId.equals(userId!))).go();
        await (_db.delete(_db.bankAccounts)..where((t) => t.userId.equals(userId!))).go();
        await (_db.delete(_db.creditCards)..where((t) => t.userId.equals(userId!))).go();
        await (_db.delete(_db.statements)..where((t) => t.userId.equals(userId!))).go();
        await (_db.delete(_db.milesWallet)..where((t) => t.userId.equals(userId!))).go();
        await (_db.delete(_db.travelGoals)..where((t) => t.userId.equals(userId!))).go();
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

    _ref.invalidate(accountProfileProvider);
    _ref.invalidate(cashFlowScreenProvider);
    _ref.invalidate(cashPositionProvider);
    _ref.invalidate(monthlyIncomeProvider);
    _ref.invalidate(monthlyExpensesProvider);
  }

  Future<void> signOut() async {
    await _storage.clearAll();
  }
}

final accountOperationsProvider = Provider((ref) {
  return AccountOperations(
    ref.watch(appDatabaseProvider),
    ref.watch(secureStorageProvider),
    ref,
  );
});
