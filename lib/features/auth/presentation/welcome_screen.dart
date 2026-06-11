import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/common/scale_button.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'auth_controller.dart';
import 'auth_state.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  void _showPhoneLoginSheet(BuildContext context, WidgetRef ref) {
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    bool isOtpSent = false;
    bool isLoading = false;
    String? verificationId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(AppSpacing.mobilePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(isOtpSent ? 'Enter OTP' : 'Continue with Phone', style: AppTypography.heading),
                    const SizedBox(height: 8),
                    Text(
                      isOtpSent ? 'We sent a verification code to your number.' : 'You will receive a 6-digit code to verify your number.',
                      style: AppTypography.caption.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 24),

                    if (!isOtpSent) ...[
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Phone Number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Send OTP',
                        isLoading: isLoading,
                        onPressed: () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter phone number')));
                            return;
                          }
                          String formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
                          
                          setState(() => isLoading = true);
                          
                          try {
                            await fb.FirebaseAuth.instance.verifyPhoneNumber(
                              phoneNumber: formattedPhone,
                              verificationCompleted: (fb.PhoneAuthCredential credential) async {
                                try {
                                  await ref.read(authControllerProvider.notifier).signInWithPhone(credential, 'user');
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (context.mounted) {
                                    setState(() => isLoading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              },
                              verificationFailed: (fb.FirebaseAuthException e) {
                                setState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Failed: ${e.message}')));
                              },
                              codeSent: (String verId, int? resendToken) {
                                setState(() {
                                  verificationId = verId;
                                  isOtpSent = true;
                                  isLoading = false;
                                });
                              },
                              codeAutoRetrievalTimeout: (String verId) {
                                verificationId = verId;
                              },
                            );
                          } catch (e) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                      ),
                    ] else ...[
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '6-digit OTP',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Verify & Login',
                        isLoading: isLoading,
                        onPressed: () async {
                          final code = otpController.text.trim();
                          if (code.isEmpty || verificationId == null) return;
                          
                          setState(() => isLoading = true);
                          
                          try {
                            final credential = fb.PhoneAuthProvider.credential(
                              verificationId: verificationId!,
                              smsCode: code,
                            );
                            await ref.read(authControllerProvider.notifier).signInWithPhone(credential, 'user');
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP or error: $e')));
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    // Show failure messages if login failed
    if (authState is AuthFailure) {
      Future.microtask(() {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: context.colors.error,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: context.colors.background,
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
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: context.colors.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.compass,
                      size: 44,
                      color: context.colors.primary,
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
                  color: context.colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Login Actions
              PrimaryButton(
                text: 'Continue with Google',
                isLoading: isLoading,
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signInWithGoogle('user');
                },
              ),
              const SizedBox(height: AppSpacing.s12),
              SecondaryButton(
                text: 'Continue with Phone Number',
                onPressed: isLoading ? () {} : () => _showPhoneLoginSheet(context, ref),
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
                        color: context.colors.primary,
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
