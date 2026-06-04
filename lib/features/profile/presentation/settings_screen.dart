import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/common/scale_button.dart';
import '../../../providers/app_state_providers.dart';

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

  // Privacy States
  bool _isPrivateAccount = false;
  List<String> _blockedUsers = ['John Doe', 'Spam Bot 404', 'Irritating Merchant'];
  
  // Language State
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Hindi (हिन्दी)', 'Spanish (Español)', 'French (Français)'];

  // Permission States
  bool _locationPermission = true;
  bool _cameraPermission = false;
  bool _notificationPermission = true;

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Language', style: AppTypography.heading),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((lang) {
              return RadioListTile<String>(
                title: Text(lang, style: AppTypography.body),
                value: lang,
                groupValue: _selectedLanguage,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedLanguage = val);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Language changed to $val'), duration: const Duration(seconds: 1)),
                    );
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showBlockedUsers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  const SizedBox(height: 20),
                  Text('Blocked Users', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Users you block will not be able to follow you or contact you.', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  const Divider(height: 24),
                  if (_blockedUsers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text('No blocked users.', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _blockedUsers.length,
                      itemBuilder: (context, index) {
                        final name = _blockedUsers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.border,
                            child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                          trailing: TextButton(
                            child: const Text('Unblock', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              setModalState(() {
                                _blockedUsers.remove(name);
                              });
                              setState(() {}); // Update main screen if needed
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text(
            'This action is permanent and cannot be undone. All your profile details, settings, and local history will be wiped out.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close settings screen
                ref.read(appRoleProvider.notifier).state = null; // Logout
                ref.read(bottomNavIndexProvider.notifier).state = 0;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account successfully deleted.'), backgroundColor: Colors.red),
                );
              },
            ),
          ],
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
            Text('Appearance', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
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
                          Icon(LucideIcons.palette, color: Theme.of(context).iconTheme.color),
                          const SizedBox(width: 12),
                          Text('Theme Mode', style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text(
                        activeThemeMode == ThemeMode.system
                            ? 'System'
                            : activeThemeMode == ThemeMode.dark
                                ? 'Dark'
                                : 'Light',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
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
                          onTap: () => ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.light),
                          icon: LucideIcons.sun,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOptionButton(
                          label: 'Dark',
                          isSelected: activeThemeMode == ThemeMode.dark,
                          onTap: () => ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                          icon: LucideIcons.moon,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildThemeOptionButton(
                          label: 'System',
                          isSelected: activeThemeMode == ThemeMode.system,
                          onTap: () => ref.read(appThemeModeProvider.notifier).setThemeMode(ThemeMode.system),
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
            Text('Notifications', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
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
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSwitchTile(
                    label: 'Offer Alerts',
                    icon: LucideIcons.tag,
                    val: _offerNotifications,
                    onChanged: (v) => setState(() => _offerNotifications = v),
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSwitchTile(
                    label: 'Nearby Deals',
                    icon: LucideIcons.navigation,
                    val: _nearbyDealsNotifications,
                    onChanged: (v) => setState(() => _nearbyDealsNotifications = v),
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildSwitchTile(
                    label: 'Marketing & Promos',
                    icon: LucideIcons.megaphone,
                    val: _marketingNotifications,
                    onChanged: (v) => setState(() => _marketingNotifications = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // --- PREFERENCES ---
            Text('Preferences', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
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
                    label: 'Blocked Users',
                    subtitle: '${_blockedUsers.length} users',
                    icon: LucideIcons.shieldAlert,
                    onTap: _showBlockedUsers,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // --- PERMISSIONS ---
            Text('App Permissions', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
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
                    onChanged: (v) => setState(() => _notificationPermission = v),
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
                  color: Colors.red.shade50.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: const Center(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
    final activeTextColor = isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;


    return ScaleButtonPressed(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).dividerColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).dividerColor,
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
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      trailing: Switch.adaptive(
        value: val,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildClickTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16),
      onTap: onTap,
    );
  }
}
