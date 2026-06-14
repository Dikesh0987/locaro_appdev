import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/common/scale_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../providers/app_state_providers.dart';
import '../../auth/application/auth_service.dart';
import '../../../core/services/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification States
  bool _pushNotifications = true;
  bool _offerNotifications = true;
  bool _nearbyDealsNotifications = true;
  bool _marketingNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final user = ref.read(databaseProvider).currentUser;
        setState(() {
          _pushNotifications = user.notificationEnabled;
          _offerNotifications = user.notificationSettings['offers'] ?? true;
          _nearbyDealsNotifications =
              user.notificationSettings['nearbyDeals'] ?? true;
          _marketingNotifications =
              user.notificationSettings['marketing'] ?? false;
          _selectedLanguage = user.language;
        });
        // Also refresh email status
        ref.read(authServiceProvider).refreshUserEmailVerificationStatus().then(
          (_) {
            if (mounted) setState(() {});
          },
        );
      }
    });
  }

  Future<void> _sendVerificationEmail() async {
    final user = ref.read(databaseProvider).currentUser;
    if (user.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email address found to verify.')),
      );
      return;
    }
    try {
      await ref.read(authServiceProvider).sendEmailVerification(user.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification link sent. Please check your inbox.'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _updateNotifications({
    bool? push,
    bool? offers,
    bool? nearby,
    bool? marketing,
  }) async {
    final user = ref.read(databaseProvider).currentUser;
    final newPush = push ?? _pushNotifications;
    final newOffers = offers ?? _offerNotifications;
    final newNearby = nearby ?? _nearbyDealsNotifications;
    final newMarketing = marketing ?? _marketingNotifications;

    setState(() {
      _pushNotifications = newPush;
      _offerNotifications = newOffers;
      _nearbyDealsNotifications = newNearby;
      _marketingNotifications = newMarketing;
    });

    if (!user.isGuest) {
      final newSettings = Map<String, bool>.from(user.notificationSettings);
      newSettings['offers'] = newOffers;
      newSettings['nearbyDeals'] = newNearby;
      newSettings['marketing'] = newMarketing;

      await ref
          .read(authServiceProvider)
          .updateNotificationSettings(newPush, newSettings);

      await fcmService.updateTopicSubscriptions(
        pushEnabled: newPush,
        offersEnabled: newOffers,
        nearbyDealsEnabled: newNearby,
        marketingEnabled: newMarketing,
      );
    }
  }

  // Privacy States
  bool _isPrivateAccount = false;

  // Language State
  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English',
    'Hindi (हिन्दी)',
    'Spanish (Español)',
    'French (Français)',
  ];

  // Permission States
  bool _locationPermission = true;
  bool _cameraPermission = false;
  bool _notificationPermission = true;

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Select Language', style: AppTypography.heading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((lang) {
              return RadioListTile<String>(
                title: Text(lang, style: AppTypography.body),
                value: lang,
                groupValue: _selectedLanguage,
                activeColor: context.colors.primary,
                onChanged: (val) async {
                  if (val != null) {
                    setState(() => _selectedLanguage = val);
                    Navigator.pop(dialogContext);

                    final user = ref.read(databaseProvider).currentUser;
                    if (!user.isGuest) {
                      final updatedUser = user.copyWith(language: val);
                      await ref
                          .read(databaseProvider.notifier)
                          .updateCurrentUser(updatedUser);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Language changed to $val'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Account?',
            style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'This action is permanent and cannot be undone. All your profile details, settings, and local history will be wiped out.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(
                  color: context.colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                try {
                  await ref.read(authServiceProvider).handleDeleteAccount();
                  if (mounted) {
                    Navigator.pop(context); // Close settings screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Account successfully deleted.'),
                        backgroundColor: context.colors.error,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete account: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showUpdatePhoneSheet() {
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
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(AppSpacing.mobilePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isOtpSent ? 'Enter OTP' : 'Update Phone Number',
                      style: AppTypography.heading,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOtpSent
                          ? 'We sent a verification code to your new number.'
                          : 'Enter your new phone number to receive an OTP.',
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!isOtpSent) ...[
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'New Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Send OTP',
                        isLoading: isLoading,
                        onPressed: () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a phone number'),
                              ),
                            );
                            return;
                          }
                          String formattedPhone = phone.startsWith('+')
                              ? phone
                              : '+91$phone';

                          setState(() => isLoading = true);

                          try {
                            await fb.FirebaseAuth.instance.verifyPhoneNumber(
                              phoneNumber: formattedPhone,
                              verificationCompleted:
                                  (fb.PhoneAuthCredential credential) async {
                                    try {
                                      await ref
                                          .read(authServiceProvider)
                                          .updatePhoneNumber(formattedPhone);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Phone number updated successfully!',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        setState(() => isLoading = false);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                              verificationFailed: (fb.FirebaseAuthException e) {
                                setState(() => isLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Verification Failed: ${e.message}',
                                    ),
                                  ),
                                );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                      ),
                    ] else ...[
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '6-digit OTP',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Verify & Update',
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

                            final currentUser =
                                fb.FirebaseAuth.instance.currentUser;
                            if (currentUser != null) {
                              try {
                                await currentUser.linkWithCredential(
                                  credential,
                                );
                              } on fb.FirebaseAuthException catch (e) {
                                if (e.code == 'provider-already-linked' ||
                                    e.code == 'credential-already-in-use') {
                                  // Already linked, proceed.
                                } else {
                                  rethrow;
                                }
                              }
                            }

                            String formattedPhone = phoneController.text.trim();
                            if (!formattedPhone.startsWith('+')) {
                              formattedPhone = '+91$formattedPhone';
                            }

                            await ref
                                .read(authServiceProvider)
                                .updatePhoneNumber(formattedPhone);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Phone number updated successfully!',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invalid OTP or error: $e'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeMode = ref.watch(appThemeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.mobilePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- THEME SELECTOR ---
            Text(
              'Appearance',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.palette,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Theme Mode',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        activeThemeMode == ThemeMode.system
                            ? 'System'
                            : activeThemeMode == ThemeMode.dark
                            ? 'Dark'
                            : 'Light',
                        style: AppTypography.caption.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildThemeOptionButton(
                          label: 'Light',
                          isSelected: activeThemeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(authServiceProvider)
                              .updateThemeMode('light'),
                          icon: LucideIcons.sun,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOptionButton(
                          label: 'Dark',
                          isSelected: activeThemeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(authServiceProvider)
                              .updateThemeMode('dark'),
                          icon: LucideIcons.moon,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOptionButton(
                          label: 'System',
                          isSelected: activeThemeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(authServiceProvider)
                              .updateThemeMode('system'),
                          icon: LucideIcons.laptop,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // --- NOTIFICATIONS ---
            Text(
              'Notifications',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    label: 'Push Notifications',
                    icon: LucideIcons.bell,
                    val: _pushNotifications,
                    onChanged: (v) => _updateNotifications(push: v),
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSwitchTile(
                    label: 'Offer Alerts',
                    icon: LucideIcons.tag,
                    val: _offerNotifications,
                    onChanged: (v) => _updateNotifications(offers: v),
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSwitchTile(
                    label: 'Nearby Deals',
                    icon: LucideIcons.navigation,
                    val: _nearbyDealsNotifications,
                    onChanged: (v) => _updateNotifications(nearby: v),
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSwitchTile(
                    label: 'Marketing & Promos',
                    icon: LucideIcons.megaphone,
                    val: _marketingNotifications,
                    onChanged: (v) => _updateNotifications(marketing: v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // --- PREFERENCES ---
            Text(
              'Preferences',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  _buildClickTile(
                    label: 'App Language',
                    subtitle: _selectedLanguage,
                    icon: LucideIcons.languages,
                    onTap: _showLanguageSelector,
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSwitchTile(
                    label: 'Private Profile',
                    icon: LucideIcons.eyeOff,
                    val: _isPrivateAccount,
                    onChanged: (v) => setState(() => _isPrivateAccount = v),
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildClickTile(
                    label: 'Update Phone Number',
                    subtitle: 'Change your registered phone number',
                    icon: LucideIcons.phone,
                    onTap: _showUpdatePhoneSheet,
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildClickTile(
                    label: 'Email Verification',
                    subtitle:
                        fb.FirebaseAuth.instance.currentUser?.emailVerified ==
                            true
                        ? 'Verified'
                        : 'Unverified (Tap to verify)',
                    icon: LucideIcons.mail,
                    onTap:
                        fb.FirebaseAuth.instance.currentUser?.emailVerified ==
                            true
                        ? () {}
                        : _sendVerificationEmail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // --- PERMISSIONS ---
            Text(
              'App Permissions',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    label: 'Location Access',
                    icon: LucideIcons.mapPin,
                    val: _locationPermission,
                    onChanged: (v) => setState(() => _locationPermission = v),
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSwitchTile(
                    label: 'Camera Access',
                    icon: LucideIcons.camera,
                    val: _cameraPermission,
                    onChanged: (v) => setState(() => _cameraPermission = v),
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSwitchTile(
                    label: 'Notifications Access',
                    icon: LucideIcons.bellRing,
                    val: _notificationPermission,
                    onChanged: (v) =>
                        setState(() => _notificationPermission = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap * 2),

            // --- DELETE ACCOUNT ---
            ScaleButtonPressed(
              onTap: _showDeleteAccountDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: context.colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: context.colors.error.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(
                      color: context.colors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final activeTextColor = isSelected
        ? context.colors.surface
        : Theme.of(context).textTheme.bodyLarge?.color;

    return ScaleButtonPressed(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary
              : Theme.of(context).dividerColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: activeTextColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: activeTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String label,
    required IconData icon,
    required bool val,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).iconTheme.color),
        title: Text(
          label,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: Switch.adaptive(
          value: val,
          onChanged: onChanged,
          activeTrackColor: context.colors.primary,
        ),
      ),
    );
  }

  Widget _buildClickTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).iconTheme.color),
        title: Text(
          label,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.caption.copyWith(
            color: context.colors.textSecondary,
            fontSize: 11,
          ),
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 16),
        onTap: onTap,
      ),
    );
  }
}
