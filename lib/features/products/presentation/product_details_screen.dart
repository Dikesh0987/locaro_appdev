import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../providers/app_state_providers.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import '../../auth/application/auth_service.dart';
import '../../../core/widgets/common/skeleton_loaders.dart';
import '../../../core/widgets/common/animated_action_icon.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _activeImageIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    Future.microtask(() {
      ref.read(databaseProvider.notifier).incrementProductView(widget.productId);
    });
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseProvider);
    
    final product = state.products.where((p) => p.id == widget.productId).firstOrNull;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(child: Text('This product is no longer available.')),
      );
    }

    final shop = state.shops.where((s) => s.id == product.shopId).firstOrNull;
    if (shop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(child: Text('The shop for this product is no longer available.')),
      );
    }

    final isSaved = state.currentUser.savedProducts.contains(product.id);
    final isLiked = state.currentUser.likedProducts.contains(product.id);

    if (_isLoading) {
      return const Scaffold(
        body: SingleChildScrollView(
          child: ProductDetailsSkeleton(),
        ),
      );
    }

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
                                  ? context.colors.primary
                                  : context.colors.primary.withValues(alpha: 0.3),
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
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(LucideIcons.arrowLeft, size: 20, color: context.colors.primary),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ref.read(authServiceProvider).checkGuest(context, onAllowed: () {
                                ref.read(databaseProvider.notifier).toggleSaveProduct(product.id);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedActionIcon(
                                icon: LucideIcons.bookmark,
                                activeIcon: LucideIcons.bookmark, // Or another icon if available
                                isActive: isSaved,
                                inactiveColor: context.colors.textSecondary,
                                activeColor: context.colors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.s24),

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
                                color: context.colors.offerOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SALE',
                                style: AppTypography.label.copyWith(
                                  color: context.colors.offerOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                          ],
                          Icon(LucideIcons.clock, size: 12, color: context.colors.textSecondary),
                          SizedBox(width: 4),
                          Text('Just listed', style: AppTypography.label.copyWith(color: context.colors.textSecondary)),
                        ],
                      ),
                      SizedBox(height: AppSpacing.s12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: AppTypography.heading.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 12),
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
                                    color: context.colors.textSecondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.sectionGap),

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
                                name: shop.shopName,
                                radius: 20,
                                fallbackIcon: LucideIcons.store,
                              ),
                              SizedBox(width: AppSpacing.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.shopName,
                                      style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Verified Partner • 1.3 km away',
                                      style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.chevronRight, size: 16),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sectionGap),

                      // About Item Description
                      Text('About this item', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: AppSpacing.s8),
                      Text(
                        product.description,
                        style: AppTypography.caption.copyWith(color: context.colors.textSecondary, height: 1.5),
                      ),
                      SizedBox(height: AppSpacing.sectionGap),

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
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(top: BorderSide(color: context.colors.border, width: 1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: AnimatedActionIcon(
                            icon: LucideIcons.heart,
                            activeIcon: LucideIcons.heart, // Consider using a filled heart if available
                            isActive: isLiked,
                            inactiveColor: context.colors.primary,
                            activeColor: context.colors.error,
                            size: 16,
                          ),
                          label: Text(
                            isLiked ? 'Interested' : 'Interested',
                            style: TextStyle(color: context.colors.textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: context.colors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          onPressed: () {
                            ref.read(databaseProvider.notifier).toggleLikeProduct(product.id);
                          },
                        ),
                      ),
                      SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(LucideIcons.store, size: 16, color: context.colors.textPrimary),
                          label: Text('Visit Shop', style: TextStyle(color: context.colors.textPrimary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: context.colors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShopProfileScreen(shopId: shop.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  if (shop.isWhatsappVerified && shop.isWhatsappEnabled) ...[
                    SizedBox(height: AppSpacing.s12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(LucideIcons.messageCircle, color: Colors.white, size: 18),
                            label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                              ),
                            ),
                            onPressed: () async {
                              final text = Uri.encodeComponent('Hello ${shop.shopName}, I am interested in your product "${product.name}" that I saw on Locaro.');
                              final whatsappUrl = 'https://wa.me/${shop.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}?text=$text';
                              if (await canLaunchUrlString(whatsappUrl)) {
                                await launchUrlString(whatsappUrl);
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not launch WhatsApp')),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: context.colors.textSecondary),
              SizedBox(width: 6),
              Text(
                header,
                style: AppTypography.label.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.label.copyWith(
              color: context.colors.textPrimary,
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
