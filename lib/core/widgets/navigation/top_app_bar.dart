import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const TopAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: AppTypography.heading),
      leading: leading,
      actions: actions ?? [
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.primary),
          onPressed: () {},
        ),
        const SizedBox(width: AppSpacing.s8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
