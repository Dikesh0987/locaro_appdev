import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../shell/presentation/shell_screen.dart';
import 'role_selection_screen.dart';
import 'splash_screen.dart';

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUserVal = ref.watch(authUserProvider);

    return authUserVal.when(
      data: (user) {
        if (user != null && user.isOnboardingCompleted) {
          return const ShellScreen();
        }

        // Return RoleSelectionScreen if logged out or onboarding is incomplete
        return const RoleSelectionScreen();
      },
      loading: () => const SplashScreen(),
      error: (err, stack) => const RoleSelectionScreen(),
    );
  }
}
