import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../providers/app_state_providers.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../products/presentation/product_details_screen.dart';
import '../../map/presentation/map_screen.dart';
import '../../../models/product_model.dart';
import '../../../models/offer_model.dart';
import '../../../models/post_model.dart';
import '../../auth/application/auth_service.dart';
import '../../../core/widgets/common/skeleton_loaders.dart';
import 'package:url_launcher/url_launcher_string.dart';


class ShopProfileScreen extends ConsumerStatefulWidget {
  final String shopId;

  const ShopProfileScreen({super.key, required this.shopId});

  @override
  ConsumerState<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends ConsumerState<ShopProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _isLoading = false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseProvider);
    // Find the active shop
    final shop = state.shops.where((s) => s.id == widget.shopId).firstOrNull;
    
    if (shop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_outlined, size: 64, color: context.colors.textSecondary),
              SizedBox(height: 16),
              Text('This shop no longer exists.'),
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Go Back')),
            ],
          ),
        ),
      );
    }
    final shopProducts = state.products.where((p) => p.shopId == shop.id).toList();
    final shopOffers = state.offers.where((o) => o.shopId == shop.id).toList();
    final shopPosts = state.posts.where((post) => post.shopId == shop.id).toList();

    final isFollowing = state.currentUser.followingShops.contains(shop.id);

    if (_isLoading) {
      return const Scaffold(
        body: SingleChildScrollView(
          child: ShopProfileSkeleton(),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner & Header Stack
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: FallbackImage(
                    imageUrl: shop.banner,
                    fit: BoxFit.cover,
                  ),
                ),
                // Back Button
                Positioned(
                  top: 50,
                  left: AppSpacing.mobilePadding,
                  child: GestureDetector(
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
                ),
                // Map Button
                Positioned(
                  top: 50,
                  right: AppSpacing.mobilePadding + 44, // offset to the left of the WhatsApp button
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapScreen(initialShopId: shop.id),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.mapPin, size: 20, color: context.colors.primary),
                    ),
                  ),
                ),
                // WhatsApp Button
                Positioned(
                  top: 50,
                  right: AppSpacing.mobilePadding,
                  child: GestureDetector(
                    onTap: () async {
                      final whatsappUrl = 'https://wa.me/${shop.whatsapp.replaceAll(RegExp(r'[^0-9]'), '')}';
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
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.messageCircle, size: 20, color: Colors.white),
                    ),
                  ),
                ),

                // Logo Positioned overlapping the banner bottom
                Positioned(
                  bottom: -35,
                  left: AppSpacing.mobilePadding,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      shape: BoxShape.circle,
                    ),
                    child: FallbackAvatar(
                      imageUrl: shop.logo,
                      name: shop.shopName,
                      radius: 35,
                      fallbackIcon: LucideIcons.store,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 48),

            // Shop Metadata
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.shopName,
                              style: AppTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
                            ),
                            if (shop.showOnlineStatus) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: shop.isOnline ? context.colors.success : context.colors.textSecondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    shop.isOnline ? 'Online Now' : 'Currently Offline',
                                    style: AppTypography.label.copyWith(
                                      color: shop.isOnline ? context.colors.success : context.colors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        height: 38,
                        child: isFollowing
                            ? SecondaryButton(
                                text: 'Following',
                                onPressed: () {
                                  ref.read(authServiceProvider).checkGuest(context, onAllowed: () {
                                    ref.read(databaseProvider.notifier).toggleFollowShop(shop.id);
                                  });
                                },
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.colors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  ref.read(authServiceProvider).checkGuest(context, onAllowed: () {
                                    ref.read(databaseProvider.notifier).toggleFollowShop(shop.id);
                                  });
                                },
                                child: Text(
                                  'Follow',
                                  style: TextStyle(color: context.colors.surface, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  
                  // Category & Stats Wrap to prevent overflow
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        shop.category, 
                        style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${shop.rating} rating', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text('${shop.followers} followers', style: AppTypography.label.copyWith(color: context.colors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s12),
                  
                  Text(
                    shop.description,
                    style: AppTypography.caption.copyWith(color: context.colors.textSecondary, height: 1.4),
                  ),
                  SizedBox(height: AppSpacing.s16),
                  
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 14, color: context.colors.textSecondary),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop.address,
                          style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.sectionGap),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: context.colors.primary,
              unselectedLabelColor: context.colors.textSecondary,
              indicatorColor: context.colors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Offers'),
                Tab(text: 'Posts'),
                Tab(text: 'Reviews'),
              ],
            ),

            // Tab Bar View content rendered directly in column to avoid height calculation issues
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                switch (_tabController.index) {
                  case 0:
                    return _buildProductsTab(context, shopProducts);
                  case 1:
                    return _buildOffersTab(context, shopOffers);
                  case 2:
                    return _buildPostsTab(context, shopPosts);
                  case 3:
                    return _buildReviewsTab(context);
                  default:
                    return SizedBox();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB SUB-PAGES ---

  Widget _buildProductsTab(BuildContext context, List<ProductModel> products) {
    if (products.isEmpty) {
      return _buildEmptyTab('No active products posted by this merchant.', LucideIcons.packageOpen);
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.s16,
        crossAxisSpacing: AppSpacing.s16,
        childAspectRatio: 0.78,
      ),
      itemCount: products.length,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
              SizedBox(height: 2),
              Text(
                '₹${p.discountPrice?.toStringAsFixed(0) ?? p.price.toStringAsFixed(0)}',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: context.colors.primary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOffersTab(BuildContext context, List<OfferModel> offers) {
    if (offers.isEmpty) {
      return _buildEmptyTab('No custom discount offers currently running.', LucideIcons.tag);
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      itemCount: offers.length,
      separatorBuilder: (context, index) => SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) {
        final o = offers[index];
        return BaseCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.offerOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          o.discount,
                          style: AppTypography.label.copyWith(
                            color: context.colors.offerOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(o.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(o.description, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: context.colors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostsTab(BuildContext context, List<PostModel> posts) {
    if (posts.isEmpty) {
      return _buildEmptyTab('No updates shared yet.', LucideIcons.newspaper);
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      itemCount: posts.length,
      separatorBuilder: (context, index) => SizedBox(height: AppSpacing.s16),
      itemBuilder: (context, index) {
        final post = posts[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: FallbackImage(
                imageUrl: post.image,
                fit: BoxFit.cover, 
                width: double.infinity, 
                height: 200,
              ),
            ),
            SizedBox(height: 8),
            Text(
              post.caption,
              style: AppTypography.caption.copyWith(height: 1.4),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.heart, size: 14, color: context.colors.textSecondary),
                SizedBox(width: 4),
                Text('${post.likes} likes', style: AppTypography.label.copyWith(color: context.colors.textSecondary)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: AppSpacing.mobilePadding),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.border.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.messageSquare,
                size: 40,
                color: context.colors.secondary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Customers haven\'t left any reviews for this shop yet.',
              style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTab(String msg, [IconData? icon]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: AppSpacing.mobilePadding),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.border.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: context.colors.secondary,
                ),
              ),
              SizedBox(height: 16),
            ],
            Text(
              msg,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
