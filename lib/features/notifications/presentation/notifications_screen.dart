import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'MARK ALL READ',
              style: AppTypography.label.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stay updated with your favorite local spots.',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Card Container encapsulating notifications matching mockup
            BaseCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- NEW SECTION ---
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                      child: Text(
                        'NEW',
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    _buildNotificationRow(
                      logoUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=100', // Cafe
                      title: 'Cafe Aroma',
                      body: 'Your morning brew is ready! Flash this notification for 10% off your next purchase.',
                      time: '2m ago',
                      isUnread: true,
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildNotificationRow(
                      logoUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=100', // Mart
                      title: 'The Daily Catch',
                      body: 'Fresh King Salmon just arrived. Limited stock available this weekend!',
                      time: '1h ago',
                      isUnread: true,
                    ),
                    
                    // --- EARLIER SECTION ---
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
                      child: Text(
                        'EARLIER',
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    _buildNotificationRow(
                      logoUrl: 'https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?w=100', // Fruit
                      title: 'Local Green Grocer',
                      body: 'Weekend farmer\'s market starts at 8 AM tomorrow. Tap to see the vendors list.',
                      time: 'Yesterday',
                      isUnread: false,
                    ),
                    const Divider(color: AppColors.border, height: 1),
                    _buildNotificationRow(
                      logoUrl: '', // System
                      title: 'Nearo System',
                      body: 'You\'ve reached level 3 local explorer! Check out your new badge in settings.',
                      time: 'Tue',
                      isUnread: false,
                      isSystem: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'You\'re all caught up',
                style: AppTypography.label.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationRow({
    required String logoUrl,
    required String title,
    required String body,
    required String time,
    required bool isUnread,
    bool isSystem = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUnread) ...[
            Container(
              margin: const EdgeInsets.only(top: 14, right: 8),
              height: 6,
              width: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ] else ...[
            const SizedBox(width: 14),
          ],
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.border,
            backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
            child: logoUrl.isEmpty
                ? const Icon(LucideIcons.sparkles, size: 16, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      time,
                      style: AppTypography.label.copyWith(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
