import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../core/widgets/common/offer_badge.dart';
import '../../../providers/app_state_providers.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import '../../products/presentation/product_details_screen.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseProvider);
    final shops = state.shops;
    final products = state.products;
    final offers = state.offers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
              child: SizedBox(
                height: 52,
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Discover shops, products, offers...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Trending Products
            _buildSectionHeader(context, 'Trending Products', () {}),
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
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(productId: p.id),
                        ),
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
                              child: Image.network(
                                p.images.first,
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
                              color: AppColors.primary,
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
                        MaterialPageRoute(
                          builder: (context) => ShopProfileScreen(shopId: s.id),
                        ),
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
                              child: Image.network(
                                s.banner,
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            s.shopName,
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                s.category,
                                style: AppTypography.label.copyWith(color: AppColors.textSecondary),
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
                      MaterialPageRoute(
                        builder: (context) => ShopProfileScreen(shopId: shop.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 4),
                          child: Image.network(
                            o.banner,
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
                                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                o.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label.copyWith(color: AppColors.textSecondary),
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
            const SizedBox(height: AppSpacing.sectionGap),

            // New in Town
            _buildSectionHeader(context, 'New in Town', () {}),
            SizedBox(
              height: 180,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
                scrollDirection: Axis.horizontal,
                itemCount: shops.reversed.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.s16),
                itemBuilder: (context, index) {
                  final s = shops.reversed.toList()[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopProfileScreen(shopId: s.id),
                        ),
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
                              child: Image.network(
                                s.banner,
                                width: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            s.shopName,
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            s.category,
                            style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
            style: AppTypography.subheading.copyWith(fontWeight: FontWeight.w700),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              'See all',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
