import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/common/offer_badge.dart';
import '../../../core/widgets/navigation/top_app_bar.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/post_model.dart';
import '../../../models/lead_model.dart';
import '../../../models/product_model.dart';
import '../../../models/offer_model.dart';
import '../../queries/presentation/query_bottom_sheet.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import '../../auth/application/auth_service.dart';
import '../../../core/widgets/common/skeleton_loaders.dart';
import '../../../core/widgets/common/animated_action_icon.dart';
import '../application/home_feed_provider.dart';
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 5;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });
        if (mounted) {
          setState(() {
            _visibleCount += 5;
            _isLoadingMore = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseProvider);
    final shops = state.shops;
    final products = state.products;

    if (shops.isEmpty) {
      return Scaffold(
        appBar: const TopAppBar(),
        body: ListView.separated(
          itemCount: 3,
          separatorBuilder: (context, index) =>
              Container(height: 8, color: context.colors.border),
          itemBuilder: (context, index) => const FeedSkeletonCard(),
        ),
      );
    }

    final feedItems = ref.watch(homeFeedProvider);

    return Scaffold(
      appBar: const TopAppBar(),
      body: feedItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.newspaper, size: 64, color: context.colors.border),
                  SizedBox(height: AppSpacing.s16),
                  Text(
                    'No Updates Yet',
                    style: AppTypography.heading.copyWith(color: context.colors.textPrimary),
                  ),
                  SizedBox(height: AppSpacing.s8),
                  Text(
                    'Follow shops to see their updates here.',
                    style: AppTypography.body.copyWith(color: context.colors.textSecondary),
                  ),
                ],
              ),
            )
                  : RefreshIndicator(
                      onRefresh: () async {
                        // data refreshes instantly
                      },
                      child: ListView.separated(
                        key: const PageStorageKey('home_feed'),
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: AppSpacing.s24),
                        itemCount: feedItems.length > _visibleCount 
                            ? _visibleCount + (_isLoadingMore ? 1 : 0) 
                            : feedItems.length,
                        separatorBuilder: (context, index) =>
                            Container(height: 8, color: context.colors.border),
                        itemBuilder: (context, index) {
                          if (index == _visibleCount && _isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          final feedItem = feedItems[index];
                  final shop = shops.firstWhere(
                    (s) => s.id == feedItem.shopId,
                    orElse: () => state.currentShop,
                  );
                  final distanceText = '${feedItem.distance.toStringAsFixed(1)} km away';

                  if (feedItem.type == FeedItemType.post) {
                    final post = feedItem.item as PostModel;
                    // Find product if linked
                    ProductModel? linkedProduct;
                    try {
                      linkedProduct = products.firstWhere(
                        (p) => p.shopId == shop.id,
                      );
                    } catch (_) {}

                    return _FeedCard(
                      post: post,
                      shopName: shop.shopName,
                      shopLogo: shop.logo,
                      distance: distanceText,
                      linkedProduct: linkedProduct,
                      onShopTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ShopProfileScreen(shopId: shop.id),
                          ),
                        );
                      },
                    );
                  } else if (feedItem.type == FeedItemType.product) {
                    final product = feedItem.item as ProductModel;
                    return _ProductFeedCard(
                      product: product,
                      shopName: shop.shopName,
                      shopLogo: shop.logo,
                      distance: distanceText,
                      onShopTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ShopProfileScreen(shopId: shop.id),
                          ),
                        );
                      },
                    );
                  } else {
                    final offer = feedItem.item as OfferModel;
                    return _OfferFeedCard(
                      offer: offer,
                      shopName: shop.shopName,
                      shopLogo: shop.logo,
                      distance: distanceText,
                      onShopTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ShopProfileScreen(shopId: shop.id),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
    );
  }
}

// ==========================================
// --- POST CARD IN FEED ---
// ==========================================
class _FeedCard extends ConsumerStatefulWidget {
  final PostModel post;
  final String shopName;
  final String shopLogo;
  final String distance;
  final ProductModel? linkedProduct;
  final VoidCallback onShopTap;

  const _FeedCard({
    required this.post,
    required this.shopName,
    required this.shopLogo,
    required this.distance,
    required this.linkedProduct,
    required this.onShopTap,
  });

  @override
  ConsumerState<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends ConsumerState<_FeedCard> {
  bool? _localIsLiked;
  bool? _localIsSaved;

  bool get _isLiked {
    final dbState = ref.read(databaseProvider);
    return _localIsLiked ?? dbState.currentUser.likedPosts.contains(widget.post.id);
  }

  bool get _isSaved {
    if (widget.linkedProduct == null) return false;
    final dbState = ref.read(databaseProvider);
    return _localIsSaved ?? dbState.currentUser.savedProducts.contains(widget.linkedProduct!.id);
  }

  void _triggerLike() {
    ref.read(authServiceProvider).checkGuest(
          context,
          onAllowed: () {
            setState(() {
              _localIsLiked = !_isLiked;
            });
            ref.read(databaseProvider.notifier).toggleLikePost(widget.post.id);
          },
        );
  }

  void _triggerSave() {
    if (widget.linkedProduct == null) return;
    ref.read(authServiceProvider).checkGuest(
          context,
          onAllowed: () {
            final wasSaved = _isSaved;
            setState(() {
              _localIsSaved = !wasSaved;
            });
            ref.read(databaseProvider.notifier).toggleSaveProduct(widget.linkedProduct!.id);
            if (!wasSaved) {
              _generateLead(LeadType.saved, 'Product Saved');
            }
          },
        );
  }

  void _generateLead(LeadType type, String typeLabel) {
    if (widget.linkedProduct == null) return;

    ref.read(authServiceProvider).checkGuest(
          context,
          onAllowed: () {
            final dbState = ref.read(databaseProvider);
            final newLead = LeadModel(
              id: 'lead_${dbState.currentUser.id}_${widget.linkedProduct!.id}_${type.name}',
              userId: dbState.currentUser.id,
              userName: dbState.currentUser.name,
              userPhone: dbState.currentUser.phone,
              productId: widget.linkedProduct!.id,
              productName: widget.linkedProduct!.name,
              shopId: widget.post.shopId,
              type: type,
              status: 'New',
              createdAt: DateTime.now(),
            );

            ref.read(databaseProvider.notifier).addLead(newLead);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Simulated Lead: $typeLabel generated for ${widget.shopName}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(databaseProvider);
    final isSaved = _isSaved;
    final isLiked = _isLiked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Info Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mobilePadding,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onShopTap,
                child: FallbackAvatar(
                  imageUrl: widget.shopLogo,
                  radius: 18,
                  fallbackIcon: LucideIcons.store,
                ),
              ),
              SizedBox(width: AppSpacing.s12),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onShopTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shopName,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.navigation,
                            size: 10,
                            color: context.colors.textSecondary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            widget.distance,
                            style: AppTypography.label.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.moreHorizontal, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Large Image Container with Double Tap to Like
        GestureDetector(
          onDoubleTap: _triggerLike,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.1,
                child: FallbackImage(
                  imageUrl: widget.post.image,
                  fit: BoxFit.cover,
                  fallbackIcon: LucideIcons.image,
                ),
              ),
              if (widget.post.type == PostType.offer)
                const Positioned(
                  top: AppSpacing.s16,
                  right: AppSpacing.s16,
                  child: OfferBadge(text: 'Offer Active'),
                ),
            ],
          ),
        ),

        // Actions Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              IconButton(
                icon: AnimatedActionIcon(
                  icon: Icons.favorite_border,
                  activeIcon: Icons.favorite,
                  isActive: isLiked,
                  inactiveColor: context.colors.primary,
                  activeColor: context.colors.error,
                  size: 24,
                ),
                onPressed: _triggerLike,
              ),
              IconButton(
                icon: const Icon(LucideIcons.messageCircle),
                onPressed: () {
                  showQueryBottomSheet(
                    context,
                    shopId: widget.post.shopId,
                    productId: widget.linkedProduct?.id,
                    category: widget.linkedProduct?.category ?? 'OFFERS',
                  );
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.send),
                onPressed: () {
                  _generateLead(LeadType.callClick, 'Share Link click');
                },
              ),
              const Spacer(),
              if (widget.linkedProduct != null)
                IconButton(
                  icon: AnimatedActionIcon(
                    icon: Icons.bookmark_border,
                    activeIcon: Icons.bookmark,
                    isActive: isSaved,
                    inactiveColor: context.colors.textSecondary,
                    activeColor: context.colors.primary,
                    size: 24,
                  ),
                  onPressed: _triggerSave,
                ),
            ],
          ),
        ),

        // Content Details
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mobilePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.linkedProduct != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.linkedProduct!.name,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '₹${widget.linkedProduct!.discountPrice?.toStringAsFixed(0) ?? widget.linkedProduct!.price.toStringAsFixed(0)}',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.s8),
              ],
              Text(
                widget.post.caption,
                style: AppTypography.caption.copyWith(height: 1.4),
              ),
              SizedBox(height: AppSpacing.s12),

              // Sticky actions for Leads generation
              if (widget.linkedProduct != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          LucideIcons.store,
                          size: 14,
                          color: context.colors.textPrimary,
                        ),
                        label: Text(
                          'Visit Shop',
                          style: TextStyle(color: context.colors.textPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: context.colors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                        ),
                        onPressed: widget.onShopTap,
                      ),
                    ),
                    SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          LucideIcons.messageSquare,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Message Shop',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                        ),
                        onPressed: () {
                          showQueryBottomSheet(
                            context,
                            shopId: widget.post.shopId,
                            productId: widget.linkedProduct?.id,
                            category: widget.linkedProduct?.category ?? 'OFFERS',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.s12),
              ],

              Text(
                'SHOP UPDATE',
                style: AppTypography.label.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// --- PRODUCT CARD IN FEED ---
// ==========================================
class _ProductFeedCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final String shopName;
  final String shopLogo;
  final String distance;
  final VoidCallback onShopTap;

  const _ProductFeedCard({
    required this.product,
    required this.shopName,
    required this.shopLogo,
    required this.distance,
    required this.onShopTap,
  });

  @override
  ConsumerState<_ProductFeedCard> createState() => _ProductFeedCardState();
}

class _ProductFeedCardState extends ConsumerState<_ProductFeedCard> {
  bool? _localIsLiked;
  bool? _localIsSaved;

  bool get _isLiked {
    final dbState = ref.read(databaseProvider);
    return _localIsLiked ?? dbState.currentUser.likedProducts.contains(widget.product.id);
  }

  bool get _isSaved {
    final dbState = ref.read(databaseProvider);
    return _localIsSaved ?? dbState.currentUser.savedProducts.contains(widget.product.id);
  }

  void _triggerLike() {
    ref.read(authServiceProvider).checkGuest(
          context,
          onAllowed: () {
            setState(() {
              _localIsLiked = !_isLiked;
            });
            ref.read(databaseProvider.notifier).toggleLikeProduct(widget.product.id);
          },
        );
  }

  void _triggerSave() {
    ref.read(authServiceProvider).checkGuest(
          context,
          onAllowed: () {
            final wasSaved = _isSaved;
            setState(() {
              _localIsSaved = !wasSaved;
            });
            ref.read(databaseProvider.notifier).toggleSaveProduct(widget.product.id);
            if (!wasSaved) {
              _generateLead(LeadType.saved, 'Product Bookmarked');
            }
          },
        );
  }

  void _generateLead(LeadType type, String typeLabel) {
    ref.read(authServiceProvider).checkGuest(
          context,
          onAllowed: () {
            final dbState = ref.read(databaseProvider);
            final newLead = LeadModel(
              id: 'lead_${dbState.currentUser.id}_${widget.product.id}_${type.name}',
              userId: dbState.currentUser.id,
              userName: dbState.currentUser.name,
              userPhone: dbState.currentUser.phone,
              productId: widget.product.id,
              productName: widget.product.name,
              shopId: widget.product.shopId,
              type: type,
              status: 'New',
              createdAt: DateTime.now(),
            );

            ref.read(databaseProvider.notifier).addLead(newLead);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Simulated Lead: $typeLabel generated for ${widget.shopName}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(databaseProvider);
    final isSaved = _isSaved;
    final isLiked = _isLiked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Info Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mobilePadding,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onShopTap,
                child: FallbackAvatar(
                  imageUrl: widget.shopLogo,
                  radius: 18,
                  fallbackIcon: LucideIcons.store,
                ),
              ),
              SizedBox(width: AppSpacing.s12),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onShopTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shopName,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.navigation,
                            size: 10,
                            color: context.colors.textSecondary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            widget.distance,
                            style: AppTypography.label.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.moreHorizontal, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Product Image Container with Double Tap to Like
        GestureDetector(
          onDoubleTap: _triggerLike,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.1,
                child: FallbackImage(
                  imageUrl: widget.product.images.isNotEmpty ? widget.product.images.first : '',
                  fit: BoxFit.cover,
                  fallbackIcon: LucideIcons.image,
                ),
              ),
              Positioned(
                top: AppSpacing.s16,
                right: AppSpacing.s16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'NEW PRODUCT',
                    style: AppTypography.label.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Actions Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              IconButton(
                icon: AnimatedActionIcon(
                  icon: Icons.favorite_border,
                  activeIcon: Icons.favorite,
                  isActive: isLiked,
                  inactiveColor: context.colors.primary,
                  activeColor: context.colors.error,
                  size: 24,
                ),
                onPressed: _triggerLike,
              ),
              IconButton(
                icon: const Icon(LucideIcons.messageCircle),
                onPressed: () {
                  showQueryBottomSheet(
                    context,
                    shopId: widget.product.shopId,
                    productId: widget.product.id,
                    category: widget.product.category,
                  );
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.send),
                onPressed: () {
                  _generateLead(LeadType.callClick, 'Share Product click');
                },
              ),
              const Spacer(),
              IconButton(
                icon: AnimatedActionIcon(
                  icon: Icons.bookmark_border,
                  activeIcon: Icons.bookmark,
                  isActive: isSaved,
                  inactiveColor: context.colors.textSecondary,
                  activeColor: context.colors.primary,
                  size: 24,
                ),
                onPressed: _triggerSave,
              ),
            ],
          ),
        ),

        // Content Details
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mobilePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.product.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.product.discountPrice != null) ...[
                        Text(
                          '₹${widget.product.price.toStringAsFixed(0)}',
                          style: AppTypography.caption.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 6),
                      ],
                      Text(
                        '₹${widget.product.discountPrice?.toStringAsFixed(0) ?? widget.product.price.toStringAsFixed(0)}',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s8),
              Text(
                widget.product.description,
                style: AppTypography.caption.copyWith(height: 1.4),
              ),
              SizedBox(height: AppSpacing.s12),

              // Sticky actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        LucideIcons.store,
                        size: 14,
                        color: context.colors.textPrimary,
                      ),
                      label: Text(
                        'Visit Shop',
                        style: TextStyle(color: context.colors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: context.colors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.buttonRadius,
                          ),
                        ),
                      ),
                      onPressed: widget.onShopTap,
                    ),
                  ),
                  SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        LucideIcons.messageSquare,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Message Shop',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.buttonRadius,
                          ),
                        ),
                      ),
                      onPressed: () {
                        showQueryBottomSheet(
                          context,
                          shopId: widget.product.shopId,
                          productId: widget.product.id,
                          category: widget.product.category,
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s12),

              Text(
                'PRODUCT RECOMMENDATION',
                style: AppTypography.label.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// --- OFFER CARD IN FEED ---
// ==========================================
class _OfferFeedCard extends ConsumerStatefulWidget {
  final OfferModel offer;
  final String shopName;
  final String shopLogo;
  final String distance;
  final VoidCallback onShopTap;

  const _OfferFeedCard({
    required this.offer,
    required this.shopName,
    required this.shopLogo,
    required this.distance,
    required this.onShopTap,
  });

  @override
  ConsumerState<_OfferFeedCard> createState() => _OfferFeedCardState();
}

class _OfferFeedCardState extends ConsumerState<_OfferFeedCard>
    with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  late AnimationController _likeController;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _likeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_likeController);
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _triggerLike() {
    ref.read(authServiceProvider).checkGuest(
          context,
          onAllowed: () {
            setState(() => _isLiked = !_isLiked);
            if (_isLiked) {
              _likeController.forward(from: 0.0);
            }
          },
        );
  }

  void _generateLead(LeadType type, String typeLabel) {
    ref.read(authServiceProvider).checkGuest(
          context,
          onAllowed: () {
            final dbState = ref.read(databaseProvider);
            final newLead = LeadModel(
              id: 'lead_${dbState.currentUser.id}_${widget.offer.id}_${type.name}',
              userId: dbState.currentUser.id,
              userName: dbState.currentUser.name,
              userPhone: dbState.currentUser.phone,
              productId: widget.offer.id,
              productName: widget.offer.title,
              shopId: widget.offer.shopId,
              type: type,
              status: 'New',
              createdAt: DateTime.now(),
            );

            ref.read(databaseProvider.notifier).addLead(newLead);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Simulated Lead: $typeLabel generated for ${widget.shopName}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Info Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mobilePadding,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onShopTap,
                child: FallbackAvatar(
                  imageUrl: widget.shopLogo,
                  radius: 18,
                  fallbackIcon: LucideIcons.store,
                ),
              ),
              SizedBox(width: AppSpacing.s12),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onShopTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shopName,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.navigation,
                            size: 10,
                            color: context.colors.textSecondary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            widget.distance,
                            style: AppTypography.label.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.moreHorizontal, size: 20),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Offer Banner Container with Double Tap to Like
        GestureDetector(
          onDoubleTap: _triggerLike,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.1,
                child: FallbackImage(
                  imageUrl: widget.offer.banner,
                  fit: BoxFit.cover,
                  fallbackIcon: LucideIcons.image,
                ),
              ),
              Positioned(
                top: AppSpacing.s16,
                right: AppSpacing.s16,
                child: OfferBadge(text: widget.offer.discount),
              ),
            ],
          ),
        ),

        // Actions Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              ScaleTransition(
                scale: _likeScale,
                child: IconButton(
                  icon: Icon(
                    _isLiked ? LucideIcons.heart : LucideIcons.heart,
                    color: _isLiked ? context.colors.error : context.colors.primary,
                  ),
                  onPressed: _triggerLike,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.messageCircle),
                onPressed: () {
                  showQueryBottomSheet(
                    context,
                    shopId: widget.offer.shopId,
                    category: 'OFFERS',
                  );
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.send),
                onPressed: () {
                  _generateLead(LeadType.callClick, 'Share Offer click');
                },
              ),
            ],
          ),
        ),

        // Content Details
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mobilePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.offer.title,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppSpacing.s8),
              Text(
                widget.offer.description,
                style: AppTypography.caption.copyWith(height: 1.4),
              ),
              SizedBox(height: AppSpacing.s12),

              // Sticky actions for claim coupon
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        LucideIcons.ticket,
                        size: 14,
                        color: context.colors.offerOrange,
                      ),
                      label: Text(
                        'Claim Coupon',
                        style: TextStyle(color: context.colors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: context.colors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.buttonRadius,
                          ),
                        ),
                      ),
                      onPressed: () => _generateLead(
                        LeadType.interested,
                        'Claimed Coupon',
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        LucideIcons.messageSquare,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Message Shop',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.buttonRadius,
                          ),
                        ),
                      ),
                      onPressed: () {
                        showQueryBottomSheet(
                          context,
                          shopId: widget.offer.shopId,
                          category: 'OFFERS',
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.s12),

              Text(
                'PROMOTIONAL OFFER',
                style: AppTypography.label.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ],
    );
  }
}
