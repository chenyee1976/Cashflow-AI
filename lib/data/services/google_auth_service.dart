import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../secure_storage/secure_storage_service.dart';

import 'analytics_service.dart';

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService(
    db: ref.watch(appDatabaseProvider),
    storage: ref.watch(secureStorageProvider),
    analytics: ref.watch(analyticsServiceProvider),
  );
});

class GoogleAuthResult {
  final String userId;
  final bool isNewUser;
  final String displayName;
  final String email;

  const GoogleAuthResult({
    required this.userId,
    required this.isNewUser,
    required this.displayName,
    required this.email,
  });
}

class GoogleAuthException implements Exception {
  final String message;
  const GoogleAuthException(this.message);
  @override
  String toString() => message;
}

class GoogleAuthService {
  final AppDatabase _db;
  final SecureStorageService _storage;
  final AnalyticsService _analytics;

  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  GoogleAuthService({
    required AppDatabase db,
    required SecureStorageService storage,
    required AnalyticsService analytics,
  })  : _db = db,
        _storage = storage,
        _analytics = analytics;

  /// Sign in with Google. Returns auth result with userId and isNewUser flag.
  Future<GoogleAuthResult> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled sign-in
        if (kDebugMode) {
          return _mockSignIn();
        }
        throw const GoogleAuthException('Sign-in was cancelled by user.');
      }
      return _processAccount(account);
    } catch (e) {
      if (e is GoogleAuthException) rethrow;
      if (kDebugMode) {
        debugPrint('Google Sign-In fallback in debug mode: $e');
        return _mockSignIn();
      }
      throw GoogleAuthException('Google Sign-In failed: ${e.toString()}');
    }
  }

  Future<GoogleAuthResult> _mockSignIn() async {
    String? existingUserId = await _storage.getUserId();
    String? existingEmail = await _storage.getGoogleEmail();

    final userId = (existingUserId != null && existingUserId.isNotEmpty)
        ? existingUserId
        : 'tester_${const Uuid().v4().substring(0, 8)}';

    final email = (existingEmail != null && existingEmail.isNotEmpty)
        ? existingEmail
        : 'tester_${userId.substring(userId.length > 8 ? userId.length - 8 : 0)}@beta.cashflow.ai';

    final user = await _db.getUserById(userId);
    final statements = await _db.getStatementsByUser(userId);
    final bankAccounts = await _db.getBankAccountsByUser(userId);
    final creditCards = await _db.getCreditCardsByUser(userId);
    final onboardingComplete = await _storage.isOnboardingComplete();
    
    final isExistingAccount = user != null || statements.isNotEmpty || bankAccounts.isNotEmpty || creditCards.isNotEmpty || onboardingComplete;
    final isNewUser = !isExistingAccount;

    if (user == null) {
      final companion = UsersCompanion.insert(
        id: userId,
        firstName: 'Beta',
        lastName: 'Tester',
        email: email,
        googleId: 'google_$userId',
        displayName: Value('Beta Tester ($email)'),
        photoUrl: const Value(''),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        lastLoginAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        sessionExpires: Value(
          DateTime.now()
                  .add(const Duration(days: 30))
                  .millisecondsSinceEpoch ~/
              1000,
        ),
      );
      await _db.upsertUser(companion);
    }
    await _storage.saveGoogleUser(
      userId: userId,
      googleId: 'google_$userId',
      email: email,
    );
    await _storage.saveSessionExpiry(
      DateTime.now().add(const Duration(days: 30)),
    );

    if (isExistingAccount) {
      await _storage.setOnboardingComplete();
    }

    _analytics.setUser(userId, email);

    return GoogleAuthResult(
      userId: userId,
      isNewUser: isNewUser,
      displayName: user?.displayName ?? 'Beta Tester ($email)',
      email: email,
    );
  }

  /// Silent sign-in for session restoration
  Future<GoogleAuthResult?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return null;
      return _processAccount(account);
    } catch (_) {
      return null;
    }
  }

  Future<GoogleAuthResult> _processAccount(GoogleSignInAccount account) async {
    // Check if user already exists in DB and onboarding is complete
    final existing = await _db.getUserByGoogleId(account.id);
    final onboardingComplete = await _storage.isOnboardingComplete();
    
    final userId = existing?.id ?? const Uuid().v4();
    final statements = await _db.getStatementsByUser(userId);
    final bankAccounts = await _db.getBankAccountsByUser(userId);
    final creditCards = await _db.getCreditCardsByUser(userId);
    final isExistingAccount = existing != null || statements.isNotEmpty || bankAccounts.isNotEmpty || creditCards.isNotEmpty || onboardingComplete;
    final isNewUser = !isExistingAccount;

    final companion = UsersCompanion.insert(
      id: userId,
      firstName: _extractFirstName(account.displayName ?? ''),
      lastName: _extractLastName(account.displayName ?? ''),
      email: account.email,
      googleId: account.id,
      displayName: Value(account.displayName),
      photoUrl: Value(account.photoUrl),
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      lastLoginAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      sessionExpires: Value(
        DateTime.now()
                .add(const Duration(days: 30))
                .millisecondsSinceEpoch ~/
            1000,
      ),
    );

    await _db.upsertUser(companion);

    // Persist session info
    await _storage.saveGoogleUser(
      userId: userId,
      googleId: account.id,
      email: account.email,
    );
    await _storage.saveSessionExpiry(
      DateTime.now().add(const Duration(days: 30)),
    );

    if (isExistingAccount) {
      await _storage.setOnboardingComplete();
    }

    _analytics.setUser(userId, account.email);

    return GoogleAuthResult(
      userId: userId,
      isNewUser: isNewUser,
      displayName: account.displayName ?? account.email,
      email: account.email,
    );
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.clearAll();
  }

  String _extractFirstName(String displayName) {
    if (displayName.isEmpty) return 'User';
    final parts = displayName.trim().split(' ');
    return parts.first;
  }

  String _extractLastName(String displayName) {
    if (displayName.isEmpty) return '';
    final parts = displayName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }
}
