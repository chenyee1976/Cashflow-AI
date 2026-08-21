import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/google_auth_service.dart';
import '../../../data/services/analytics_service.dart';

enum LoginStatus { idle, loading, success, error }

class LoginState {
  final LoginStatus status;
  final String? errorMessage;
  final String? displayName;

  const LoginState({
    this.status = LoginStatus.idle,
    this.errorMessage,
    this.displayName,
  });

  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
    String? displayName,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      displayName: displayName ?? this.displayName,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final GoogleAuthService _authService;

  LoginNotifier(this._authService) : super(const LoginState());

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(status: LoginStatus.loading);
    try {
      final result = await _authService.signIn();
      state = state.copyWith(
        status: LoginStatus.success,
        displayName: result.displayName,
      );
      return result.isNewUser;
    } catch (e) {
      AnalyticsService().logEvent('user_login_failed', parameters: {
        'error': e.toString(),
      });
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const LoginState();
  }
}

final loginProvider = StateNotifierProvider.autoDispose<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(ref.watch(googleAuthServiceProvider));
});
