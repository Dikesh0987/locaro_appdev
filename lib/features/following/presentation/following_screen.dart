import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../core/widgets/common/offer_badge.dart';
import '../../../core/widgets/navigation/top_app_bar.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/shop_model.dart';
import '../../../models/offer_model.dart';
import '../../../models/post_model.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import '../../../core/widgets/common/animated_action_icon.dart';
import '../../search/presentation/search_screen.dart';
import '../../../core/utils/page_transitions.dart';

class FollowingScreen extends ConsumerWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.watch(databaseProvider);
    final user = dbState.currentUser;
    
    // Followed shops
    final followedShops = dbState.shops.where((s) => user.followingShops.contains(s.id)).toList();
    
    // Sort recently followed (we can treat the reverse order of user.followingShops as recently followed)
    final recentlyFollowed = followedShops.reversed.toList();

    // Offers from followed shops
    final offers = dbState.offers.where((o) => user.followingShops.contains(o.shopId)).toList();

    // Posts from followed shops (sorted by date descending)
    final posts = dbState.posts.where((p) => user.followingShops.contains(p.shopId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: TopAppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.mobilePadding, 0, AppSpacing.mobilePadding, AppSpacing.s12),
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
                hintStyle: AppTypography.body.copyWith(
                  color: context.colors.textSecondary,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 20,
                  color: context.colors.textSecondary,
                ),
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
        ),
      ),
      body: followedShops.isEmpty
          ? _buildEmptyState(context, ref)
          : RefreshIndicator(
              onRefresh: () async {
                // data refreshes instantly
              },
              child: SingleChildScrollView(
                key: const PageStorageKey('following_feed'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // SECTION 1: Followed Shops (Recently Followed)
                    _buildSectionHeader(context, 'Shops You Follow', '${followedShops.length} shops'),
                    SizedBox(height: AppSpacing.s12),
                    SizedBox(
                      height: 105,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
                        scrollDirection: Axis.horizontal,
                        itemCount: recentlyFollowed.length,
                        separatorBuilder: (context, index) => SizedBox(width: AppSpacing.s16),
                        itemBuilder: (context, index) {
                          final shop = recentlyFollowed[index];
                          return _ShopAvatarCard(shop: shop);
                        },
                      ),
                    ),
                    SizedBox(height: AppSpacing.sectionGap),

                    // SECTION 2: Latest Offers from Followed Shops
                    if (offers.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Exclusive Offers', '${offers.length} active'),
                      SizedBox(height: AppSpacing.s12),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
                          scrollDirection: Axis.horizontal,
                          itemCount: offers.length,
                          separatorBuilder: (context, index) => SizedBox(width: AppSpacing.s16),
                          itemBuilder: (context, index) {
                            final offer = offers[index];
                            final shop = followedShops.where((s) => s.id == offer.shopId).firstOrNull;
                            if (shop == null) return const SizedBox.shrink();
                            return _OfferCard(offer: offer, shop: shop);
                          },
                        ),
                      ),
                      SizedBox(height: AppSpacing.sectionGap),
                    ],

                    // SECTION 3: New Posts Feed
                    _buildSectionHeader(context, 'Recent Updates', '${posts.length} posts'),
                    SizedBox(height: AppSpacing.s12),
                    posts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
                            child: _buildSimplePlaceholder(context, 'No recent updates or posts from these shops.'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
                            itemCount: posts.length,
                            separatorBuilder: (context, index) => SizedBox(height: AppSpacing.s16),
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              final shop = followedShops.where((s) => s.id == post.shopId).firstOrNull;
                              if (shop == null) return const SizedBox.shrink();
                              return _PostCard(post: post, shop: shop);
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.subheading.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          Text(
            count,
            style: AppTypography.label.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplePlaceholder(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.colors.border),
      ),
      child: Center(
        child: Text(
          text,
          style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.border.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.heart,
                size: 48,
                color: context.colors.secondary,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Followed Shops Yet',
              style: AppTypography.heading.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Follow local shops to get their latest updates, products, and exclusive offers right here.',
              style: AppTypography.body.copyWith(color: context.colors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(LucideIcons.compass, size: 16, color: context.colors.surface),
              label: Text('Discover Local Shops', style: TextStyle(color: context.colors.surface)),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              onPressed: () {
                // Switch tab to Discover
                ref.read(bottomNavIndexProvider.notifier).state = 1;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Circular Shop Avatar Card with Unfollow action overlay or longpress
class _ShopAvatarCard extends ConsumerWidget {
  final ShopModel shop;
  const _ShopAvatarCard({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShopProfileScreen(shopId: shop.id)),
        );
      },
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Stack(
              children: [
                FallbackAvatar(
                  imageUrl: shop.logo,
                  name: shop.shopName,
                  radius: 30,
                  fallbackIcon: LucideIcons.store,
                ),
                // Small unfollow button
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () => _showUnfollowConfirmation(context, ref),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
                      child: Icon(
                        LucideIcons.heartHandshake,
                        size: 10,
                        color: context.colors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              shop.shopName,
              style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showUnfollowConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unfollow ${shop.shopName}?'),
        content: Text('You will no longer receive their latest posts and offers in your Following feed.'),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Unfollow', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
            onPressed: () {
              ref.read(databaseProvider.notifier).toggleFollowShop(shop.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unfollowed ${shop.shopName}'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(databaseProvider.notifier).toggleFollowShop(shop.id);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Offers Card
class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final ShopModel shop;

  const _OfferCard({required this.offer, required this.shop});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShopProfileScreen(shopId: shop.id)),
        );
      },
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 4),
              child: FallbackImage(
                imageUrl: offer.banner,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          offer.title,
                          style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4),
                      OfferBadge(text: offer.discount),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    shop.shopName,
                    style: AppTypography.label.copyWith(color: context.colors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    offer.description,
                    style: AppTypography.label.copyWith(color: context.colors.textSecondary, fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Compact Post Card for feed
class _PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final ShopModel shop;

  const _PostCard({required this.post, required this.shop});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  @override
  Widget build(BuildContext context) {
    final dbState = ref.watch(databaseProvider);
    final isLiked = dbState.currentUser.likedPosts.contains(widget.post.id);
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: FallbackAvatar(
              imageUrl: widget.shop.logo,
              name: widget.shop.shopName,
              radius: 16,
              fallbackIcon: LucideIcons.store,
            ),
            title: Text(
              widget.shop.shopName,
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              widget.shop.category,
              style: AppTypography.label.copyWith(color: context.colors.textSecondary, fontSize: 10),
            ),
            trailing: IconButton(
              icon: Icon(LucideIcons.heartOff, size: 16, color: context.colors.textSecondary),
              tooltip: 'Unfollow Shop',
              onPressed: () => _confirmUnfollow(context),
            ),
          ),
          
          // Image
          AspectRatio(
            aspectRatio: 1.5,
            child: FallbackImage(
              imageUrl: widget.post.image,
              fit: BoxFit.cover,
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: AnimatedActionIcon(
                    icon: LucideIcons.heart,
                    activeIcon: LucideIcons.heart,
                    isActive: isLiked,
                    inactiveColor: context.colors.primary,
                    activeColor: context.colors.error,
                    size: 20,
                  ),
                  onPressed: () {
                    ref.read(databaseProvider.notifier).toggleLikePost(widget.post.id);
                  },
                ),
                Text(
                  '${widget.post.likes}',
                  style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 16),
                Icon(LucideIcons.messageCircle, size: 20, color: context.colors.primary),
                SizedBox(width: 4),
                Text(
                  '${widget.post.comments}',
                  style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Caption
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
            child: Text(
              widget.post.caption,
              style: AppTypography.caption.copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmUnfollow(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unfollow ${widget.shop.shopName}?'),
        content: Text('You will no longer receive updates from this shop in your Following tab.'),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Unfollow', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
            onPressed: () {
              ref.read(databaseProvider.notifier).toggleFollowShop(widget.shop.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
