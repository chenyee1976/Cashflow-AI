import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<String?> _safeRead(String key) async {
    try {
      final val = await _storage.read(key: key);
      if (val != null) return val;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('sec_$key');
    } catch (_) {
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sec_$key', value);
    } catch (_) {}
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sec_$key');
    } catch (_) {}
  }

  // ── Google Auth ─────────────────────────────────────────
  Future<void> saveGoogleUser({
    required String userId,
    required String googleId,
    required String email,
  }) async {
    await Future.wait([
      _safeWrite(AppConstants.keyUserId, userId),
      _safeWrite(AppConstants.keyGoogleUserId, googleId),
      _safeWrite(AppConstants.keyGoogleEmail, email),
    ]);
  }

  Future<String?> getUserId() => _safeRead(AppConstants.keyUserId);

  Future<String?> getGoogleId() => _safeRead(AppConstants.keyGoogleUserId);

  Future<String?> getGoogleEmail() => _safeRead(AppConstants.keyGoogleEmail);

  // ── Session ─────────────────────────────────────────────
  Future<void> saveSessionExpiry(DateTime expiry) => _safeWrite(
        AppConstants.keySessionExpiry,
        expiry.millisecondsSinceEpoch.toString(),
      );

  Future<bool> isSessionValid() async {
    final value = await _safeRead(AppConstants.keySessionExpiry);
    if (value == null) return false;
    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(value));
    return DateTime.now().isBefore(expiry);
  }

  // ── Onboarding ──────────────────────────────────────────
  Future<void> setOnboardingComplete() =>
      _safeWrite(AppConstants.keyOnboardingComplete, 'true');

  Future<bool> isOnboardingComplete() async {
    final value = await _safeRead(AppConstants.keyOnboardingComplete);
    return value == 'true';
  }

  Future<void> saveRewardFocus(String focus) =>
      _safeWrite(AppConstants.keyRewardFocus, focus);

  Future<String?> getRewardFocus() =>
      _safeRead(AppConstants.keyRewardFocus);

  static final String defaultGeminiApiKey = 'PROXY_VIA_VERCEL';

  Future<void> saveGeminiApiKey(String key) =>
      _safeWrite(AppConstants.keyGeminiApiKey, key);

  Future<String?> getGeminiApiKey() async {
    final value = await _safeRead(AppConstants.keyGeminiApiKey);
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
    return defaultGeminiApiKey;
  }

  Future<void> saveMobileNumber(String mobile) =>
      _safeWrite('mobile_number', mobile);

  Future<String?> getMobileNumber() =>
      _safeRead('mobile_number');

  Future<void> saveFxRate(String currency, String rate) =>
      _safeWrite('fx_rate_${currency.toUpperCase().trim()}', rate);

  Future<String?> getFxRate(String currency) =>
      _safeRead('fx_rate_${currency.toUpperCase().trim()}');

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
      _safeWrite('billing_card_name', name),
      _safeWrite('billing_card_num', num),
      _safeWrite('billing_card_expiry', expiry),
      _safeWrite('billing_card_cvv', cvv),
      _safeWrite('billing_card_zip', zip),
      _safeWrite('billing_last_pay', lastPay),
      _safeWrite('billing_next_pay', nextPay),
    ]);
  }

  Future<Map<String, String>> getBillingCard() async {
    final values = await Future.wait([
      _safeRead('billing_card_name'),
      _safeRead('billing_card_num'),
      _safeRead('billing_card_expiry'),
      _safeRead('billing_card_cvv'),
      _safeRead('billing_card_zip'),
      _safeRead('billing_last_pay'),
      _safeRead('billing_next_pay'),
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
  Future<void> setBiometricEnabled(bool enabled) => _safeWrite(
        AppConstants.keyBiometricEnabled,
        enabled.toString(),
      );

  Future<bool> isBiometricEnabled() async {
    final value = await _safeRead(AppConstants.keyBiometricEnabled);
    return value == 'true';
  }

  // ── Inactivity ──────────────────────────────────────────
  Future<void> updateLastActivity() => _safeWrite(
        AppConstants.keyLastActivity,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

  Future<bool> isInactivityTimeoutReached() async {
    final value = await _safeRead(AppConstants.keyLastActivity);
    if (value == null) return false;
    final last = DateTime.fromMillisecondsSinceEpoch(int.parse(value));
    return DateTime.now().difference(last).inMinutes >=
        AppConstants.inactivityTimeoutMinutes;
  }

  // ── Cash on Hand (Per-Month Support) ───────────────────
  Future<void> saveCashOnHandBaseForMonth({required int year, required int month, required double amount}) =>
      _safeWrite('key_cash_on_hand_base_${year}_$month', amount.toString());

  Future<double?> getCashOnHandBaseForMonth({required int year, required int month}) async {
    final val = await _safeRead('key_cash_on_hand_base_${year}_$month');
    if (val != null) return double.tryParse(val);
    // Fallback to legacy global setting if month specific is unset
    final fallback = await _safeRead('key_cash_on_hand_base');
    return fallback != null ? double.tryParse(fallback) : null;
  }

  // ── Clear all (logout) ──────────────────────────────────
  Future<void> clearAll() async {
    await _safeDelete(AppConstants.keyUserId);
    await _safeDelete(AppConstants.keyGoogleUserId);
    await _safeDelete(AppConstants.keySessionExpiry);
  }
}
