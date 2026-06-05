import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../shell/presentation/shell_screen.dart';
import 'auth_flow_container.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUserVal = ref.watch(authUserProvider);

    return authUserVal.when(
      data: (user) {
        if (user == null) {
          return const WelcomeScreen();
        }

        if (!user.isOnboardingCompleted) {
          // New authenticated user needing onboarding
          return const AuthFlowContainer(role: 'user');
        }

        // Fully authenticated user
        return const ShellScreen();
      },
      loading: () => const SplashScreen(),
      error: (err, stack) => const WelcomeScreen(),
    );
  }
}
