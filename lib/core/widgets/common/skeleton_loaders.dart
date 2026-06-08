import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/spacing.dart';

class SkeletonContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8ECF3),
      highlightColor: const Color(0xFF2A3556).withAlpha(15),
      period: const Duration(milliseconds: 1200),
      direction: ShimmerDirection.ltr,
      child: Container(
        margin: margin,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// HOME FEED SKELETON
// ---------------------------------------------------------
class FeedSkeletonCard extends StatelessWidget {
  const FeedSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Avatar, Name, Distance, Offer Badge
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.mobilePadding,
              vertical: AppSpacing.s12,
            ),
            child: Row(
              children: [
                const SkeletonContainer(width: 44, height: 44, borderRadius: 22),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonContainer(width: 140, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      SkeletonContainer(width: 80, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                const SkeletonContainer(width: 70, height: 26, borderRadius: 13),
              ],
            ),
          ),

          // Large Post Image
          const AspectRatio(
            aspectRatio: 1.1,
            child: SkeletonContainer(width: double.infinity, height: double.infinity, borderRadius: 0),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Row(
              children: const [
                SkeletonContainer(width: 28, height: 28, borderRadius: 14),
                SizedBox(width: 16),
                SkeletonContainer(width: 28, height: 28, borderRadius: 14),
                SizedBox(width: 16),
                SkeletonContainer(width: 28, height: 28, borderRadius: 14),
                Spacer(),
                SkeletonContainer(width: 28, height: 28, borderRadius: 14),
              ],
            ),
          ),

          // Title & Description Lines
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.mobilePadding,
              vertical: 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonContainer(width: 200, height: 16, borderRadius: 4),
                SizedBox(height: 8),
                SkeletonContainer(width: double.infinity, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonContainer(width: double.infinity, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonContainer(width: 150, height: 14, borderRadius: 4),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// DISCOVER SKELETONS
// ---------------------------------------------------------
class ProductSkeletonCard extends StatelessWidget {
  const ProductSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AspectRatio(
          aspectRatio: 1.0,
          child: SkeletonContainer(width: double.infinity, height: double.infinity, borderRadius: 12),
        ),
        SizedBox(height: 12),
        SkeletonContainer(width: 100, height: 14, borderRadius: 4),
        SizedBox(height: 6),
        SkeletonContainer(width: 60, height: 14, borderRadius: 4),
      ],
    );
  }
}

class ShopCardSkeleton extends StatelessWidget {
  const ShopCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(child: SkeletonContainer(width: 200, borderRadius: 12)),
        SizedBox(height: 12),
        SkeletonContainer(width: 140, height: 16, borderRadius: 4),
        SizedBox(height: 6),
        SkeletonContainer(width: 90, height: 14, borderRadius: 4),
      ],
    );
  }
}

class OfferCardSkeleton extends StatelessWidget {
  const OfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Row(
        children: [
          const SkeletonContainer(width: 80, height: 80, borderRadius: 12),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonContainer(width: double.infinity, height: 16, borderRadius: 4),
                SizedBox(height: 8),
                SkeletonContainer(width: 100, height: 14, borderRadius: 4),
                SizedBox(height: 8),
                SkeletonContainer(width: double.infinity, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// PROFILE SKELETON
// ---------------------------------------------------------
class ProfileSkeletonHeader extends StatelessWidget {
  const ProfileSkeletonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar, Name, Email
        Row(
          children: [
            const SkeletonContainer(width: 88, height: 88, borderRadius: 44),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonContainer(width: 160, height: 24, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonContainer(width: 120, height: 14, borderRadius: 4),
                  SizedBox(height: 8),
                  SkeletonContainer(width: 140, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Edit Profile Button
        const SkeletonContainer(width: double.infinity, height: 48, borderRadius: 24),
        const SizedBox(height: 32),

        // Quick Actions
        const SkeletonContainer(width: 100, height: 14, borderRadius: 4),
        const SizedBox(height: 16),
        Row(
          children: const [
            Expanded(child: SkeletonContainer(height: 80, borderRadius: 16)),
            SizedBox(width: 12),
            Expanded(child: SkeletonContainer(height: 80, borderRadius: 16)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: SkeletonContainer(height: 80, borderRadius: 16)),
            SizedBox(width: 12),
            Expanded(child: SkeletonContainer(height: 80, borderRadius: 16)),
          ],
        ),
        const SizedBox(height: 32),

        // Settings Cards
        const SkeletonContainer(width: 100, height: 14, borderRadius: 4),
        const SizedBox(height: 16),
        const SkeletonContainer(width: double.infinity, height: 180, borderRadius: 16),
      ],
    );
  }
}

// ---------------------------------------------------------
// SHOP PROFILE SKELETON
// ---------------------------------------------------------
class ShopProfileSkeleton extends StatelessWidget {
  const ShopProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner & Logo
        Stack(
          clipBehavior: Clip.none,
          children: [
            const SkeletonContainer(width: double.infinity, height: 180, borderRadius: 0),
            Positioned(
              bottom: -35,
              left: AppSpacing.mobilePadding,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const SkeletonContainer(width: 70, height: 70, borderRadius: 35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),

        // Shop Name & Followers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonContainer(width: 180, height: 28, borderRadius: 6),
                  SkeletonContainer(width: 100, height: 38, borderRadius: 19),
                ],
              ),
              SizedBox(height: 12),
              SkeletonContainer(width: 220, height: 14, borderRadius: 4),
              SizedBox(height: 16),
              SkeletonContainer(width: double.infinity, height: 14, borderRadius: 4),
              SizedBox(height: 6),
              SkeletonContainer(width: 250, height: 14, borderRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonContainer(width: 60, height: 20, borderRadius: 4),
              SkeletonContainer(width: 60, height: 20, borderRadius: 4),
              SkeletonContainer(width: 60, height: 20, borderRadius: 4),
              SkeletonContainer(width: 60, height: 20, borderRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Products Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding),
          child: Row(
            children: const [
              Expanded(child: ProductSkeletonCard()),
              SizedBox(width: 16),
              Expanded(child: ProductSkeletonCard()),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// PRODUCT DETAILS SKELETON
// ---------------------------------------------------------
class ProductDetailsSkeleton extends StatelessWidget {
  const ProductDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonContainer(width: double.infinity, height: 350, borderRadius: 0),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.mobilePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonContainer(width: 100, height: 24, borderRadius: 4), // Price
              SizedBox(height: 12),
              SkeletonContainer(width: double.infinity, height: 28, borderRadius: 6), // Title
              SizedBox(height: 8),
              SkeletonContainer(width: 180, height: 28, borderRadius: 6), // Title row 2
              SizedBox(height: 24),
              SkeletonContainer(width: double.infinity, height: 14, borderRadius: 4), // Desc
              SizedBox(height: 8),
              SkeletonContainer(width: double.infinity, height: 14, borderRadius: 4), // Desc
              SizedBox(height: 8),
              SkeletonContainer(width: 200, height: 14, borderRadius: 4), // Desc
              SizedBox(height: 40),
              SkeletonContainer(width: double.infinity, height: 56, borderRadius: 28), // Action Button
            ],
          ),
        ),
      ],
    );
  }
}
