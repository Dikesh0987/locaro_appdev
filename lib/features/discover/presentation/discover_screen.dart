import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../core/widgets/common/offer_badge.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../core/widgets/navigation/top_app_bar.dart';
import '../../../core/widgets/common/skeleton_loaders.dart';
import '../../../providers/app_state_providers.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import '../../products/presentation/product_details_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../../core/utils/page_transitions.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  bool _isLoading = true;
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseProvider);
    final shops = state.shops.where((s) => s.shopName.toLowerCase().contains(_searchQuery) || s.category.toLowerCase().contains(_searchQuery)).toList();
    final products = state.products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
    final offers = state.offers.where((o) => o.title.toLowerCase().contains(_searchQuery) || o.description.toLowerCase().contains(_searchQuery)).toList();

    return Scaffold(
      appBar: const TopAppBar(),
      body: SingleChildScrollView(
        key: const PageStorageKey('discover_feed'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
              child: Text(
                'Explore',
                style: AppTypography.display.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
              child: TextFormField(
                readOnly: true,
                onTap: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(page: const SearchScreen()),
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Search shops, products...',
                  hintStyle: AppTypography.body.copyWith(color: context.colors.textSecondary),
                  prefixIcon: Icon(LucideIcons.search, size: 20, color: context.colors.textSecondary),
                  filled: true,
                  fillColor: context.colors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(100),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),

            // Category Chips (Mock)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
                children: [
                  _buildCategoryChip(context, 'All', true),
                  const SizedBox(width: 8),
                  _buildCategoryChip(context, 'Fashion', false),
                  const SizedBox(width: 8),
                  _buildCategoryChip(context, 'Electronics', false),
                  const SizedBox(width: 8),
                  _buildCategoryChip(context, 'Food & Drinks', false),
                  const SizedBox(width: 8),
                  _buildCategoryChip(context, 'Services', false),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s32),

            // Trending Products
            _buildSectionHeader(context, 'Trending Products', () {}),
            if (_isLoading && products.isEmpty)
              _buildProductSkeletons()
            else if (products.isEmpty)
              _buildEmptyState(context, 'No Products Available', LucideIcons.packageOpen)
            else
              SizedBox(
                height: 220,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.s16),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          SlidePageRoute(page: ProductDetailsScreen(productId: p.id)),
                        );
                      },
                      child: SizedBox(
                        width: 140,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                child: FallbackImage(
                                  imageUrl: p.images.isNotEmpty ? p.images.first : '',
                                  width: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            Text(
                              p.name,
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${p.discountPrice?.toStringAsFixed(0) ?? p.price.toStringAsFixed(0)}',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: context.colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Nearby Shops
            _buildSectionHeader(context, 'Nearby Shops', () {}),
            if (_isLoading && shops.isEmpty)
              _buildShopSkeletons()
            else if (shops.isEmpty)
              _buildEmptyState(context, 'No Shops Nearby', LucideIcons.store)
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
                  scrollDirection: Axis.horizontal,
                  itemCount: shops.length,
                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.s16),
                  itemBuilder: (context, index) {
                    final s = shops[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          SlidePageRoute(page: ShopProfileScreen(shopId: s.id)),
                        );
                      },
                      child: SizedBox(
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                child: FallbackImage(
                                  imageUrl: s.banner,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.shopName,
                                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (s.showOnlineStatus) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: s.isOnline ? Colors.green : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    s.isOnline ? 'Online' : 'Offline',
                                    style: AppTypography.label.copyWith(
                                      color: s.isOnline ? Colors.green : Colors.grey,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  s.category,
                                  style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                                ),
                                const SizedBox(width: 4),
                                const Icon(LucideIcons.star, size: 10, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  s.rating.toString(),
                                  style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Popular Offers
            _buildSectionHeader(context, 'Popular Offers', () {}),
            if (_isLoading && offers.isEmpty)
              _buildOfferSkeletons()
            else if (offers.isEmpty)
              _buildEmptyState(context, 'No Offers Available', LucideIcons.tag)
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
                itemCount: offers.length > 3 ? 3 : offers.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s12),
                itemBuilder: (context, index) {
                  final o = offers[index];
                  final shop = shops.firstWhere((s) => s.id == o.shopId);

                  return BaseCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        SlidePageRoute(page: ShopProfileScreen(shopId: shop.id)),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 4),
                            child: FallbackImage(
                              imageUrl: o.banner,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        o.title,
                                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    OfferBadge(text: o.discount),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  shop.shopName,
                                  style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  o.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildProductSkeletons() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.s16),
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 140,
            child: ProductSkeletonCard(),
          );
        },
      ),
    );
  }

  Widget _buildShopSkeletons() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.s16),
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 200,
            child: ShopCardSkeleton(),
          );
        },
      ),
    );
  }

  Widget _buildOfferSkeletons() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) {
        return const OfferCardSkeleton();
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.heading.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'See all',
              style: AppTypography.caption.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: context.colors.border),
          const SizedBox(height: AppSpacing.s12),
          Text(
            message,
            style: AppTypography.body.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? context.colors.primary : context.colors.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isSelected ? context.colors.primary : context.colors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: isSelected ? context.colors.surface : context.colors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
