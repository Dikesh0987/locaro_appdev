import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/common/scale_button.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    // Show failure messages if login failed
    if (authState is AuthFailure) {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mobilePadding,
            vertical: AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              // Visual Brand element
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.compass,
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Welcome Headlines
              Text(
                'Discover your\nneighborhood',
                style: AppTypography.display.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Connect with local merchants, explore nearby fresh arrivals, and get custom discount updates in your block instantly.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Login Actions
              PrimaryButton(
                text: 'Continue with Google',
                isLoading: isLoading,
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signInWithGoogle();
                },
              ),
              const SizedBox(height: AppSpacing.s16),
              Center(
                child: ScaleButtonPressed(
                  onTap: isLoading
                      ? () {}
                      : () {
                          ref.read(authControllerProvider.notifier).signInAsGuest();
                        },
                  child: TextButton(
                    onPressed: null, // Let ScaleButtonPressed handle the tap
                    child: Text(
                      'Continue as Guest',
                      style: AppTypography.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
          ),
        ),
      ),
    );
  }
}
