import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/navigation/top_app_bar.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/user_model.dart';
import '../../../models/shop_model.dart';
import '../../../models/product_model.dart';
import '../../products/presentation/product_details_screen.dart';
import '../../auth/application/auth_service.dart';
import '../../auth/data/auth_repository.dart';
import 'settings_screen.dart';
import '../../../core/widgets/common/skeleton_loaders.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  String _formatMemberSince(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return 'Member since ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(appRoleProvider);
    final state = ref.watch(databaseProvider);

    return Scaffold(
      appBar: const TopAppBar(),
      body: SingleChildScrollView(
        key: const PageStorageKey('profile_scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: AppSpacing.s16),
        child: role == 'user'
            ? _buildUserProfile(context, ref, state)
            : _buildOwnerProfile(context, ref, state),
      ),
    );
  }

  // ==========================================
  // --- USER PROFILE VIEW ---
  // ==========================================
  Widget _buildUserProfile(BuildContext context, WidgetRef ref, LocaroDataState dbState) {
    final user = dbState.currentUser;
    final savedProducts = dbState.products.where((p) => user.savedProducts.contains(p.id)).toList();
    final followedShops = dbState.shops.where((s) => user.followingShops.contains(s.id)).toList();

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: AppTypography.display.copyWith(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -0.8),
          ),
          const SizedBox(height: 20),
          const ProfileSkeletonHeader(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Profile',
          style: AppTypography.display.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: 20),

        // PROFILE HEADER
        Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: GestureDetector(
                onTap: () => _changePhoto(context, ref),
                child: Stack(
                  children: [
                    FallbackAvatar(
                      imageUrl: user.profileImage,
                      radius: 44,
                      fallbackIcon: LucideIcons.user,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.camera, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: AppTypography.heading.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    user.email,
                    style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 12, color: context.colors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        _formatMemberSince(user.createdAt),
                        style: AppTypography.label.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Edit Profile Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(LucideIcons.edit2, size: 14, color: context.colors.textPrimary),
            label: Text('Edit Profile', style: TextStyle(color: context.colors.textPrimary)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: context.colors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onPressed: () => _showEditProfileSheet(context, ref, user),
          ),
        ),
        SizedBox(height: 28),

        // QUICK ACTIONS SECTION
        _buildSectionTitle(context, 'QUICK ACTIONS'),
        SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildQuickActionCard(
              context,
              icon: LucideIcons.bookmark,
              title: 'Saved Products',
              subtitle: '${savedProducts.length} items',
              color: Colors.blue.shade50,
              iconColor: Colors.blue.shade700,
              onTap: () => _showSavedProductsSheet(context, savedProducts),
            ),
            _buildQuickActionCard(
              context,
              icon: LucideIcons.heart,
              title: 'Followed Shops',
              subtitle: '${followedShops.length} shops',
              color: Colors.pink.shade50,
              iconColor: Colors.pink.shade700,
              onTap: () {
                // Navigate to Following tab index
                ref.read(bottomNavIndexProvider.notifier).state = 3;
              },
            ),
            _buildQuickActionCard(
              context,
              icon: LucideIcons.bell,
              title: 'Notification Config',
              subtitle: 'Manage alerts',
              color: Colors.amber.shade50,
              iconColor: Colors.amber.shade700,
              onTap: () => _navigateToSettings(context),
            ),
            _buildQuickActionCard(
              context,
              icon: LucideIcons.palette,
              title: 'Appearance',
              subtitle: 'Theme & style',
              color: Colors.purple.shade50,
              iconColor: Colors.purple.shade700,
              onTap: () => _navigateToSettings(context),
            ),
          ],
        ),
        SizedBox(height: 28),

        // PREFERENCES SECTION
        _buildSectionTitle(context, 'PREFERENCES'),
        SizedBox(height: 10),
        _buildSectionCard(
          context,
          children: [
            _buildThemeSelectionRow(context, ref),
            const Divider(height: 1, indent: 48),
            _buildSwitchRow(
              context,
              icon: LucideIcons.bell,
              label: 'Push Notifications',
              val: user.notificationEnabled,
              onChanged: (v) async {
                final updatedUser = user.copyWith(notificationEnabled: v);
                await ref.read(databaseProvider.notifier).updateCurrentUser(updatedUser);
              },
            ),
            const Divider(height: 1, indent: 48),
            _buildSwitchRow(
              context,
              icon: LucideIcons.mapPin,
              label: 'Share Current Location',
              val: true, // Mock location permission toggle
              onChanged: (v) {},
            ),
          ],
        ),
        SizedBox(height: 28),

        // ACCOUNT SECTION
        _buildSectionTitle(context, 'ACCOUNT SECTION'),
        SizedBox(height: 10),
        _buildSectionCard(
          context,
          children: [
            _buildMenuRow(
              context,
              icon: LucideIcons.languages,
              label: 'Language',
              trailingText: user.language,
              onTap: () => _navigateToSettings(context),
            ),
            const Divider(height: 1, indent: 48),
            _buildMenuRow(
              context,
              icon: LucideIcons.shieldAlert,
              label: 'Privacy & Security',
              onTap: () => _navigateToSettings(context),
            ),
            const Divider(height: 1, indent: 48),
            _buildMenuRow(
              context,
              icon: LucideIcons.helpCircle,
              label: 'Help & Support',
              onTap: () => _showHelpSupportSheet(context),
            ),
            const Divider(height: 1, indent: 48),
            _buildMenuRow(
              context,
              icon: LucideIcons.fileText,
              label: 'Terms & Conditions',
              onTap: () => _showDocumentSheet(context, 'Terms & Conditions', _dummyTerms),
            ),
            const Divider(height: 1, indent: 48),
            _buildMenuRow(
              context,
              icon: LucideIcons.lock,
              label: 'Privacy Policy',
              onTap: () => _showDocumentSheet(context, 'Privacy Policy', _dummyPrivacyPolicy),
            ),
          ],
        ),
        SizedBox(height: 28),

        // DANGER ZONE
        _buildSectionTitle(context, 'DANGER ZONE'),
        SizedBox(height: 10),
        _buildSectionCard(
          context,
          borderColor: Colors.red.shade100,
          children: [
            _buildMenuRow(
              context,
              icon: LucideIcons.logOut,
              label: 'Log Out',
              textColor: context.colors.error,
              iconColor: context.colors.error,
              showChevron: false,
              onTap: () => _handleLogout(context, ref),
            ),
            const Divider(height: 1, indent: 48),
            _buildMenuRow(
              context,
              icon: LucideIcons.trash2,
              label: 'Delete Account',
              textColor: context.colors.error,
              iconColor: context.colors.error,
              showChevron: false,
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),
          ],
        ),
        SizedBox(height: 48),
      ],
    );
  }

  // ==========================================
  // --- SHOP OWNER PROFILE VIEW ---
  // ==========================================
  Widget _buildOwnerProfile(BuildContext context, WidgetRef ref, LocaroDataState dbState) {
    final shop = dbState.currentShop;

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Merchant Profile',
            style: AppTypography.display.copyWith(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -0.8),
          ),
          const SizedBox(height: 20),
          const ProfileSkeletonHeader(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Merchant Profile',
          style: AppTypography.display.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: 20),

        // PROFILE HEADER
        Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: GestureDetector(
                onTap: () => _changeShopLogo(context, ref, shop),
                child: Stack(
                  children: [
                    FallbackAvatar(
                      imageUrl: shop.logo,
                      radius: 44,
                      fallbackIcon: LucideIcons.store,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.camera, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop.shopName,
                          style: AppTypography.heading.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shop.isVerified) ...[
                        SizedBox(width: 6),
                        Icon(LucideIcons.checkCircle, size: 16, color: context.colors.success),
                      ]
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Owner: ${shop.ownerName}',
                    style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LucideIcons.store, size: 12, color: context.colors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        '${shop.category} • Verified Partner',
                        style: AppTypography.label.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Edit Shop Details Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(LucideIcons.edit3, size: 14, color: context.colors.textPrimary),
            label: Text('Edit Shop Details', style: TextStyle(color: context.colors.textPrimary)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: context.colors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            onPressed: () => _showEditShopSheet(context, ref, shop),
          ),
        ),
        SizedBox(height: 28),

        // QUICK ACTIONS SECTION
        _buildSectionTitle(context, 'QUICK ACTIONS'),
        SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildQuickActionCard(
              context,
              icon: LucideIcons.layoutDashboard,
              title: 'Merchant Center',
              subtitle: 'Go to Dashboard',
              color: Colors.blue.shade50,
              iconColor: Colors.blue.shade700,
              onTap: () {
                ref.read(bottomNavIndexProvider.notifier).state = 0;
              },
            ),
            _buildQuickActionCard(
              context,
              icon: LucideIcons.plusCircle,
              title: 'Add Product',
              subtitle: 'Launch a product',
              color: Colors.pink.shade50,
              iconColor: Colors.pink.shade700,
              onTap: () {
                ref.read(bottomNavIndexProvider.notifier).state = 1;
              },
            ),
            _buildQuickActionCard(
              context,
              icon: LucideIcons.camera,
              title: 'Shop Cover Banner',
              subtitle: 'Change cover image',
              color: Colors.amber.shade50,
              iconColor: Colors.amber.shade700,
              onTap: () => _changeShopBanner(context, ref, shop),
            ),
            _buildQuickActionCard(
              context,
              icon: LucideIcons.megaphone,
              title: 'Manage Posts',
              subtitle: 'Post updates & news',
              color: Colors.purple.shade50,
              iconColor: Colors.purple.shade700,
              onTap: () {
                ref.read(bottomNavIndexProvider.notifier).state = 2;
              },
            ),
          ],
        ),
        SizedBox(height: 28),

        // BUSINESS INFORMATION CARD
        _buildSectionTitle(context, 'STORE INFORMATION'),
        SizedBox(height: 10),
        _buildSectionCard(
          context,
          children: [
            _buildInfoRow(context, LucideIcons.mapPin, 'Address', shop.address),
            const Divider(height: 1, indent: 48),
            _buildInfoRow(context, LucideIcons.clock, 'Working Hours', '09:00 AM - 09:00 PM'),
            const Divider(height: 1, indent: 48),
            _buildInfoRow(context, LucideIcons.messageCircle, 'WhatsApp Channel', '+91 ${shop.whatsapp}'),
            const Divider(height: 1, indent: 48),
            _buildInfoRow(context, LucideIcons.info, 'Status', shop.isVerified ? 'Verified Partner' : 'Standard Partner'),
          ],
        ),
        SizedBox(height: 28),

        // PREFERENCES & SETTINGS CARD
        _buildSectionTitle(context, 'PREFERENCES & HELP'),
        SizedBox(height: 10),
        _buildSectionCard(
          context,
          children: [
            _buildThemeSelectionRow(context, ref),
            const Divider(height: 1, indent: 48),
            _buildSwitchRow(
              context,
              icon: LucideIcons.bell,
              label: 'Real-time Lead Notifications',
              val: true,
              onChanged: (v) {},
            ),
            const Divider(height: 1, indent: 48),
            _buildSwitchRow(
              context,
              icon: LucideIcons.eye,
              label: 'Show Online Status',
              val: true,
              onChanged: (v) {},
            ),
            const Divider(height: 1, indent: 48),
            _buildMenuRow(
              context,
              icon: LucideIcons.helpCircle,
              label: 'Merchant Help Desk',
              onTap: () => _showHelpSupportSheet(context),
            ),
          ],
        ),
        SizedBox(height: 28),

        // DANGER ZONE
        _buildSectionTitle(context, 'DANGER ZONE'),
        SizedBox(height: 10),
        _buildSectionCard(
          context,
          borderColor: Colors.red.shade100,
          children: [
            _buildMenuRow(
              context,
              icon: LucideIcons.logOut,
              label: 'Log Out',
              textColor: context.colors.error,
              iconColor: context.colors.error,
              showChevron: false,
              onTap: () => _handleLogout(context, ref),
            ),
          ],
        ),
        SizedBox(height: 48),
      ],
    );
  }

  // ==========================================
  // --- BOTTOM SHEETS & SUB WIDGETS ---
  // ==========================================

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: AppTypography.label.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required List<Widget> children, Color? borderColor}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? context.colors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: context.colors.surface,
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return BaseCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.label.copyWith(color: context.colors.textSecondary, fontSize: 10),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? trailingText,
    Color? textColor,
    Color? iconColor,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Theme.of(context).iconTheme.color, size: 20),
      title: Text(
        label,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor ?? context.colors.textPrimary,
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText,
              style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
            ),
            SizedBox(width: 8),
          ],
          if (showChevron)
            Icon(LucideIcons.chevronRight, size: 14, color: context.colors.textSecondary.withValues(alpha: 0.7)),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String val) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color, size: 20),
      title: Text(
        label,
        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: SizedBox(
        width: 150,
        child: Text(
          val,
          style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool val,
    required ValueChanged<bool> onChanged,
  }) {
    return StatefulBuilder(
      builder: (context, setStateRow) {
        return ListTile(
          leading: Icon(icon, color: Theme.of(context).iconTheme.color, size: 20),
          title: Text(
            label,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          trailing: Switch.adaptive(
            value: val,
            activeThumbColor: context.colors.primary,
            onChanged: (v) {
              setStateRow(() => val = v);
              onChanged(v);
            },
          ),
        );
      },
    );
  }

  Widget _buildThemeSelectionRow(BuildContext context, WidgetRef ref) {
    final activeThemeMode = ref.watch(appThemeModeProvider);

    return ListTile(
      leading: const Icon(LucideIcons.palette, size: 20),
      title: Text(
        'Theme Mode',
        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeOptionPill(
            label: 'Light',
            isSelected: activeThemeMode == ThemeMode.light,
            onTap: () => ref.read(authServiceProvider).updateThemeMode('light'),
          ),
          SizedBox(width: 6),
          _ThemeOptionPill(
            label: 'Dark',
            isSelected: activeThemeMode == ThemeMode.dark,
            onTap: () => ref.read(authServiceProvider).updateThemeMode('dark'),
          ),
          SizedBox(width: 6),
          _ThemeOptionPill(
            label: 'Auto',
            isSelected: activeThemeMode == ThemeMode.system,
            onTap: () => ref.read(authServiceProvider).updateThemeMode('system'),
          ),
        ],
      ),
    );
  }


  // Edit User Profile sheet
  void _showEditProfileSheet(BuildContext context, WidgetRef ref, UserModel user) {
    final nameCont = TextEditingController(text: user.name);
    final emailCont = TextEditingController(text: user.email);
    final phoneCont = TextEditingController(text: user.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: 16),
              Text('Edit Profile', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              AppTextField(controller: nameCont, hintText: 'Full Name'),
              SizedBox(height: 12),
              AppTextField(controller: emailCont, hintText: 'Email Address', keyboardType: TextInputType.emailAddress),
              SizedBox(height: 12),
              AppTextField(controller: phoneCont, hintText: 'Phone Number', keyboardType: TextInputType.phone),
              SizedBox(height: 24),
              PrimaryButton(
                text: 'Save Changes',
                onPressed: () {
                  if (nameCont.text.isEmpty || emailCont.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Email cannot be empty.')));
                  } else {
                    final updatedUser = user.copyWith(
                      name: nameCont.text,
                      email: emailCont.text,
                      phone: phoneCont.text,
                    );
                    ref.read(databaseProvider.notifier).updateCurrentUser(updatedUser);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Edit Shop Details Sheet
  void _showEditShopSheet(BuildContext context, WidgetRef ref, ShopModel shop) {
    final nameCont = TextEditingController(text: shop.shopName);
    final ownerCont = TextEditingController(text: shop.ownerName);
    final addressCont = TextEditingController(text: shop.address);
    final phoneCont = TextEditingController(text: shop.whatsapp);
    final descCont = TextEditingController(text: shop.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                SizedBox(height: 16),
                Text('Edit Shop Details', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                AppTextField(controller: nameCont, hintText: 'Shop Name'),
                SizedBox(height: 12),
                AppTextField(controller: ownerCont, hintText: 'Owner Name'),
                SizedBox(height: 12),
                AppTextField(controller: addressCont, hintText: 'Shop Address'),
                SizedBox(height: 12),
                AppTextField(controller: phoneCont, hintText: 'WhatsApp Number'),
                SizedBox(height: 12),
                TextFormField(
                  controller: descCont,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Shop Description...'),
                ),
                SizedBox(height: 24),
                PrimaryButton(
                  text: 'Save Details',
                  onPressed: () {
                    if (nameCont.text.isEmpty || ownerCont.text.isEmpty || addressCont.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Required fields cannot be empty.')));
                    } else {
                      final updatedShop = shop.copyWith(
                        shopName: nameCont.text,
                        ownerName: ownerCont.text,
                        address: addressCont.text,
                        whatsapp: phoneCont.text,
                        description: descCont.text,
                      );
                      ref.read(databaseProvider.notifier).updateCurrentShop(updatedShop);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop profile updated successfully.')));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Saved Products sheet overlay
  void _showSavedProductsSheet(BuildContext context, List<ProductModel> products) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: 16),
              Text('Saved Products', style: AppTypography.heading.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Expanded(
                child: products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.bookmark, size: 48, color: context.colors.border),
                              SizedBox(height: 16),
                              Text(
                                'No Saved Products',
                                style: AppTypography.heading.copyWith(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Products you save will appear here.',
                                style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                              ),
                            ],
                          ),
                        )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.s16,
                          crossAxisSpacing: AppSpacing.s16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final p = products[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ProductDetailsScreen(productId: p.id)),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: FallbackImage(
                                      imageUrl: p.images.isNotEmpty ? p.images.first : '',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  p.name,
                                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text('₹${p.discountPrice?.toStringAsFixed(0) ?? p.price.toStringAsFixed(0)}', style: AppTypography.label),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // FAQs
  void _showHelpSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: 20),
              Text('Help & Support FAQ', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              _buildFaqTile(context, 'How do I contact a shop owner?', 'Simply click on any product, click "WhatsApp" or "Interested" and you will be connected with the shop owner instantly.'),
              const Divider(height: 1),
              _buildFaqTile(context, 'How is my location used?', 'We only use your approximate location coordinates to find and display shops and offers within 2-3 km of your radius.'),
              const Divider(height: 1),
              _buildFaqTile(context, 'How do I register a merchant shop?', 'Log out from your User profile, select "Shop Owner" in the selection panel, and complete the business registration form.'),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFaqTile(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Text(answer, style: AppTypography.caption.copyWith(color: context.colors.textSecondary, height: 1.4)),
        ),
      ],
    );
  }

  // Terms & Privacy Sheets
  void _showDocumentSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: 16),
              Text(title, style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    body,
                    style: AppTypography.body.copyWith(height: 1.5, color: context.colors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Deletion Dialogue
  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text(
            'This action is permanent and cannot be undone. All your profile details, settings, and local history will be wiped out.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                try {
                  await ref.read(authServiceProvider).handleDeleteAccount();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account successfully deleted.'), backgroundColor: Colors.red),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authServiceProvider).handleSignOut();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _changePhoto(BuildContext context, WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      try {
        await ref.read(authServiceProvider).changeProfilePhoto(File(image.path));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully.')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _changeShopLogo(BuildContext context, WidgetRef ref, ShopModel shop) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      try {
        final url = await ref.read(authRepositoryProvider).uploadShopAsset(
          shop.id,
          'logo',
          File(image.path),
        );
        final updatedShop = shop.copyWith(logoUrl: url);
        await ref.read(databaseProvider.notifier).updateCurrentShop(updatedShop);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop logo updated successfully.')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update logo: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _changeShopBanner(BuildContext context, WidgetRef ref, ShopModel shop) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null) {
      try {
        final url = await ref.read(authRepositoryProvider).uploadShopAsset(
          shop.id,
          'banner',
          File(image.path),
        );
        final updatedShop = shop.copyWith(bannerUrl: url);
        await ref.read(databaseProvider.notifier).updateCurrentShop(updatedShop);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop banner updated successfully.')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update banner: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  static const String _dummyTerms = 'Welcome to Locaro. By accessing or using our hyperlocal discovery application, you agree to comply with and be bound by these terms. We match users with nearby merchant product catalogs without charging commission. We do not process direct transactions or store card detail info. Purchases are conducted offline or directly via the merchant\'s chosen channels (e.g. WhatsApp).';
  
  static const String _dummyPrivacyPolicy = 'At Locaro, we take privacy and local security seriously. We collect approximate location coordinates to retrieve catalog details from shops in your immediate vicinity. This coordinate info is processed locally and never sold or shared. Profile pictures, names, and contact detail info are only visible to merchants you explicitly contact.';
}

class _ThemeOptionPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary : context.colors.border,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            fontSize: 10,
            color: isSelected ? Colors.white : context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
