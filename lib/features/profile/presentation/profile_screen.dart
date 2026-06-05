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
import '../../../core/widgets/common/scale_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/user_model.dart';
import '../../../models/shop_model.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import '../../products/presentation/product_details_screen.dart';
import '../../auth/application/auth_service.dart';
import '../../auth/data/auth_repository.dart';
import 'settings_screen.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appRoleProvider);
    final state = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(role == 'user' ? 'My Profile' : 'Merchant Profile'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {
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
            },
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: AppSpacing.s12),
        child: role == 'user'
            ? _buildUserProfile(context, ref, state)
            : _buildOwnerProfile(context, ref, state),
      ),
    );
  }

  // ==========================================
  // --- USER PROFILE VIEW ---
  // ==========================================
  Widget _buildUserProfile(BuildContext context, WidgetRef ref, NearoDataState dbState) {
    final user = dbState.currentUser;
    final savedProducts = dbState.products.where((p) => user.savedProducts.contains(p.id)).toList();
    final followedShops = dbState.shops.where((s) => user.followingShops.contains(s.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Profile Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: ScaleButtonPressed(
                      onTap: () => _changePhoto(context, ref),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.border,
                            backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null,
                            child: user.profileImage.isEmpty
                                ? const Icon(LucideIcons.user, size: 24)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.camera, size: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: AppTypography.heading.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(user.email, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 10, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(user.location, style: AppTypography.label.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(LucideIcons.edit2, size: 14),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      ),
                      onPressed: () => _showEditProfileSheet(context, ref, user),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        // My Saved Catalog Section
        _buildSectionHeader('Saved Products', '${savedProducts.length} items'),
        const SizedBox(height: AppSpacing.s12),
        savedProducts.isEmpty
            ? _buildEmptyState('No saved products yet.')
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.s16,
                  crossAxisSpacing: AppSpacing.s16,
                  childAspectRatio: 0.8,
                ),
                itemCount: savedProducts.length,
                itemBuilder: (context, index) {
                  final p = savedProducts[index];
                  return ScaleButtonPressed(
                    onTap: () {
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
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                            child: Image.network(p.images.first, fit: BoxFit.cover, width: double.infinity),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(p.name, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('₹${p.discountPrice?.toStringAsFixed(0) ?? p.price.toStringAsFixed(0)}', style: AppTypography.label),
                      ],
                    ),
                  );
                },
              ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Followed Shops Section
        _buildSectionHeader('Followed Shops', '${followedShops.length} shops'),
        const SizedBox(height: AppSpacing.s12),
        followedShops.isEmpty
            ? _buildEmptyState('No followed shops yet.')
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: followedShops.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s12),
                itemBuilder: (context, index) {
                  final s = followedShops[index];
                  return BaseCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ShopProfileScreen(shopId: s.id)),
                      );
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(s.logo),
                      ),
                      title: Text(s.shopName, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(s.category, style: AppTypography.caption),
                      trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    ),
                  );
                },
              ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Settings & Preferences Section
        Text('Settings & Preferences', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _buildMenuRow(context, LucideIcons.languages, 'Language', () => _navigateToSettings(context)),
              const Divider(height: 1, indent: 48),
              _buildMenuRow(context, LucideIcons.bell, 'Notifications', () => _navigateToSettings(context)),
              const Divider(height: 1, indent: 48),
              _buildMenuRow(context, LucideIcons.palette, 'Appearance', () => _navigateToSettings(context)),
              const Divider(height: 1, indent: 48),
              _buildMenuRow(context, LucideIcons.shieldAlert, 'Privacy & Security', () => _navigateToSettings(context)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Support & About Info Blocks
        Text('App Information', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _buildMenuRow(context, LucideIcons.helpCircle, 'Help & Support', () => _showHelpSupportSheet(context)),
              const Divider(height: 1, indent: 48),
              _buildMenuRow(context, LucideIcons.fileText, 'Terms & Conditions', () => _showDocumentSheet(context, 'Terms & Conditions', _dummyTerms)),
              const Divider(height: 1, indent: 48),
              _buildMenuRow(context, LucideIcons.lock, 'Privacy Policy', () => _showDocumentSheet(context, 'Privacy Policy', _dummyPrivacyPolicy)),
              const Divider(height: 1, indent: 48),
              _buildMenuRow(context, LucideIcons.info, 'About Nearo', () => _showDocumentSheet(context, 'About Nearo', _dummyAboutNearo)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        // User Feedback Actions
        Text('Feedback & Sharing', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _buildMenuRow(context, LucideIcons.star, 'Rate App', () => _showRatingDialog(context)),
              const Divider(height: 1, indent: 48),
              _buildMenuRow(context, LucideIcons.share2, 'Share App', () => _showShareSheet(context)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap * 2),

        // Logout
        _buildLogoutButton(context, ref),
        const SizedBox(height: 32),
      ],
    );
  }

  // ==========================================
  // --- SHOP OWNER PROFILE VIEW ---
  // ==========================================
  Widget _buildOwnerProfile(BuildContext context, WidgetRef ref, NearoDataState dbState) {
    final shop = dbState.currentShop;
    final shopLeads = dbState.leads.where((l) => l.shopId == shop.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Banner and Logo Stack
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius - 1)),
                    child: Image.network(
                      shop.banner,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ScaleButtonPressed(
                      onTap: () => _changeShopBanner(context, ref, shop),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.border,
                          backgroundImage: NetworkImage(shop.logo),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: ScaleButtonPressed(
                            onTap: () => _changeShopLogo(context, ref, shop),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.camera, size: 10, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(shop.shopName, style: AppTypography.heading.copyWith(fontWeight: FontWeight.w800)),
                              if (shop.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(LucideIcons.checkCircle, size: 16, color: AppColors.success),
                              ]
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Owner: ${shop.ownerName}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(LucideIcons.store, size: 10, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(shop.category, style: AppTypography.label.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.edit3, size: 14),
                        label: const Text('Edit Shop Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                        onPressed: () => _showEditShopSheet(context, ref, shop),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Shop Analytics Overview
        Text('Business Performance', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAnalyticsMetric('Views', '4,210', '+12%'),
                  _buildAnalyticsMetric('Leads', '${shopLeads.length}', '+8%'),
                  _buildAnalyticsMetric('Followers', '${shop.followers}', '+15%'),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Conversion Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              _buildConversionProgressBar('WhatsApp Clicks', 0.65, '96 clicks'),
              const SizedBox(height: 8),
              _buildConversionProgressBar('Discount Requests', 0.25, '36 requests'),
              const SizedBox(height: 8),
              _buildConversionProgressBar('Product Saves', 0.40, '58 saves'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Business Information
        Text('Store Information', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _buildInfoRow(context, LucideIcons.mapPin, 'Address', shop.address),
              const Divider(height: 1, indent: 48),
              _buildInfoRow(context, LucideIcons.clock, 'Working Hours', '09:00 AM - 09:00 PM'),
              const Divider(height: 1, indent: 48),
              _buildInfoRow(context, LucideIcons.messageCircle, 'WhatsApp Channel', '+91 ${shop.whatsapp}'),
              const Divider(height: 1, indent: 48),
              _buildInfoRow(context, LucideIcons.info, 'Verification Status', shop.isVerified ? 'Verified Partner' : 'Standard Partner'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Merchant Privacy/Notification settings
        Text('Merchant Portal Settings', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              _buildSwitchRow(context, LucideIcons.bell, 'Real-time Lead Notifications', true),
              const Divider(height: 1, indent: 48),
              _buildSwitchRow(context, LucideIcons.eye, 'Show Store Online Status', true),
              const Divider(height: 1, indent: 48),
              _buildMenuRow(context, LucideIcons.helpCircle, 'Merchant Help Desk', () => _showHelpSupportSheet(context)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap * 2),

        // Logout
        _buildLogoutButton(context, ref),
        const SizedBox(height: 32),
      ],
    );
  }

  // ==========================================
  // --- BOTTOM SHEETS & INTERACTION DIALOGS ---
  // ==========================================

  // EDIT USER PROFILE SHEET
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
              const SizedBox(height: 16),
              Text('Edit Profile', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              AppTextField(controller: nameCont, hintText: 'Full Name'),
              const SizedBox(height: 12),
              AppTextField(controller: emailCont, hintText: 'Email Address', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              AppTextField(controller: phoneCont, hintText: 'Phone Number', keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
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

  // EDIT SHOP DETAILS SHEET
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
                const SizedBox(height: 16),
                Text('Edit Shop Details', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                AppTextField(controller: nameCont, hintText: 'Shop Name'),
                const SizedBox(height: 12),
                AppTextField(controller: ownerCont, hintText: 'Owner Name'),
                const SizedBox(height: 12),
                AppTextField(controller: addressCont, hintText: 'Shop Address'),
                const SizedBox(height: 12),
                AppTextField(controller: phoneCont, hintText: 'WhatsApp Number'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCont,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Shop Description...'),
                ),
                const SizedBox(height: 24),
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

  // FAQ HELP DESK ACCORDION
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
              const SizedBox(height: 20),
              Text('Help & FAQ Desk', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              _buildFaqTile('How do I contact a shop owner?', 'Simply click on any product, click "WhatsApp" or "Interested" and you will be connected with the shop owner instantly.'),
              const Divider(height: 1),
              _buildFaqTile('How is my location used?', 'We only use your approximate location coordinates to find and display shops and offers within 2-3 km of your radius.'),
              const Divider(height: 1),
              _buildFaqTile('How do I register a merchant shop?', 'Log out from your User profile, select "Shop Owner" in the selection panel, and complete the business registration form.'),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // TERMS / PRIVACY DISPLAY SHEET
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
              const SizedBox(height: 16),
              Text(title, style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    body,
                    style: AppTypography.body.copyWith(height: 1.5, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // INTERACTIVE APP RATING DIALOG
  void _showRatingDialog(BuildContext context) {
    int selectedRating = 0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Center(child: Text('Rate Nearo', style: TextStyle(fontWeight: FontWeight.bold))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enjoying your local neighborhood catalog? Tap stars to rate us!', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      final isLit = starNum <= selectedRating;
                      return IconButton(
                        icon: Icon(
                          LucideIcons.star,
                          color: isLit ? Colors.amber : Colors.grey.shade400,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() => selectedRating = starNum);
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thank you for rating us $selectedRating stars!')),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // APP SHARING BOTTOM SHEET
  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
              const SizedBox(height: 20),
              Text('Share Nearo', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareIcon(LucideIcons.link, 'Copy Link', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
                  }),
                  _buildShareIcon(LucideIcons.messageCircle, 'WhatsApp', () => Navigator.pop(context)),
                  _buildShareIcon(LucideIcons.camera, 'Instagram', () => Navigator.pop(context)),
                  _buildShareIcon(LucideIcons.send, 'Twitter', () => Navigator.pop(context)),

                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // --- SUB-WIDGET COMPONENTS ---
  // ==========================================

  Widget _buildShareIcon(IconData icon, String label, VoidCallback onTap) {
    return ScaleButtonPressed(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTypography.label.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Text(answer, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.4)),
        ),
      ],
    );
  }

  Widget _buildAnalyticsMetric(String label, String val, String trend) {
    return Column(
      children: [
        Text(val, style: AppTypography.display.copyWith(fontWeight: FontWeight.w800, fontSize: 24)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(label, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            Text(trend, style: const TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildConversionProgressBar(String label, double val, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
            Text(desc, style: AppTypography.label.copyWith(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
        Text(val, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(msg, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildMenuRow(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String val) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      trailing: Text(
        val,
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSwitchRow(BuildContext context, IconData icon, String label, bool initVal) {
    return StatefulBuilder(
      builder: (context, setRowState) {
        return ListTile(
          leading: Icon(icon, color: Theme.of(context).iconTheme.color),
          title: Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          trailing: Switch.adaptive(
            value: initVal,
            activeColor: AppColors.primary,
            onChanged: (v) => setRowState(() => initVal = v),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return ScaleButtonPressed(
      onTap: () async {
        try {
          await ref.read(authServiceProvider).handleSignOut();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign out failed: ${e.toString()}')),
          );
        }
      },
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red.shade50.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: AppColors.error),
        ),
        child: Center(
          child: Text(
            'Log Out',
            style: AppTypography.body.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _changePhoto(BuildContext context, WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      try {
        await ref.read(authServiceProvider).changeProfilePhoto(File(image.path));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully.')),
        );
      } catch (e) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop logo updated successfully.')),
        );
      } catch (e) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop banner updated successfully.')),
        );
      } catch (e) {
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

  // --- DUMMY CORE DOCUMENT STRINGS ---
  static const String _dummyTerms = 'Welcome to Nearo. By accessing or using our hyperlocal discovery application, you agree to comply with and be bound by these terms. We match users with nearby merchant product catalogs without charging commission. We do not process direct transactions or store card detail info. Purchases are conducted offline or directly via the merchant\'s chosen channels (e.g. WhatsApp).';
  
  static const String _dummyPrivacyPolicy = 'At Nearo, we take privacy and local security seriously. We collect approximate location coordinates to retrieve catalog details from shops in your immediate vicinity. This coordinate info is processed locally and never sold or shared. Profile pictures, names, and contact detail info are only visible to merchants you explicitly contact.';
  
  static const String _dummyAboutNearo = 'Nearo is a premium hyperlocal discovery platform connecting customers with their neighborhood sellers. Inspired by modern minimalism, we design high-end shopping feed screens that bring back the charm of neighborhood discovery. Version 1.0.0 (Production Ready).';
}
