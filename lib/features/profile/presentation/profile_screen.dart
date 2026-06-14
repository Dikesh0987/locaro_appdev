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
import '../../queries/presentation/sent_queries_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/permission_service.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../core/utils/firebase_error_handler.dart';

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
    _isLoading = false;
  }

  String _formatMemberSince(DateTime dt) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return 'Member since ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final formattedMinute = minute.toString().padLeft(2, '0');
      return '$formattedHour:$formattedMinute $period';
    } catch (e) {
      return time;
    }
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
          const ProfileSkeletonHeader(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


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
                      name: user.name,
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
        

        _buildVerificationBanners(context, ref, user),

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
              icon: LucideIcons.phone,
              label: 'Change Mobile Number',
              trailingText: user.phone.isNotEmpty ? user.phone : 'Not Set',
              onTap: () => _showChangeMobileSheet(context, ref, user.phone, false),
            ),
            const Divider(height: 1, indent: 48),
            _buildMenuRow(
              context,
              icon: LucideIcons.messageSquare,
              label: 'My Queries',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SentQueriesScreen()));
              },
            ),

            const Divider(height: 1, indent: 48),
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
    final user = dbState.currentUser;

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileSkeletonHeader(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


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
                      name: shop.shopName,
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

        _buildVerificationBanners(context, ref, user),

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
            _buildInfoRow(context, LucideIcons.clock, 'Working Hours', '${_formatTime(shop.openTime)} - ${_formatTime(shop.closeTime)}'),
            const Divider(height: 1, indent: 48),
            _buildMenuRow(
              context,
              icon: LucideIcons.phone,
              label: 'Change Mobile Number',
              trailingText: shop.whatsapp.isNotEmpty ? '+91 ${shop.whatsapp}' : 'Not Set',
              onTap: () => _showChangeMobileSheet(context, ref, shop.whatsapp, true),
            ),
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
              icon: LucideIcons.eye,
              label: 'Show Online Status',
              val: shop.showOnlineStatus,
              onChanged: (v) async {
                final updatedShop = shop.copyWith(showOnlineStatus: v);
                await ref.read(databaseProvider.notifier).updateCurrentShop(updatedShop);
              },
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

  Widget _buildAnalyticCard(
    BuildContext context, 
    String title, 
    String value, 
    IconData icon, 
    Color color
  ) {
    return BaseCard(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.heading.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 2),
            Text(
              title,
              style: AppTypography.label.copyWith(color: context.colors.textSecondary, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
    final descCont = TextEditingController(text: shop.description);
    final openTimeCont = TextEditingController(text: shop.openTime);
    final closeTimeCont = TextEditingController(text: shop.closeTime);

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
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                           final TimeOfDay? picked = await showTimePicker(
                             context: context,
                             initialTime: TimeOfDay(
                               hour: int.tryParse(openTimeCont.text.split(':').first) ?? 9,
                               minute: int.tryParse(openTimeCont.text.split(':').last) ?? 0,
                             ),
                           );
                           if (picked != null) {
                             openTimeCont.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                           }
                        },
                        child: AbsorbPointer(
                          child: AppTextField(controller: openTimeCont, hintText: 'Open Time (HH:mm)'),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                           final TimeOfDay? picked = await showTimePicker(
                             context: context,
                             initialTime: TimeOfDay(
                               hour: int.tryParse(closeTimeCont.text.split(':').first) ?? 21,
                               minute: int.tryParse(closeTimeCont.text.split(':').last) ?? 0,
                             ),
                           );
                           if (picked != null) {
                             closeTimeCont.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                           }
                        },
                        child: AbsorbPointer(
                          child: AppTextField(controller: closeTimeCont, hintText: 'Close Time (HH:mm)'),
                        ),
                      ),
                    ),
                  ],
                ),
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
                        description: descCont.text,
                        openTime: openTimeCont.text,
                        closeTime: closeTimeCont.text,
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

  // Change Mobile Number Sheet
  void _showChangeMobileSheet(BuildContext context, WidgetRef ref, String currentPhone, bool isShop) {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    bool isOtpSent = false;
    bool isSheetLoading = false;
    String? verificationId;
    int cooldownSeconds = 0;
    Timer? cooldownTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void startCooldown() {
              cooldownSeconds = 30;
              cooldownTimer?.cancel();
              cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                setSheetState(() {
                  if (cooldownSeconds > 0) {
                    cooldownSeconds--;
                  } else {
                    timer.cancel();
                  }
                });
              });
            }

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
                      isOtpSent ? 'Enter OTP' : 'Change Mobile Number',
                      style: AppTypography.heading,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOtpSent
                          ? 'We sent a verification code to your new number.'
                          : 'Current: ${currentPhone.isNotEmpty ? currentPhone : "None"}\n\nEnter new number below:',
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
                        text: cooldownSeconds > 0 ? 'Resend in ${cooldownSeconds}s' : 'Send OTP',
                        isLoading: isSheetLoading,
                        onPressed: cooldownSeconds > 0 ? () {} : () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter phone number'),
                              ),
                            );
                            return;
                          }
                          String formattedPhone = phone.startsWith('+')
                              ? phone
                              : '+91$phone';

                          setSheetState(() => isSheetLoading = true);

                          try {
                            final isUsed = await ref.read(authRepositoryProvider).isPhoneNumberUsed(formattedPhone);
                            if (isUsed) {
                              if (context.mounted) {
                                setSheetState(() => isSheetLoading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('This phone number is already registered.')),
                                );
                              }
                              return;
                            }
                          } catch (e) {
                            debugPrint('Phone uniqueness check failed: $e');
                          }

                          try {
                            await fb.FirebaseAuth.instance.verifyPhoneNumber(
                              phoneNumber: formattedPhone,
                              timeout: const Duration(seconds: 60),
                              verificationCompleted: (fb.PhoneAuthCredential credential) async {
                                try {
                                  await ref.read(authServiceProvider).linkPhoneAccount(credential);
                                  if (isShop) {
                                    final updatedPhone = ref.read(databaseProvider).currentUser.phone;
                                    final shop = ref.read(databaseProvider).currentShop;
                                    final updatedShop = shop.copyWith(whatsapp: updatedPhone, phone: updatedPhone);
                                    await ref.read(databaseProvider.notifier).updateCurrentShop(updatedShop);
                                  }
                                  if (context.mounted) {
                                    setSheetState(() => isSheetLoading = false);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Mobile number linked successfully!')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setSheetState(() => isSheetLoading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(FirebaseErrorHandler.handleGenericException(e))),
                                    );
                                  }
                                }
                              },
                              verificationFailed: (fb.FirebaseAuthException e) {
                                setSheetState(() {
                                  isSheetLoading = false;
                                  if (e.code == 'too-many-requests') {
                                    startCooldown();
                                  }
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(FirebaseErrorHandler.handleAuthException(e)),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                              codeSent: (String verId, int? resendToken) {
                                setSheetState(() {
                                  verificationId = verId;
                                  isOtpSent = true;
                                  isSheetLoading = false;
                                  startCooldown();
                                });
                              },
                              codeAutoRetrievalTimeout: (String verId) {
                                verificationId = verId;
                              },
                            );
                          } catch (e) {
                            setSheetState(() => isSheetLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(FirebaseErrorHandler.handleGenericException(e))),
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
                        isLoading: isSheetLoading,
                        onPressed: () async {
                          final code = otpController.text.trim();
                          if (code.isEmpty || verificationId == null) return;

                          setSheetState(() => isSheetLoading = true);

                          try {
                            final credential = fb.PhoneAuthProvider.credential(
                              verificationId: verificationId!,
                              smsCode: code,
                            );
                            // Link with Firebase Auth and Update Database
                            await ref.read(authServiceProvider).linkPhoneAccount(credential);

                            if (isShop) {
                              final updatedPhone = ref.read(databaseProvider).currentUser.phone;
                              final shop = ref.read(databaseProvider).currentShop;
                              final updatedShop = shop.copyWith(whatsapp: updatedPhone, phone: updatedPhone);
                              await ref.read(databaseProvider.notifier).updateCurrentShop(updatedShop);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mobile number updated and linked successfully!')),
                              );
                            }
                          } on fb.FirebaseAuthException catch (e) {
                            setSheetState(() => isSheetLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(FirebaseErrorHandler.handleAuthException(e)),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } catch (e) {
                            setSheetState(() => isSheetLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(FirebaseErrorHandler.handleGenericException(e)),
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
    final granted = await PermissionService.requestPermission(
      context: context,
      permission: Permission.photos,
      title: 'Photo Library Access',
      rationale: 'Locaro needs access to your photos so you can choose a new profile picture.',
      icon: LucideIcons.image,
    );
    if (!granted) return;

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
    final granted = await PermissionService.requestPermission(
      context: context,
      permission: Permission.photos,
      title: 'Photo Library Access',
      rationale: 'Locaro needs access to your photos so you can select a shop logo.',
      icon: LucideIcons.image,
    );
    if (!granted) return;

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
    final granted = await PermissionService.requestPermission(
      context: context,
      permission: Permission.photos,
      title: 'Photo Library Access',
      rationale: 'Locaro needs access to your photos so you can select a shop cover banner.',
      icon: LucideIcons.image,
    );
    if (!granted) return;

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

  // ==========================================
  // --- CREDENTIAL LINKING ---
  // ==========================================
  Widget _buildVerificationBanners(BuildContext context, WidgetRef ref, UserModel user) {
    final currentUser = fb.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    final hasGoogle = currentUser.providerData.any((p) => p.providerId == 'google.com');
    final hasPhone = currentUser.providerData.any((p) => p.providerId == 'phone');

    List<Widget> banners = [];

    // If they signed up with Phone, they don't have Google linked
    if (!hasGoogle) {
      banners.add(
        _buildVerificationBanner(
          context: context,
          icon: LucideIcons.mail,
          color: Colors.blue,
          title: 'Link Google Account',
          subtitle: 'Link your Google account to log in seamlessly with Google.',
          buttonText: 'Link Google',
          onTap: () async {
            try {
              await ref.read(authServiceProvider).linkGoogleAccount();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google Account Linked Successfully!')),
                );
                setState(() {});
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to link Google: $e')),
                );
              }
            }
          },
        ),
      );
    }

    // If they signed up with Google, they don't have Phone linked
    if (!hasPhone && user.phone.isNotEmpty && !user.phoneVerified) {
      banners.add(
        _buildVerificationBanner(
          context: context,
          icon: LucideIcons.smartphone,
          color: Colors.amber,
          title: 'Verify Phone Number',
          subtitle: 'Verify your phone number to enable mobile login.',
          buttonText: 'Verify Phone',
          onTap: () => _showPhoneVerificationSheet(context, ref, user.phone),
        ),
      );
    }

    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        ...banners,
      ],
    );
  }

  Widget _buildVerificationBanner({
    required BuildContext context,
    required IconData icon,
    required MaterialColor color,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.shade700, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: color.shade900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTypography.caption.copyWith(color: color.shade900, height: 1.4)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color.shade900,
                side: BorderSide(color: color.shade400),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhoneVerificationSheet(BuildContext context, WidgetRef ref, String phone) {
    String verificationId = '';
    bool isOtpSent = false;
    bool isLoading = false;
    final otpController = TextEditingController();

    String formattedPhone = phone;
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+91$phone';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> sendOtp() async {
              setSheetState(() => isLoading = true);
              try {
                await fb.FirebaseAuth.instance.verifyPhoneNumber(
                  phoneNumber: formattedPhone,
                  timeout: const Duration(seconds: 60),
                  verificationCompleted: (fb.PhoneAuthCredential credential) async {
                    try {
                      await ref.read(authServiceProvider).linkPhoneAccount(credential);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Phone Verified Successfully!')),
                        );
                      }
                    } catch (e) {
                      debugPrint('Auto-verify link failed: $e');
                    }
                  },
                  verificationFailed: (fb.FirebaseAuthException e) {
                    setSheetState(() => isLoading = false);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(e.message ?? 'Verification failed')),
                    );
                  },
                  codeSent: (String vId, int? resendToken) {
                    setSheetState(() {
                      verificationId = vId;
                      isOtpSent = true;
                      isLoading = false;
                    });
                  },
                  codeAutoRetrievalTimeout: (String vId) {
                    verificationId = vId;
                  },
                );
              } catch (e) {
                setSheetState(() => isLoading = false);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed to send OTP: $e')),
                );
              }
            }

            Future<void> verifyOtp() async {
              if (otpController.text.length < 6) return;
              setSheetState(() => isLoading = true);
              try {
                final credential = fb.PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: otpController.text,
                );
                await ref.read(authServiceProvider).linkPhoneAccount(credential);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone Linked Successfully!')),
                  );
                }
              } catch (e) {
                setSheetState(() => isLoading = false);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Invalid OTP: $e')),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Verify Phone', style: AppTypography.heading),
                      IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Phone Number: $formattedPhone', style: AppTypography.body),
                  const SizedBox(height: 24),

                  if (!isOtpSent) ...[
                    PrimaryButton(
                      text: 'Send OTP',
                      isLoading: isLoading,
                      onPressed: sendOtp,
                    ),
                  ] else ...[
                    AppTextField(
                      controller: otpController,
                      hintText: 'Enter 6-digit OTP',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Verify & Link',
                      isLoading: isLoading,
                      onPressed: verifyOtp,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: sendOtp,
                        child: const Text('Resend OTP'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
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
