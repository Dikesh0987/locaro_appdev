import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../theme/colors.dart';

class FallbackAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final IconData fallbackIcon;

  const FallbackAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 18,
    this.fallbackIcon = LucideIcons.store,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.border,
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isEmpty 
          ? Icon(fallbackIcon, size: radius, color: AppColors.textSecondary) 
          : null,
      onBackgroundImageError: imageUrl.isNotEmpty ? (e, s) {} : null,
    );
  }
}

class FallbackImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData fallbackIcon;

  const FallbackImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackIcon = LucideIcons.image,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: AppColors.border,
        child: Center(
          child: Icon(fallbackIcon, size: 48, color: AppColors.textSecondary),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: AppColors.border,
        child: Center(
          child: Icon(fallbackIcon, size: 48, color: AppColors.textSecondary),
        ),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
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
    );
  }
}
