import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/lead_model.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import '../../auth/application/auth_service.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _activeImageIndex = 0;

  void _generateLead(LeadType type, String typeLabel, String shopId, String productName) {
    ref.read(authServiceProvider).checkGuest(context, onAllowed: () {
      final dbState = ref.read(databaseProvider);
      final newLead = LeadModel(
        id: 'lead_${DateTime.now().millisecondsSinceEpoch}',
        userId: dbState.currentUser.id,
        userName: dbState.currentUser.name,
        userPhone: dbState.currentUser.phone,
        productId: widget.productId,
        productName: productName,
        shopId: shopId,
        type: type,
        status: 'New',
        createdAt: DateTime.now(),
      );

      ref.read(databaseProvider.notifier).addLead(newLead);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulated Lead: $typeLabel generated for this product!'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseProvider);
    
    // Find the product
    final product = state.products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => state.products.first,
    );

    // Find the shop owner of this product
    final shop = state.shops.firstWhere(
      (s) => s.id == product.shopId,
      orElse: () => state.currentShop,
    );

    final isSaved = state.currentUser.savedProducts.contains(product.id);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Swiper Image Gallery
                Stack(
                  children: [
                    SizedBox(
                      height: 380,
                      child: PageView.builder(
                        itemCount: product.images.length,
                        onPageChanged: (index) {
                          setState(() => _activeImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return FallbackImage(
                            imageUrl: product.images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          );
                        },
                      ),
                    ),
                    // Gallery dots
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          product.images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _activeImageIndex == index
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Header Actions (Back & Save)
                    Positioned(
                      top: 50,
                      left: AppSpacing.mobilePadding,
                      right: AppSpacing.mobilePadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.arrowLeft, size: 20, color: AppColors.primary),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ref.read(authServiceProvider).checkGuest(context, onAllowed: () {
                                ref.read(databaseProvider.notifier).toggleSaveProduct(product.id);
                                if (!isSaved) {
                                  _generateLead(LeadType.saved, 'Product Saved', product.shopId, product.name);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSaved ? LucideIcons.bookmark : LucideIcons.bookmark,
                                size: 20,
                                color: isSaved ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),

                // Details Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sale badge and title
                      Row(
                        children: [
                          if (product.discountPrice != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.offerOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SALE',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.offerOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Icon(LucideIcons.clock, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('Just listed', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: AppTypography.heading.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${product.discountPrice?.toStringAsFixed(0) ?? product.price.toStringAsFixed(0)}',
                                style: AppTypography.heading.copyWith(fontWeight: FontWeight.w800, fontSize: 24),
                              ),
                              if (product.discountPrice != null)
                                Text(
                                  '₹${product.price.toStringAsFixed(0)}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),

                      // Shop Card info
                      BaseCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShopProfileScreen(shopId: shop.id),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.s16),
                          child: Row(
                            children: [
                              FallbackAvatar(
                                imageUrl: shop.logo,
                                radius: 20,
                                fallbackIcon: LucideIcons.store,
                              ),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.shopName,
                                      style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Verified Studio • 0.8 mi away',
                                      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.chevronRight, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),

                      // About Item Description
                      Text('About this item', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        product.description,
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),

                      // Specification details grid inspired by Airbnb list
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.s12,
                        mainAxisSpacing: AppSpacing.s12,
                        childAspectRatio: 2.2,
                        children: [
                          _buildSpecCard(LucideIcons.layoutGrid, 'CATEGORY', product.category),
                          _buildSpecCard(LucideIcons.checkCircle, 'CONDITION', 'Excellent Local'),
                          _buildSpecCard(LucideIcons.boxes, 'STOCK AVAILABLE', '${product.stock} units'),
                          _buildSpecCard(LucideIcons.truck, 'DELIVERY', 'Available locally'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pinned Bottom Actions Sheet matching Apple styled Layout
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                left: AppSpacing.mobilePadding,
                right: AppSpacing.mobilePadding,
                top: AppSpacing.s16,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(LucideIcons.heart, size: 16, color: AppColors.primary),
                          label: const Text('Interested', style: TextStyle(color: AppColors.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          onPressed: () {
                            ref.read(databaseProvider.notifier).toggleLikeProduct(product.id);
                            _generateLead(LeadType.interested, 'Interested action', product.shopId, product.name);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(LucideIcons.percent, size: 16, color: AppColors.offerOrange),
                          label: const Text('Ask Discount', style: TextStyle(color: AppColors.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          onPressed: () {
                            _generateLead(LeadType.discountRequest, 'Discount Request', product.shopId, product.name);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(LucideIcons.messageSquare, color: Colors.white),
                      label: const Text('WhatsApp Shop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                      ),
                      onPressed: () {
                        _generateLead(LeadType.whatsappClick, 'WhatsApp query', product.shopId, product.name);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(IconData icon, String header, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                header,
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
