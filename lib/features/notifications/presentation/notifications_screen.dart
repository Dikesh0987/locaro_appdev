import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Offers', 'Followers', 'Comments', 'System'];

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => n.isUnread).length;

    // Filter notifications
    final filteredNotifications = _selectedFilter == 'All'
        ? notifications
        : notifications.where((n) => n.category.toLowerCase() == _selectedFilter.toLowerCase()).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Text(
              'MARK ALL READ',
              style: AppTypography.label.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.s12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen description & Unread badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: AppSpacing.s8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Stay updated with your favorite local spots.',
                    style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$unreadCount unread',
                      style: AppTypography.label.copyWith(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Filters Row
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? context.colors.primary : context.colors.surface,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected ? context.colors.primary : context.colors.border,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: AppTypography.label.copyWith(
                        color: isSelected ? Colors.white : context.colors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8),

          // Notifications List
          Expanded(
            child: notifications.isEmpty 
                ? _buildEmptyState('No notifications yet', 'You have no new notifications right now.')
                : filteredNotifications.isEmpty
                ? _buildEmptyState('No notifications found', 'Change your filters or search options.')
                : RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
                      itemCount: filteredNotifications.length,
                      separatorBuilder: (context, index) => SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = filteredNotifications[index];
                        return BaseCard(
                          onTap: () {
                            ref.read(notificationsProvider.notifier).toggleUnread(notification.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Unread Indicator Dot
                                if (notification.isUnread)
                                  Container(
                                    margin: const EdgeInsets.only(top: 18, right: 8),
                                    height: 8,
                                    width: 8,
                                    decoration: BoxDecoration(
                                      color: context.colors.offerOrange,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                else
                                  SizedBox(width: 16),

                                // Sender Avatar
                                FallbackAvatar(
                                  imageUrl: notification.logoUrl,
                                  radius: 22,
                                  fallbackIcon: LucideIcons.sparkles,
                                ),
                                SizedBox(width: AppSpacing.s12),

                                // Notification Text details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification.title,
                                              style: AppTypography.body.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: context.colors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            notification.time,
                                            style: AppTypography.label.copyWith(
                                              color: context.colors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        notification.body,
                                        style: AppTypography.caption.copyWith(
                                          color: context.colors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      // Category Pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: context.colors.border,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          notification.category,
                                          style: AppTypography.label.copyWith(
                                            color: context.colors.textSecondary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.border.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.bellOff, size: 40, color: context.colors.secondary),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
