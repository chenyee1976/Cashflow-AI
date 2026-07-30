import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/app_database.dart';
import '../../data/secure_storage/secure_storage_service.dart';
import 'package:drift/drift.dart';
import '../account/account_provider.dart';

class OnboardingState {
  final int currentStep; // 1 to 3
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final String currencyPref;
  final double monthlySavingsGoal;
  
  final bool termsAccepted;
  final bool privacyAccepted;
  final bool dataConsentAccepted;

  final String rewardFocus; // 'miles' | 'cashback' | 'both'
  final bool isLoading;

  const OnboardingState({
    this.currentStep = 1,
    this.firstName = '',
    this.lastName = '',
    this.mobileNumber = '',
    this.currencyPref = 'SGD',
    this.monthlySavingsGoal = 0.0,
    this.termsAccepted = false,
    this.privacyAccepted = false,
    this.dataConsentAccepted = false,
    this.rewardFocus = 'both',
    this.isLoading = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? firstName,
    String? lastName,
    String? mobileNumber,
    String? currencyPref,
    double? monthlySavingsGoal,
    bool? termsAccepted,
    bool? privacyAccepted,
    bool? dataConsentAccepted,
    String? rewardFocus,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      currencyPref: currencyPref ?? this.currencyPref,
      monthlySavingsGoal: monthlySavingsGoal ?? this.monthlySavingsGoal,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
      dataConsentAccepted: dataConsentAccepted ?? this.dataConsentAccepted,
      rewardFocus: rewardFocus ?? this.rewardFocus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final AppDatabase _db;
  final SecureStorageService _storage;
  final Ref _ref;

  OnboardingNotifier(this._db, this._storage, this._ref) : super(const OnboardingState());

  Future<void> setPersonalInfo({
    required String firstName,
    required String lastName,
    required String mobileNumber,
    required String currencyPref,
    required double monthlySavingsGoal,
  }) async {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      mobileNumber: mobileNumber,
      currencyPref: currencyPref,
      monthlySavingsGoal: monthlySavingsGoal,
    );

    var userId = await _storage.getUserId();
    if (userId == null || userId.isEmpty || userId == 'unknown_user') {
      userId = 'chenyee_user';
      await _storage.saveGoogleUser(userId: userId, googleId: 'google_mock_123', email: 'chenwallpaper@gmail.com');
    }

    final companion = UsersCompanion(
      id: Value(userId),
      firstName: Value(firstName),
      lastName: Value(lastName),
      email: const Value('chenwallpaper@gmail.com'),
      googleId: const Value('google_mock_123'),
      rewardFocus: const Value('Both'),
      currencyPref: Value(currencyPref),
      createdAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
    );
    int retries = 20;
    while (true) {
      try {
        await _db.upsertUser(companion);
        await _storage.saveMobileNumber(mobileNumber);
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
  }

  void setLegalConsents({
    required bool terms,
    required bool privacy,
    required bool dataConsent,
  }) {
    state = state.copyWith(
      termsAccepted: terms,
      privacyAccepted: privacy,
      dataConsentAccepted: dataConsent,
    );
  }

  void setRewardFocus(String focus) {
    state = state.copyWith(rewardFocus: focus);
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    try {
      var userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty || userId == 'unknown_user') {
        userId = 'chenyee_user';
        await _storage.saveGoogleUser(userId: userId, googleId: 'google_mock_123', email: 'chenwallpaper@gmail.com');
      }
      
      // Update or Insert User information in Drift SQLite using upsertUser
      final companion = UsersCompanion(
        id: Value(userId),
        firstName: Value(state.firstName),
        lastName: Value(state.lastName),
        email: const Value('beta.tester@example.com'),
        googleId: const Value('google_mock_123'),
        rewardFocus: Value(state.rewardFocus),
        currencyPref: Value(state.currencyPref),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      );
      await _db.upsertUser(companion);

      // Save onboarding profile details to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (state.firstName.isNotEmpty) await prefs.setString('tester_first_name', state.firstName);
      if (state.lastName.isNotEmpty) await prefs.setString('tester_last_name', state.lastName);
      if (state.mobileNumber.isNotEmpty) await prefs.setString('tester_mobile', state.mobileNumber);

      // Save onboarding preferences
      await _storage.saveMobileNumber(state.mobileNumber);
      await _storage.saveRewardFocus(state.rewardFocus);
      await _storage.setOnboardingComplete();
      
      _ref.invalidate(accountProfileProvider);
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final onboardingProvider = StateNotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(
    ref.watch(appDatabaseProvider),
    ref.watch(secureStorageProvider),
    ref,
  );
});
