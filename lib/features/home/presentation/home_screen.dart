import 'dart:math';
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
import '../../shop/presentation/shop_profile_screen.dart';
import '../../auth/application/auth_service.dart';

enum FeedItemType { post, product, offer }

class MixedFeedItem {
  final String id;
  final String shopId;
  final FeedItemType type;
  final dynamic item; // PostModel, ProductModel, or OfferModel
  final double distance;
  final DateTime createdAt;

  MixedFeedItem({
    required this.id,
    required this.shopId,
    required this.type,
    required this.item,
    required this.distance,
    required this.createdAt,
  });
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // Math.PI / 180
  final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) *
      (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseProvider);
    final currentUser = state.currentUser;
    final shops = state.shops;
    final posts = state.posts;
    final offers = state.offers;
    final products = state.products;

    if (shops.isEmpty) {
      return const Scaffold(
        appBar: TopAppBar(),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 1. Calculate distances for all shops
    final Map<String, double> shopDistances = {};
    for (final shop in shops) {
      final distance = _calculateDistance(
        currentUser.latitude,
        currentUser.longitude,
        shop.latitude,
        shop.longitude,
      );
      shopDistances[shop.id] = distance;
    }

    // 2. Build the mixed feed items list (filter to shops within 5.0 km)
    final List<MixedFeedItem> feedItems = [];

    // Add Posts
    for (final post in posts) {
      final distance = shopDistances[post.shopId] ?? 999.0;
      if (distance <= 5.0) {
        feedItems.add(MixedFeedItem(
          id: post.id,
          shopId: post.shopId,
          type: FeedItemType.post,
          item: post,
          distance: distance,
          createdAt: post.createdAt,
        ));
      }
    }

    // Add Offers
    for (final offer in offers) {
      final distance = shopDistances[offer.shopId] ?? 999.0;
      if (distance <= 5.0) {
        feedItems.add(MixedFeedItem(
          id: offer.id,
          shopId: offer.shopId,
          type: FeedItemType.offer,
          item: offer,
          distance: distance,
          createdAt: offer.createdAt,
        ));
      }
    }

    // Add Products
    for (final product in products) {
      final distance = shopDistances[product.shopId] ?? 999.0;
      if (distance <= 5.0) {
        feedItems.add(MixedFeedItem(
          id: product.id,
          shopId: product.shopId,
          type: FeedItemType.product,
          item: product,
          distance: distance,
          createdAt: product.createdAt,
        ));
      }
    }

    // 3. Mix items deterministically using ID hash to ensure stable order
    feedItems.sort((a, b) => a.id.hashCode.compareTo(b.id.hashCode));

    return Scaffold(
      appBar: const TopAppBar(),
      body: feedItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.newspaper, size: 64, color: AppColors.border),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'No Updates Yet',
                    style: AppTypography.heading.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Follow shops to see their updates here.',
                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpacing.s24),
                itemCount: feedItems.length,
                separatorBuilder: (context, index) =>
                    Container(height: 8, color: AppColors.border),
                itemBuilder: (context, index) {
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

class _FeedCardState extends ConsumerState<_FeedCard>
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
              ref.read(databaseProvider.notifier).toggleLikePost(widget.post.id);
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
              id: 'lead_${DateTime.now().millisecondsSinceEpoch}',
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
    final dbState = ref.watch(databaseProvider);
    final isSaved =
        widget.linkedProduct != null &&
        dbState.currentUser.savedProducts.contains(widget.linkedProduct!.id);

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
              const SizedBox(width: AppSpacing.s12),
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.navigation,
                            size: 10,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.distance,
                            style: AppTypography.label.copyWith(
                              color: AppColors.textSecondary,
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
              ScaleTransition(
                scale: _likeScale,
                child: IconButton(
                  icon: Icon(
                    _isLiked ? LucideIcons.heart : LucideIcons.heart,
                    color: _isLiked ? AppColors.error : AppColors.primary,
                  ),
                  onPressed: _triggerLike,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.messageCircle),
                onPressed: () {
                  _generateLead(LeadType.interested, 'Interest query');
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
                  icon: Icon(
                    isSaved ? LucideIcons.bookmark : LucideIcons.bookmark,
                    color: isSaved
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    ref.read(authServiceProvider).checkGuest(
                          context,
                          onAllowed: () {
                            ref
                                .read(databaseProvider.notifier)
                                .toggleSaveProduct(widget.linkedProduct!.id);
                            if (!isSaved) {
                              _generateLead(LeadType.saved, 'Product Saved');
                            }
                          },
                        );
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
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
              ],
              Text(
                widget.post.caption,
                style: AppTypography.caption.copyWith(height: 1.4),
              ),
              const SizedBox(height: AppSpacing.s12),

              // Sticky actions for Leads generation
              if (widget.linkedProduct != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          LucideIcons.percent,
                          size: 14,
                          color: AppColors.offerOrange,
                        ),
                        label: const Text(
                          'Ask Discount',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                        ),
                        onPressed: () => _generateLead(
                          LeadType.discountRequest,
                          'Discount Request',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          LucideIcons.messageSquare,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'WhatsApp',
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
                        onPressed: () => _generateLead(
                          LeadType.whatsappClick,
                          'WhatsApp query',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
              ],

              Text(
                'SHOP UPDATE',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
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

class _ProductFeedCardState extends ConsumerState<_ProductFeedCard>
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
              ref.read(databaseProvider.notifier).toggleLikeProduct(widget.product.id);
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
              id: 'lead_${DateTime.now().millisecondsSinceEpoch}',
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
    final dbState = ref.watch(databaseProvider);
    final isSaved = dbState.currentUser.savedProducts.contains(widget.product.id);

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
              const SizedBox(width: AppSpacing.s12),
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.navigation,
                            size: 10,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.distance,
                            style: AppTypography.label.copyWith(
                              color: AppColors.textSecondary,
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
              ScaleTransition(
                scale: _likeScale,
                child: IconButton(
                  icon: Icon(
                    _isLiked ? LucideIcons.heart : LucideIcons.heart,
                    color: _isLiked ? AppColors.error : AppColors.primary,
                  ),
                  onPressed: _triggerLike,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.messageCircle),
                onPressed: () {
                  _generateLead(LeadType.interested, 'Product inquiry');
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
                icon: Icon(
                  isSaved ? LucideIcons.bookmark : LucideIcons.bookmark,
                  color: isSaved ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: () {
                  ref.read(authServiceProvider).checkGuest(
                        context,
                        onAllowed: () {
                          ref
                              .read(databaseProvider.notifier)
                              .toggleSaveProduct(widget.product.id);
                          if (!isSaved) {
                            _generateLead(LeadType.saved, 'Product Bookmarked');
                          }
                        },
                      );
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
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '₹${widget.product.discountPrice?.toStringAsFixed(0) ?? widget.product.price.toStringAsFixed(0)}',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                widget.product.description,
                style: AppTypography.caption.copyWith(height: 1.4),
              ),
              const SizedBox(height: AppSpacing.s12),

              // Sticky actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        LucideIcons.percent,
                        size: 14,
                        color: AppColors.offerOrange,
                      ),
                      label: const Text(
                        'Ask Discount',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.buttonRadius,
                          ),
                        ),
                      ),
                      onPressed: () => _generateLead(
                        LeadType.discountRequest,
                        'Discount Request',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        LucideIcons.messageSquare,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'WhatsApp',
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
                      onPressed: () => _generateLead(
                        LeadType.whatsappClick,
                        'WhatsApp query',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),

              Text(
                'PRODUCT RECOMMENDATION',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
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

  void _generateLead(LeadType type, String typeLabel) {
    ref.read(authServiceProvider).checkGuest(
          context,
          onAllowed: () {
            final dbState = ref.read(databaseProvider);
            final newLead = LeadModel(
              id: 'lead_${DateTime.now().millisecondsSinceEpoch}',
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
              const SizedBox(width: AppSpacing.s12),
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.navigation,
                            size: 10,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.distance,
                            style: AppTypography.label.copyWith(
                              color: AppColors.textSecondary,
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
                    color: _isLiked ? AppColors.error : AppColors.primary,
                  ),
                  onPressed: _triggerLike,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.messageCircle),
                onPressed: () {
                  _generateLead(LeadType.interested, 'Offer inquiry');
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
              const SizedBox(height: AppSpacing.s8),
              Text(
                widget.offer.description,
                style: AppTypography.caption.copyWith(height: 1.4),
              ),
              const SizedBox(height: AppSpacing.s12),

              // Sticky actions for claim coupon
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        LucideIcons.ticket,
                        size: 14,
                        color: AppColors.offerOrange,
                      ),
                      label: const Text(
                        'Claim Coupon',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: AppColors.border),
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
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        LucideIcons.messageSquare,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'WhatsApp Shop',
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
                      onPressed: () => _generateLead(
                        LeadType.whatsappClick,
                        'WhatsApp Coupon query',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),

              Text(
                'PROMOTIONAL OFFER',
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
          ),
        ),
      ],
    );
  }
}
