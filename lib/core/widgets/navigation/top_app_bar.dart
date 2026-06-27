import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../../providers/notification_providers.dart';
import '../../../features/notifications/presentation/notifications_screen.dart';
import '../../../features/search/presentation/search_screen.dart';
import '../../utils/page_transitions.dart';
import '../../../providers/app_state_providers.dart';
import '../common/fallback_image.dart';

class TopAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showDefaultActions;

  const TopAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.showDefaultActions = true,
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

    final role = ref.watch(appRoleProvider);
    final state = ref.watch(databaseProvider);

    Widget titleWidget;
    if (title != null) {
      titleWidget = Text(title!, style: AppTypography.heading);
    } else if (role == 'owner') {
      final shop = state.currentShop;
      titleWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FallbackAvatar(
            imageUrl: shop.logo,
            name: shop.shopName,
            radius: 16,
            fallbackIcon: LucideIcons.store,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              shop.shopName,
              style: AppTypography.heading.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      titleWidget = ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            context.colors.primary, // existing primary
            const Color(0xFF000080), // Navy Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          'locaro',
          style: AppTypography.heading.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            color: Colors.white, 
          ),
        ),
      );
    }

    return AppBar(
      title: titleWidget,
      centerTitle: false,
      leading: leadingWidget,
      actions: [
        ...?actions,
        if (showDefaultActions) ...[
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
                SlidePageRoute(page: const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.search, color: context.colors.primary),
            onPressed: () {
              Navigator.push(
                context,
                SlidePageRoute(page: const SearchScreen()),
              );
            },
          ),
        ],
        const SizedBox(width: AppSpacing.s8),
      ],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
