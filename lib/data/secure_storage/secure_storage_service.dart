import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  // ── Google Auth ─────────────────────────────────────────
  Future<void> saveGoogleUser({
    required String userId,
    required String googleId,
    required String email,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.keyUserId, value: userId),
      _storage.write(key: AppConstants.keyGoogleUserId, value: googleId),
      _storage.write(key: AppConstants.keyGoogleEmail, value: email),
    ]);
  }

  Future<String?> getUserId() =>
      _storage.read(key: AppConstants.keyUserId);

  Future<String?> getGoogleId() =>
      _storage.read(key: AppConstants.keyGoogleUserId);

  Future<String?> getGoogleEmail() =>
      _storage.read(key: AppConstants.keyGoogleEmail);

  // ── Session ─────────────────────────────────────────────
  Future<void> saveSessionExpiry(DateTime expiry) =>
      _storage.write(
        key: AppConstants.keySessionExpiry,
        value: expiry.millisecondsSinceEpoch.toString(),
      );

  Future<bool> isSessionValid() async {
    final value = await _storage.read(key: AppConstants.keySessionExpiry);
    if (value == null) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(value));
    return DateTime.now().isBefore(expiry);
  }

  // ── Onboarding ──────────────────────────────────────────
  Future<void> setOnboardingComplete() =>
      _storage.write(key: AppConstants.keyOnboardingComplete, value: 'true');

  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: AppConstants.keyOnboardingComplete);
    return value == 'true';
  }

  Future<void> saveRewardFocus(String focus) =>
      _storage.write(key: AppConstants.keyRewardFocus, value: focus);

  Future<String?> getRewardFocus() =>
      _storage.read(key: AppConstants.keyRewardFocus);

  static final String defaultGeminiApiKey = 'PROXY_VIA_VERCEL';

  Future<void> saveGeminiApiKey(String key) =>
      _storage.write(key: AppConstants.keyGeminiApiKey, value: key);

  Future<String?> getGeminiApiKey() async {
    final value = await _storage.read(key: AppConstants.keyGeminiApiKey);
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
    return defaultGeminiApiKey;
  }

  Future<void> saveMobileNumber(String mobile) =>
      _storage.write(key: 'mobile_number', value: mobile);

  Future<String?> getMobileNumber() =>
      _storage.read(key: 'mobile_number');

  Future<void> saveFxRate(String currency, String rate) =>
      _storage.write(key: 'fx_rate_${currency.toUpperCase().trim()}', value: rate);

  Future<String?> getFxRate(String currency) =>
      _storage.read(key: 'fx_rate_${currency.toUpperCase().trim()}');

  // ── Billing Credit Card Info ───────────────────────────
  Future<void> saveBillingCard({
    required String name,
    required String num,
    required String expiry,
    required String cvv,
    required String zip,
    required String lastPay,
    required String nextPay,
  }) async {
    await Future.wait([
      _storage.write(key: 'billing_card_name', value: name),
      _storage.write(key: 'billing_card_num', value: num),
      _storage.write(key: 'billing_card_expiry', value: expiry),
      _storage.write(key: 'billing_card_cvv', value: cvv),
      _storage.write(key: 'billing_card_zip', value: zip),
      _storage.write(key: 'billing_last_pay', value: lastPay),
      _storage.write(key: 'billing_next_pay', value: nextPay),
    ]);
  }

  Future<Map<String, String>> getBillingCard() async {
    final values = await Future.wait([
      _storage.read(key: 'billing_card_name'),
      _storage.read(key: 'billing_card_num'),
      _storage.read(key: 'billing_card_expiry'),
      _storage.read(key: 'billing_card_cvv'),
      _storage.read(key: 'billing_card_zip'),
      _storage.read(key: 'billing_last_pay'),
      _storage.read(key: 'billing_next_pay'),
    ]);
    return {
      'name': values[0] ?? '',
      'num': values[1] ?? '',
      'expiry': values[2] ?? '',
      'cvv': values[3] ?? '',
      'zip': values[4] ?? '',
      'lastPay': values[5] ?? '',
      'nextPay': values[6] ?? '',
    };
  }

  // ── Biometrics ──────────────────────────────────────────
  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(
        key: AppConstants.keyBiometricEnabled,
        value: enabled.toString(),
      );

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: AppConstants.keyBiometricEnabled);
    return value == 'true';
  }

  // ── Inactivity ──────────────────────────────────────────
  Future<void> updateLastActivity() =>
      _storage.write(
        key: AppConstants.keyLastActivity,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );

  Future<bool> isInactivityTimeoutReached() async {
    final value = await _storage.read(key: AppConstants.keyLastActivity);
    if (value == null) return false;
    final last = DateTime.fromMillisecondsSinceEpoch(int.parse(value));
    return DateTime.now().difference(last).inMinutes >=
        AppConstants.inactivityTimeoutMinutes;
  }

  // ── Cash on Hand (Per-Month Support) ───────────────────
  Future<void> saveCashOnHandBaseForMonth({required int year, required int month, required double amount}) =>
      _storage.write(key: 'key_cash_on_hand_base_${year}_$month', value: amount.toString());

  Future<double?> getCashOnHandBaseForMonth({required int year, required int month}) async {
    final val = await _storage.read(key: 'key_cash_on_hand_base_${year}_$month');
    if (val != null) return double.tryParse(val);
    // Fallback to legacy global setting if month specific is unset
    final fallback = await _storage.read(key: 'key_cash_on_hand_base');
    return fallback != null ? double.tryParse(fallback) : null;
  }

  // ── Clear all (logout) ──────────────────────────────────
  Future<void> clearAll() async {
    await _storage.delete(key: AppConstants.keyUserId);
    await _storage.delete(key: AppConstants.keyGoogleUserId);
    await _storage.delete(key: AppConstants.keySessionExpiry);
  }
}
