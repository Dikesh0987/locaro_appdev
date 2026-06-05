import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/auth_repository.dart';
import '../models/user_model.dart';
import 'app_state_providers.dart';

class AuthUserNotifier extends AsyncNotifier<UserModel?> {
  @override
  FutureOr<UserModel?> build() async {
    final authState = ref.watch(authStateChangesProvider);
    final fbUser = authState.value;

    if (fbUser == null) {
      // Clear app state on logout
      _clearAppState();
      return null;
    }

    try {
      final repository = ref.read(authRepositoryProvider);
      final doc = await repository.getUserDoc(fbUser.uid);

      if (!doc.exists) {
        // Document does not exist yet (new user in middle of Google sign-in)
        return null;
      }

      final user = UserModel.fromMap(doc.data()!);

      // Sync user inside our global DB state
      ref.read(databaseProvider.notifier).setCurrentUser(user);

      // Set user theme mode
      _setThemeFromStr(user.themeMode);

      // Set app role if onboarding is already completed
      if (user.isOnboardingCompleted) {
        ref.read(appRoleProvider.notifier).state = user.role;
      } else {
        ref.read(appRoleProvider.notifier).state = null;
      }

      return user;
    } catch (e) {
      // Keep state null or handle error accordingly
      return null;
    }
  }

  void _clearAppState() {
    // We delay slightly to avoid modifying state during widget tree build if called synchronously
    Future.microtask(() {
      ref.read(appRoleProvider.notifier).state = null;
      ref.read(bottomNavIndexProvider.notifier).state = 0;
    });
  }

  void _setThemeFromStr(String themeModeStr) {
    ThemeMode mode;
    switch (themeModeStr) {
      case 'light':
        mode = ThemeMode.light;
        break;
      case 'dark':
        mode = ThemeMode.dark;
        break;
      case 'system':
      default:
        mode = ThemeMode.system;
        break;
    }
    Future.microtask(() {
      ref.read(appThemeModeProvider.notifier).setThemeMode(mode);
    });
  }

  /// Force a refresh of the authenticated user state (e.g. after onboarding completion)
  void refresh() {
    ref.invalidateSelf();
  }
}

final authUserProvider = AsyncNotifierProvider<AuthUserNotifier, UserModel?>(() {
  return AuthUserNotifier();
});
