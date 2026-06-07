import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/colors.dart';
import 'skeleton_loaders.dart';

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
    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: context.colors.border,
        child: Icon(fallbackIcon, size: radius, color: context.colors.textSecondary),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => SkeletonContainer(
        width: radius * 2,
        height: radius * 2,
        borderRadius: radius,
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: context.colors.border,
        child: Icon(fallbackIcon, size: radius, color: context.colors.textSecondary),
      ),
      fadeInDuration: const Duration(milliseconds: 250),
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
        color: context.colors.border,
        child: Center(
          child: Icon(fallbackIcon, size: 48, color: context.colors.textSecondary),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => SkeletonContainer(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        borderRadius: 0,
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: context.colors.border,
        child: Center(
          child: Icon(fallbackIcon, size: 48, color: context.colors.textSecondary),
        ),
      ),
      fadeInDuration: const Duration(milliseconds: 250),
    );
  }
}
