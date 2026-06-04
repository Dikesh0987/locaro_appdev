import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';

class OfferBadge extends StatelessWidget {
  final String text;

  const OfferBadge({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.offerOrange,
        borderRadius: BorderRadius.circular(100), // Fully rounded
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.label.copyWith(
          color: AppColors.surface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
