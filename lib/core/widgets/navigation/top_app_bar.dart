import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../../providers/notification_providers.dart';
import '../../../features/notifications/presentation/notifications_screen.dart';
import '../../../features/search/presentation/search_screen.dart';

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
    final unreadCount = notifications.where((n) => !n.isRead).length;

    final leadingWidget = leading ?? (canPop
        ? IconButton(
            icon: Icon(LucideIcons.chevronLeft, color: context.colors.primary),
            onPressed: () => Navigator.pop(context),
          )
        : null);

    return AppBar(
      title: title != null
          ? Text(title!, style: AppTypography.heading)
          : Text(
              'Locaro',
              style: AppTypography.heading.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
                color: context.colors.primary,
              ),
            ),
      centerTitle: title == null, // Center only the Locaro logo
      leading: leadingWidget,
      actions: actions ?? [
        IconButton(
          icon: Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0,
            backgroundColor: context.colors.error,
            textColor: Colors.white,
            child: Icon(LucideIcons.bell, color: context.colors.primary),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
        ),
        IconButton(
          icon: Icon(LucideIcons.search, color: context.colors.primary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
        const SizedBox(width: AppSpacing.s8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
