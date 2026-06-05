import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../providers/app_state_providers.dart';
import '../../products/presentation/product_details_screen.dart';
import '../../../models/product_model.dart';
import '../../../models/offer_model.dart';
import '../../../models/post_model.dart';
import '../../auth/application/auth_service.dart';


class ShopProfileScreen extends ConsumerStatefulWidget {
  final String shopId;

  const ShopProfileScreen({super.key, required this.shopId});

  @override
  ConsumerState<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends ConsumerState<ShopProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
    final shop = state.shops.firstWhere(
      (s) => s.id == widget.shopId,
      orElse: () => state.currentShop,
    );

    // Filter products, offers, and posts belonging to this shop
    final shopProducts = state.products.where((p) => p.shopId == shop.id).toList();
    final shopOffers = state.offers.where((o) => o.shopId == shop.id).toList();
    final shopPosts = state.posts.where((post) => post.shopId == shop.id).toList();

    final isFollowing = state.currentUser.followingShops.contains(shop.id);

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
                  child: Image.network(
                    shop.banner,
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
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.arrowLeft, size: 20, color: AppColors.primary),
                    ),
                  ),
                ),
                // Logo Positioned overlapping the banner bottom
                Positioned(
                  bottom: -35,
                  left: AppSpacing.mobilePadding,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(shop.logo),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

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
                        child: Text(
                          shop.shopName,
                          style: AppTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                  backgroundColor: AppColors.primary,
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
                                child: const Text(
                                  'Follow',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Category & Stats Row
                  Row(
                    children: [
                      Text(shop.category, style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('${shop.rating} rating', style: AppTypography.label.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('${shop.followers} followers', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  
                  Text(
                    shop.description,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop.address,
                          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
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
                    return const SizedBox();
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
      return _buildEmptyTab('No active products posted by this merchant.');
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
                  child: Image.network(
                    p.images.first,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                p.name,
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '₹${p.discountPrice?.toStringAsFixed(0) ?? p.price.toStringAsFixed(0)}',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOffersTab(BuildContext context, List<OfferModel> offers) {
    if (offers.isEmpty) {
      return _buildEmptyTab('No custom discount offers currently running.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      itemCount: offers.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s12),
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
                          color: AppColors.offerOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          o.discount,
                          style: AppTypography.label.copyWith(
                            color: AppColors.offerOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(o.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(o.description, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostsTab(BuildContext context, List<PostModel> posts) {
    if (posts.isEmpty) {
      return _buildEmptyTab('No updates shared yet.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s16),
      itemBuilder: (context, index) {
        final post = posts[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: Image.network(post.image, fit: BoxFit.cover, width: double.infinity, height: 200),
            ),
            const SizedBox(height: 8),
            Text(
              post.caption,
              style: AppTypography.caption.copyWith(height: 1.4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.heart, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${post.likes} likes', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewsTab(BuildContext context) {
    final List<Map<String, dynamic>> mockReviews = [
      {'name': 'Ramesh Kumar', 'rating': 5, 'text': 'Amazing service, friendly staff. Highly recommended!'},
      {'name': 'Preeti Sen', 'rating': 4, 'text': 'Great quality organic products, slightly priced but worth it.'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      itemCount: mockReviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) {
        final r = mockReviews[index];
        return BaseCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r['name'], style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                    Row(
                      children: List.generate(
                        r['rating'],
                        (index) => const Icon(LucideIcons.star, size: 12, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(r['text'], style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTab(String msg) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
