import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../providers/app_state_providers.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import '../../products/presentation/product_details_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appRoleProvider);
    final state = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.mobilePadding),
        child: role == 'user'
            ? _buildUserProfile(context, ref, state)
            : _buildOwnerProfile(context, ref, state),
      ),
    );
  }

  // --- USER PROFILE VIEW ---
  Widget _buildUserProfile(BuildContext context, WidgetRef ref, NearoDataState dbState) {
    final user = dbState.currentUser;
    // Map list of saved product IDs to actual products
    final savedProducts = dbState.products.where((p) => user.savedProducts.contains(p.id)).toList();
    // Map list of followed shop IDs to actual shops
    final followedShops = dbState.shops.where((s) => user.followingShops.contains(s.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.border,
              backgroundImage: NetworkImage(user.profileImage),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: AppTypography.heading),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        user.location,
                        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Interests Tags
        Text('My Interests', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: user.interests.map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                interest,
                style: AppTypography.label.copyWith(color: AppColors.textPrimary),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Saved Products
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Saved Products', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
            Text('${savedProducts.length} items', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ],
        ),
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
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(productId: p.id),
                        ),
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
                        Text(p.name, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                        Text('₹${p.discountPrice?.toStringAsFixed(0) ?? p.price.toStringAsFixed(0)}', style: AppTypography.label),
                      ],
                    ),
                  );
                },
              ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Followed Shops
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Followed Shops', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
            Text('${followedShops.length} shops', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
          ],
        ),
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
                        MaterialPageRoute(
                          builder: (context) => ShopProfileScreen(shopId: s.id),
                        ),
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
        const SizedBox(height: AppSpacing.sectionGap * 2),

        // Logout
        _buildLogoutButton(ref),
      ],
    );
  }

  // --- SHOP OWNER PROFILE VIEW ---
  Widget _buildOwnerProfile(BuildContext context, WidgetRef ref, NearoDataState dbState) {
    final shop = dbState.currentShop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.border,
              backgroundImage: NetworkImage(shop.logo),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(shop.shopName, style: AppTypography.heading),
                      if (shop.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.checkCircle, size: 16, color: AppColors.success),
                      ]
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Owner: ${shop.ownerName}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        shop.address,
                        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Store Analytics Overview Card
        BaseCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Store Status', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOwnerStat('Followers', shop.followers.toString()),
                    _buildOwnerStat('Rating', '${shop.rating} ★'),
                    _buildOwnerStat('WhatsApp', 'Active'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap),

        // Business Description
        Text('Store Description', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.s8),
        Text(
          shop.description,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.sectionGap * 2),

        // Navigation helpers for merchant
        BaseCard(
          onTap: () {
            ref.read(bottomNavIndexProvider.notifier).state = 1; // Products tab
          },
          child: const ListTile(
            leading: Icon(LucideIcons.shoppingBag, color: AppColors.primary),
            title: Text('Manage Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Icon(LucideIcons.chevronRight, size: 16),
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        BaseCard(
          onTap: () {
            ref.read(bottomNavIndexProvider.notifier).state = 3; // Leads tab
          },
          child: const ListTile(
            leading: Icon(LucideIcons.users, color: AppColors.primary),
            title: Text('View Active Leads', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Icon(LucideIcons.chevronRight, size: 16),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionGap * 2),

        // Logout
        _buildLogoutButton(ref),
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
        child: Text(
          msg,
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildOwnerStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: AppTypography.heading.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildLogoutButton(WidgetRef ref) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        onPressed: () {
          ref.read(appRoleProvider.notifier).state = null;
          ref.read(bottomNavIndexProvider.notifier).state = 0;
        },
        child: Text(
          'Log Out',
          style: AppTypography.body.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
