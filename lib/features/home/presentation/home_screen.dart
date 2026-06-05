import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/common/offer_badge.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/post_model.dart';
import '../../../models/lead_model.dart';
import '../../../models/product_model.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import '../../auth/application/auth_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseProvider);
    final posts = state.posts;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.menu),
          onPressed: () {},
        ),
        title: Text(
          'Nearo',
          style: AppTypography.heading.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: posts.isEmpty
          ? Center(
              child: Text(
                'No updates in your area yet.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpacing.s24),
                itemCount: posts.length,
                separatorBuilder: (context, index) => Container(
                  height: 8,
                  color: AppColors.border,
                ),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  // Find shop
                  final shop = state.shops.firstWhere(
                    (s) => s.id == post.shopId,
                    orElse: () => state.currentShop,
                  );
                  // Find product if any linked
                  ProductModel? linkedProduct;
                  try {
                    linkedProduct = state.products.firstWhere(
                      (p) => p.shopId == shop.id,
                    );
                  } catch (_) {}

                  return _FeedCard(
                    post: post,
                    shopName: shop.shopName,
                    shopLogo: shop.logo,
                    distance: '${(1.2 - (index * 0.4)).toStringAsFixed(1)} km away',
                    linkedProduct: linkedProduct,
                    onShopTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopProfileScreen(shopId: shop.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

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

class _FeedCardState extends ConsumerState<_FeedCard> with SingleTickerProviderStateMixin {
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
    ref.read(authServiceProvider).checkGuest(context, onAllowed: () {
      setState(() => _isLiked = !_isLiked);
      if (_isLiked) {
        _likeController.forward(from: 0.0);
        ref.read(databaseProvider.notifier).toggleLikePost(widget.post.id);
      }
    });
  }

  void _generateLead(LeadType type, String typeLabel) {
    if (widget.linkedProduct == null) return;
    
    ref.read(authServiceProvider).checkGuest(context, onAllowed: () {
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
          content: Text('Simulated Lead: $typeLabel generated for ${widget.shopName}'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbState = ref.watch(databaseProvider);
    final isSaved = widget.linkedProduct != null &&
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
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.border,
                  backgroundImage: NetworkImage(widget.shopLogo),
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
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(LucideIcons.navigation, size: 10, color: AppColors.textSecondary),
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
                child: Image.network(
                  widget.post.image,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.border,
                      child: const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Offer Badge Overlay on Image if post is offer type
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
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
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
                    color: isSaved ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    ref.read(authServiceProvider).checkGuest(context, onAllowed: () {
                      ref.read(databaseProvider.notifier).toggleSaveProduct(widget.linkedProduct!.id);
                      if (!isSaved) {
                        _generateLead(LeadType.saved, 'Product Saved');
                      }
                    });
                  },
                ),
            ],
          ),
        ),

        // Content Details
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
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
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
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
                        icon: const Icon(LucideIcons.percent, size: 14, color: AppColors.offerOrange),
                        label: const Text('Ask Discount', style: TextStyle(color: AppColors.textPrimary)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                          ),
                        ),
                        onPressed: () => _generateLead(LeadType.discountRequest, 'Discount Request'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(LucideIcons.messageSquare, size: 14, color: Colors.white),
                        label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                          ),
                        ),
                        onPressed: () => _generateLead(LeadType.whatsappClick, 'WhatsApp query'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
              ],

              Text(
                'POSTED 2 HOURS AGO',
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
