import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../../providers/notification_providers.dart';
import '../../../features/notifications/presentation/notifications_screen.dart';

class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;

  const TopAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPop = Navigator.canPop(context);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => n.isUnread).length;

    final leadingWidget = leading ?? (canPop
        ? IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          )
        : IconButton(
            icon: const Icon(LucideIcons.menu, color: AppColors.primary),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ));

    return AppBar(
      title: title != null
          ? Text(title!, style: AppTypography.heading)
          : Text(
              'Nearo',
              style: AppTypography.heading.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
                color: AppColors.primary,
              ),
            ),
      centerTitle: title == null, // Center only the Nearo logo
      leading: leadingWidget,
      actions: actions ?? [
        IconButton(
          icon: Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0,
            backgroundColor: AppColors.error,
            textColor: Colors.white,
            child: const Icon(LucideIcons.bell, color: AppColors.primary),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(LucideIcons.search, color: AppColors.primary),
          onPressed: () {},
        ),
        const SizedBox(width: AppSpacing.s8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
