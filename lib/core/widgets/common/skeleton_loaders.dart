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
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      period: const Duration(milliseconds: 1200),
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

class FeedSkeletonCard extends StatelessWidget {
  const FeedSkeletonCard({super.key});

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
              const SkeletonContainer(width: 36, height: 36, borderRadius: 18),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonContainer(width: 120, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonContainer(width: 80, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Large Image Container
        const AspectRatio(
          aspectRatio: 1.1,
          child: SkeletonContainer(width: double.infinity, height: double.infinity, borderRadius: 0),
        ),

        // Actions Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: const [
              SkeletonContainer(width: 24, height: 24, borderRadius: 12),
              SizedBox(width: 16),
              SkeletonContainer(width: 24, height: 24, borderRadius: 12),
              SizedBox(width: 16),
              SkeletonContainer(width: 24, height: 24, borderRadius: 12),
              Spacer(),
              SkeletonContainer(width: 24, height: 24, borderRadius: 12),
            ],
          ),
        ),

        // Content Details
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.mobilePadding,
            vertical: 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonContainer(width: 200, height: 14, borderRadius: 4),
              SizedBox(height: 8),
              SkeletonContainer(width: double.infinity, height: 14, borderRadius: 4),
              SizedBox(height: 4),
              SkeletonContainer(width: 150, height: 14, borderRadius: 4),
              SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class ProductSkeletonCard extends StatelessWidget {
  const ProductSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        AspectRatio(
          aspectRatio: 1.0,
          child: SkeletonContainer(width: double.infinity, height: double.infinity, borderRadius: 8),
        ),
        SizedBox(height: 8),
        SkeletonContainer(width: 100, height: 12, borderRadius: 4),
        SizedBox(height: 4),
        SkeletonContainer(width: 60, height: 12, borderRadius: 4),
      ],
    );
  }
}

class ProfileSkeletonHeader extends StatelessWidget {
  const ProfileSkeletonHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
      child: Column(
        children: [
          const SkeletonContainer(width: 100, height: 100, borderRadius: 50),
          const SizedBox(height: 16),
          const SkeletonContainer(width: 150, height: 20, borderRadius: 4),
          const SizedBox(height: 8),
          const SkeletonContainer(width: 100, height: 14, borderRadius: 4),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              SkeletonContainer(width: 60, height: 40, borderRadius: 8),
              SkeletonContainer(width: 60, height: 40, borderRadius: 8),
              SkeletonContainer(width: 60, height: 40, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
