import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_service.dart';
import 'auth_state.dart';

class AuthController extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    return const AuthInitial();
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      await _authService.handleGoogleSignIn();
      state = const AuthSuccess();
    } catch (e) {
      state = AuthFailure(e.toString());
    }
  }

  Future<void> signInAsGuest() async {
    state = const AuthLoading();
    try {
      await _authService.handleGuestSignIn();
      state = const AuthSuccess();
    } catch (e) {
      state = AuthFailure(e.toString());
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});
