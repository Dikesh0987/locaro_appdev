import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locaro/models/shop_model.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/common/offer_badge.dart';
import '../../../core/widgets/navigation/top_app_bar.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../core/utils/time_ago.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/post_model.dart';
import '../../../models/product_model.dart';
import '../../../models/offer_model.dart';
import '../../queries/presentation/query_bottom_sheet.dart';
import '../../queries/presentation/whatsapp_inquiry_bottom_sheet.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import 'comments_bottom_sheet.dart';
import '../../auth/application/auth_service.dart';
import '../../../core/widgets/common/skeleton_loaders.dart';
import '../../../core/widgets/common/animated_action_icon.dart';
import '../../../core/utils/page_transitions.dart';
import '../application/home_feed_provider.dart';
import '../../../core/widgets/animations/fade_in_slide.dart';
import '../../products/presentation/product_details_screen.dart';
import 'package:share_plus/share_plus.dart';

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

    if (state.isLoading) {
      return Scaffold(
        appBar: const TopAppBar(),
        body: ListView.separated(
          itemCount: 3,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 8),
          itemBuilder: (context, index) => const FeedSkeletonCard(),
        ),
      );
    }

    final feedItems = ref.watch(homeFeedProvider);

    return Scaffold(
      appBar: const TopAppBar(),
      body: feedItems.isEmpty
          ? _EmptyFeedState(
              onExploreTap: () {
                ref.read(bottomNavIndexProvider.notifier).state = 1;
              },
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
                    Container(
                      height: 8,
                      color: context.colors.border.withValues(alpha: 0.2),
                    ),
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
                  final distanceText = '${feedItem.distance.toStringAsFixed(1)} km';

                  if (feedItem.type == FeedItemType.post) {
                    final post = feedItem.item as PostModel;
                    // Find product if linked
                    ProductModel? linkedProduct;
                    try {
                      linkedProduct = products.firstWhere(
                        (p) => p.shopId == shop.id,
                      );
                    } catch (_) {}

                    return FadeInSlide(
                      index: index,
                      child: _FeedCard(
                        post: post,
                        shopName: shop.shopName,
                        shopLogo: shop.logo,
                        distance: distanceText,
                        linkedProduct: linkedProduct,
                        onShopTap: () {
                          Navigator.push(
                            context,
                            SlidePageRoute(
                              page:
                                  ShopProfileScreen(shopId: shop.id),
                            ),
                          );
                        },
                      ),
                    );
                  } else if (feedItem.type == FeedItemType.product) {
                    final product = feedItem.item as ProductModel;
                    return FadeInSlide(
                      index: index,
                      child: _ProductFeedCard(
                        product: product,
                        shop: shop,
                        distance: distanceText,
                        onShopTap: () {
                          Navigator.push(
                            context,
                            SlidePageRoute(
                              page:
                                  ShopProfileScreen(shopId: shop.id),
                            ),
                          );
                        },
                      ),
                    );
                  } else {
                    final offer = feedItem.item as OfferModel;
                    return FadeInSlide(
                      index: index,
                      child: _OfferFeedCard(
                        offer: offer,
                        shopName: shop.shopName,
                        shopLogo: shop.logo,
                        distance: distanceText,
                        onShopTap: () {
                          Navigator.push(
                            context,
                            SlidePageRoute(
                              page:
                                  ShopProfileScreen(shopId: shop.id),
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ),
    );
  }
}

// ==========================================
// --- EMPTY FEED STATE ---
// ==========================================
class _EmptyFeedState extends StatelessWidget {
  final VoidCallback onExploreTap;

  const _EmptyFeedState({required this.onExploreTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: context.colors.border,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.compass,
                size: 40,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Your Feed is Empty',
              style: AppTypography.heading.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Follow nearby shops to see their latest\nproducts, offers, and updates here.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: context.colors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(LucideIcons.compass, size: 16, color: context.colors.surface),
                label: Text(
                  'Explore Nearby Shops',
                  style: TextStyle(
                    color: context.colors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                onPressed: onExploreTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// --- SHARED SHOP HEADER WIDGET ---
// ==========================================
class _ShopHeader extends StatelessWidget {
  final String shopName;
  final String shopLogo;
  final String distance;
  final String timeAgoText;
  final VoidCallback onShopTap;

  const _ShopHeader({
    required this.shopName,
    required this.shopLogo,
    required this.distance,
    required this.timeAgoText,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.mobilePadding,
        vertical: AppSpacing.s12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onShopTap,
            child: FallbackAvatar(
              imageUrl: shopLogo,
              name: shopName,
              radius: 20,
              fallbackIcon: LucideIcons.store,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: GestureDetector(
              onTap: onShopTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 10,
                        color: context.colors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        distance,
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
          Text(
            timeAgoText,
            style: AppTypography.label.copyWith(
              color: context.colors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// --- EXPANDABLE CAPTION ---
// ==========================================
class _ExpandableCaption extends StatefulWidget {
  final String text;
  final int maxLines;

  const _ExpandableCaption({
    required this.text,
  }) : maxLines = 2;

  @override
  State<_ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<_ExpandableCaption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.text,
          style: AppTypography.caption.copyWith(
            height: 1.4,
            color: context.colors.textPrimary,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        if (!isOverflowing) {
          return Text(
            widget.text,
            style: AppTypography.caption.copyWith(
              height: 1.4,
              color: context.colors.textPrimary,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : widget.maxLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                height: 1.4,
                color: context.colors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _expanded = !_expanded);
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'Read less' : 'Read more',
                      style: AppTypography.caption.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 14,
                      color: context.colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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

          },
        );
  }


  @override
  Widget build(BuildContext context) {
    ref.watch(databaseProvider);
    final isSaved = _isSaved;
    final isLiked = _isLiked;
    final shop = ref.read(databaseProvider).shops.firstWhere(
      (s) => s.id == widget.post.shopId,
      orElse: () => ref.read(databaseProvider).currentShop,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Info Header
        _ShopHeader(
          shopName: widget.shopName,
          shopLogo: widget.shopLogo,
          distance: widget.distance,
          timeAgoText: timeAgo(widget.post.createdAt),
          onShopTap: widget.onShopTap,
        ),

        // Large Image Container with Double Tap to Like
        GestureDetector(
          onDoubleTap: _triggerLike,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.1,
                child: Hero(
                  tag: 'post_${widget.post.id}_image',
                  child: FallbackImage(
                    imageUrl: widget.post.image,
                    fit: BoxFit.cover,
                    fallbackIcon: LucideIcons.image,
                  ),
                ),
              ),
              // Bottom gradient overlay for readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
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

        // Compact Actions Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: 6.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _triggerLike,
                child: AnimatedActionIcon(
                  icon: Icons.favorite_border,
                  activeIcon: Icons.favorite,
                  isActive: isLiked,
                  inactiveColor: context.colors.primary,
                  activeColor: context.colors.error,
                  size: 22,
                ),
              ),
              if (widget.post.likes > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${widget.post.likes}',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  showCommentsBottomSheet(
                    context,
                    itemId: widget.post.id,
                  );
                },
                child: Icon(LucideIcons.messageCircle, size: 20, color: context.colors.textSecondary),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  final text = widget.linkedProduct != null
                      ? 'Check out ${widget.linkedProduct!.name} from ${widget.shopName} on Locaro!\n\n${widget.post.caption}'
                      : 'Check out this update from ${widget.shopName} on Locaro!\n\n${widget.post.caption}';
                  SharePlus.instance.share(ShareParams(text: text));
                },
                child: Icon(LucideIcons.send, size: 20, color: context.colors.textSecondary),
              ),
              const Spacer(),
              if (widget.linkedProduct != null)
                GestureDetector(
                  onTap: _triggerSave,
                  child: AnimatedActionIcon(
                    icon: Icons.bookmark_border,
                    activeIcon: Icons.bookmark,
                    isActive: isSaved,
                    inactiveColor: context.colors.textSecondary,
                    activeColor: context.colors.primary,
                    size: 22,
                  ),
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
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: AppSpacing.s4),
              ],
              _ExpandableCaption(text: widget.post.caption),
              const SizedBox(height: AppSpacing.s12),

              // Compact CTA buttons
              if (widget.linkedProduct != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _CompactOutlineButton(
                        icon: LucideIcons.store,
                        label: 'Visit Shop',
                        onTap: widget.onShopTap,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    if (shop.whatsapp.isNotEmpty && shop.isWhatsappEnabled) ...[
                      Expanded(
                        child: _CompactFilledButton(
                          icon: LucideIcons.messageCircle,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () {
                            showWhatsAppInquirySheet(
                              context,
                              shop: shop,
                              product: widget.linkedProduct,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                    ],
                    Expanded(
                      child: _CompactFilledButton(
                        icon: LucideIcons.messageSquare,
                        label: 'Enquire',
                        color: context.colors.primary,
                        onTap: () {
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
              ],
              const SizedBox(height: AppSpacing.s16),
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
  final ShopModel shop;
  final String distance;
  final VoidCallback onShopTap;

  const _ProductFeedCard({
    required this.product,
    required this.shop,
    required this.distance,
    required this.onShopTap,
  });

  @override
  ConsumerState<_ProductFeedCard> createState() => _ProductFeedCardState();
}

class _ProductFeedCardState extends ConsumerState<_ProductFeedCard> {
  bool? _localIsLiked;
  bool? _localIsSaved;
  int _currentImageIndex = 0;

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

          },
        );
  }


  @override
  Widget build(BuildContext context) {
    ref.watch(databaseProvider);
    final isSaved = _isSaved;
    final isLiked = _isLiked;
    final hasDiscount = widget.product.discountPrice != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Info Header
        _ShopHeader(
          shopName: widget.shop.shopName,
          shopLogo: widget.shop.logo,
          distance: widget.distance,
          timeAgoText: timeAgo(widget.product.createdAt),
          onShopTap: widget.onShopTap,
        ),

        // Product Image Container with Double Tap to Like
        GestureDetector(
          onDoubleTap: _triggerLike,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(productId: widget.product.id),
              ),
            );
          },
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.1,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: widget.product.images.isEmpty ? 1 : widget.product.images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final imageUrl = widget.product.images.isNotEmpty ? widget.product.images[index] : '';
                        final imageWidget = FallbackImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          fallbackIcon: LucideIcons.image,
                        );
                        
                        if (index == 0) {
                          return Hero(
                            tag: 'product_${widget.product.id}_image',
                            child: imageWidget,
                          );
                        }
                        return imageWidget;
                      },
                    ),
                    if (widget.product.images.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.product.images.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Bottom gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Badge
              if (hasDiscount)
                Positioned(
                  top: AppSpacing.s12,
                  right: AppSpacing.s12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.error,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${((1 - widget.product.discountPrice! / widget.product.price) * 100).round()}% OFF',
                      style: AppTypography.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  top: AppSpacing.s12,
                  right: AppSpacing.s12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.success,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'NEW',
                      style: AppTypography.label.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Compact Actions Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: 6.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _triggerLike,
                child: AnimatedActionIcon(
                  icon: Icons.favorite_border,
                  activeIcon: Icons.favorite,
                  isActive: isLiked,
                  inactiveColor: context.colors.primary,
                  activeColor: context.colors.error,
                  size: 22,
                ),
              ),
              if (widget.product.likes > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${widget.product.likes}',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  showCommentsBottomSheet(
                    context,
                    itemId: widget.product.id,
                  );
                },
                child: Icon(LucideIcons.messageCircle, size: 20, color: context.colors.textSecondary),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  final text = 'Check out ${widget.product.name} at ${widget.shop.shopName} on Locaro!\n\n${widget.product.description}';
                  SharePlus.instance.share(ShareParams(text: text));
                },
                child: Icon(LucideIcons.send, size: 20, color: context.colors.textSecondary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _triggerSave,
                child: AnimatedActionIcon(
                  icon: Icons.bookmark_border,
                  activeIcon: Icons.bookmark,
                  isActive: isSaved,
                  inactiveColor: context.colors.textSecondary,
                  activeColor: context.colors.primary,
                  size: 22,
                ),
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
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        const SizedBox(width: 6),
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
              const SizedBox(height: AppSpacing.s4),
              _ExpandableCaption(text: widget.product.description),
              const SizedBox(height: AppSpacing.s12),

              // Compact CTA actions
              Row(
                children: [
                  if (widget.shop.whatsapp.isNotEmpty && widget.shop.isWhatsappEnabled) ...[
                    Expanded(
                      child: _CompactFilledButton(
                        icon: LucideIcons.messageCircle,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () {
                          showWhatsAppInquirySheet(
                            context,
                            shop: widget.shop,
                            product: widget.product,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                  ],
                  Expanded(
                    child: _CompactOutlineButton(
                      icon: LucideIcons.messageSquare,
                      label: 'Ask Shop',
                      onTap: () {
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
              const SizedBox(height: AppSpacing.s16),
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


  @override
  Widget build(BuildContext context) {
    final dbState = ref.watch(databaseProvider);
    final shop = dbState.shops.firstWhere(
      (s) => s.id == widget.offer.shopId,
      orElse: () => dbState.currentShop,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Info Header
        _ShopHeader(
          shopName: widget.shopName,
          shopLogo: widget.shopLogo,
          distance: widget.distance,
          timeAgoText: timeAgo(widget.offer.createdAt),
          onShopTap: widget.onShopTap,
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
              // Bottom gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.s12,
                right: AppSpacing.s12,
                child: OfferBadge(text: widget.offer.discount),
              ),
            ],
          ),
        ),

        // Compact Actions Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: 6.0),
          child: Row(
            children: [
              ScaleTransition(
                scale: _likeScale,
                child: GestureDetector(
                  onTap: _triggerLike,
                  child: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 22,
                    color: _isLiked ? context.colors.error : context.colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  showCommentsBottomSheet(
                    context,
                    itemId: widget.offer.id,
                  );
                },
                child: Icon(LucideIcons.messageCircle, size: 20, color: context.colors.textSecondary),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  final text = 'Check out this offer on Locaro!\n\n${widget.offer.title}\n${widget.offer.description}';
                  SharePlus.instance.share(ShareParams(text: text));
                },
                child: Icon(LucideIcons.send, size: 20, color: context.colors.textSecondary),
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
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              _ExpandableCaption(text: widget.offer.description),
              const SizedBox(height: AppSpacing.s12),

              // Compact CTA actions
              Row(
                children: [
                  Expanded(
                    child: _CompactOutlineButton(
                      icon: LucideIcons.ticket,
                      label: 'Claim Coupon',
                      iconColor: context.colors.offerOrange,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  if (shop.whatsapp.isNotEmpty && shop.isWhatsappEnabled) ...[
                    Expanded(
                      child: _CompactFilledButton(
                        icon: LucideIcons.messageCircle,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () {
                          showWhatsAppInquirySheet(
                            context,
                            shop: shop,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                  ],
                  Expanded(
                    child: _CompactFilledButton(
                      icon: LucideIcons.messageSquare,
                      label: 'Enquire',
                      color: context.colors.primary,
                      onTap: () {
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
              const SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// --- SHARED COMPACT BUTTON WIDGETS ---
// ==========================================
class _CompactOutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CompactOutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        side: BorderSide(color: context.colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: iconColor ?? context.colors.textPrimary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactFilledButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CompactFilledButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: 0,
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
