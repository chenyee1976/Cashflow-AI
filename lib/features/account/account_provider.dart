import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/database/app_database.dart';
import '../../../data/secure_storage/secure_storage_service.dart';
import '../../../data/services/google_auth_service.dart';
import '../../../data/services/analytics_service.dart';
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
  final prefs = await SharedPreferences.getInstance();
  final testerEmail = prefs.getString('tester_email') ?? '';
  var userId = await storage.getUserId();
  if (userId == null || userId.isEmpty || userId == 'unknown_user') {
    userId = testerEmail.contains('@') ? 'tester_${testerEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}' : 'chenyee_user';
  }

  List<BankAccount> banks = [];
  User? user;
  List<CreditCard> cards = [];

  int retries = 20;
  while (true) {
    try {
      banks = await db.getBankAccountsByUser(userId!);
      user = await db.getUserById(userId!);
      cards = await db.getCreditCardsByUser(userId!);
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

  final prefFName = prefs.getString('tester_first_name');
  final prefLName = prefs.getString('tester_last_name');
  final prefEmail = prefs.getString('tester_email');
  final prefMobile = prefs.getString('tester_mobile');

  final savedMobile = await storage.getMobileNumber();
  final mobile = (savedMobile != null && savedMobile.isNotEmpty) ? savedMobile : (prefMobile ?? '');
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
    final email = await _storage.getGoogleEmail() ?? '';
    
    if (userId != null) {
      await DatabaseMutex.run(() => _db.updateUser(
        UsersCompanion(
          id: Value(userId),
          firstName: Value(firstName),
          lastName: Value(lastName),
        ),
      ));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tester_first_name', firstName);
    await prefs.setString('tester_last_name', lastName);
    await _storage.saveMobileNumber(mobileNumber);
    await _storage.saveRewardFocus(rewardFocus);

    // 1. Log event in activity_logs
    _ref.read(analyticsServiceProvider).logEvent('profile_updated', parameters: {
      'firstName': firstName,
      'lastName': lastName,
      'mobileNumber': mobileNumber,
      'rewardFocus': rewardFocus,
    });

    // 2. Sync updated name to Supabase registered_users table
    if (email.isNotEmpty) {
      _ref.read(analyticsServiceProvider).logEvent('user_registered', parameters: {
        'id': userId,
        'email': email,
        'displayName': '$firstName $lastName'.trim(),
        'firstName': firstName,
        'lastName': lastName,
      });
    }

    _ref.invalidate(accountProfileProvider);
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final testerEmail = prefs.getString('tester_email') ?? '';
    var userId = await _storage.getUserId();
    if (userId == null || userId.isEmpty || userId == 'unknown_user') {
      userId = testerEmail.contains('@') ? 'tester_${testerEmail.replaceAll(RegExp(r"[^a-zA-Z0-9]"), "_")}' : 'chenyee_user';
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
        await (_db.delete(_db.users)..where((t) => t.id.equals(userId!))).go();
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

    await _storage.clearAll();
    await prefs.clear();

    _ref.invalidate(accountProfileProvider);
    _ref.invalidate(cashFlowScreenProvider);
    _ref.invalidate(cashPositionProvider);
    _ref.invalidate(monthlyIncomeProvider);
    _ref.invalidate(monthlyExpensesProvider);
  }

  Future<void> signOut() async {
    try {
      _ref.read(analyticsServiceProvider).logEvent('user_logout');
      await _ref.read(googleAuthServiceProvider).signOut();
    } catch (_) {
      await _storage.clearAll();
    }
  }
}

final accountOperationsProvider = Provider((ref) {
  return AccountOperations(
    ref.watch(appDatabaseProvider),
    ref.watch(secureStorageProvider),
    ref,
  );
});
