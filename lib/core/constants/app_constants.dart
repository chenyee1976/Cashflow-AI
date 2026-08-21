class AppConstants {
  AppConstants._();

  // Session
  static const int sessionDurationDays = 30;
  static const int inactivityTimeoutMinutes = 5;

  // File upload
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  // Storage paths
  static const String statementsIncomingFolder = 'statements/incoming';
  static const String statementsProcessedFolder = 'statements/processed';

  // AI
  static const double aiConfidenceThreshold = 0.7;

  // Rewards
  static const int milesExpiryWarningDays = 90;
  static const int milesExpiryUrgentDays = 30;
  static const int milesExpiryCriticalDays = 7;

  // History limit (Lite)
  static const int liteHistoryLimitMonths = 12;

  // Backend URLs (Vercel)
  static const String baseApiUrl = 'https://cashflow-ai-api.vercel.app';
  static const String aiServiceUrl = 'https://cashflow-ai-python.vercel.app';

  // Secure storage keys
  static const String keyGoogleUserId = 'google_user_id';
  static const String keyGoogleEmail = 'google_email';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyUserId = 'user_id';
  static const String keySessionExpiry = 'session_expiry';
  static const String keyLastActivity = 'last_activity';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyRewardFocus = 'reward_focus';
  static const String keyGeminiApiKey = 'gemini_api_key';

  // Feature Flags
  static const bool showProFeatures = false;
}
