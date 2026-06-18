import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../core/widgets/navigation/top_app_bar.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../providers/app_state_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseProvider);
    final shop = state.currentShop;

    // Calculate realtime metrics
    final shopProducts = state.products.where((p) => p.shopId == shop.id).toList();
    final totalViews = shopProducts.fold<int>(0, (sum, p) => sum + p.views);
    final totalLikes = shopProducts.fold<int>(0, (sum, p) => sum + p.likes);
    final engagedUsers = totalLikes + shop.followers;
    final activeProducts = shopProducts.length;

    return Scaffold(
      appBar: const TopAppBar(),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MERCHANT HEADER
            Row(
              children: [
                FallbackAvatar(
                  imageUrl: shop.logo,
                  name: shop.shopName,
                  radius: 44,
                  fallbackIcon: LucideIcons.store,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.shopName,
                        style: AppTypography.heading.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Store Verified & Online',
                          style: AppTypography.label.copyWith(
                            color: context.colors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // STORE ANALYTICS SECTION
            _buildSectionTitle(context, 'STORE ANALYTICS'),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildMetricActionCard(
                  context: context,
                  icon: LucideIcons.users,
                  title: 'Followers',
                  value: shop.followers.toString(),
                  subtitle: 'Total followers',
                  color: Colors.pink.shade50,
                  iconColor: Colors.pink.shade700,
                ),
                _buildMetricActionCard(
                  context: context,
                  icon: LucideIcons.eye,
                  title: 'Total Views',
                  value: totalViews.toString(),
                  subtitle: 'Product views',
                  color: Colors.blue.shade50,
                  iconColor: Colors.blue.shade700,
                ),
                _buildMetricActionCard(
                  context: context,
                  icon: LucideIcons.activity,
                  title: 'Engaged',
                  value: engagedUsers.toString(),
                  subtitle: 'Interactions',
                  color: Colors.green.shade50,
                  iconColor: Colors.green.shade700,
                ),
                _buildMetricActionCard(
                  context: context,
                  icon: LucideIcons.box,
                  title: 'Products',
                  value: activeProducts.toString(),
                  subtitle: 'Active listings',
                  color: Colors.orange.shade50,
                  iconColor: Colors.orange.shade700,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Shop Enable/Disable Toggle
            BaseCard(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(
                  'Shop Active Status',
                  style: AppTypography.heading.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  shop.isActive ? 'Your shop is open and visible to customers.' : 'Your shop is currently closed/disabled.',
                  style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                ),
                value: shop.isActive,
                activeThumbColor: context.colors.success,
                onChanged: (value) async {
                  final updatedShop = shop.copyWith(isActive: value);
                  await ref.read(databaseProvider.notifier).updateCurrentShop(updatedShop);
                },
                secondary: Icon(
                  shop.isActive ? Icons.store : Icons.store_outlined,
                  color: shop.isActive ? context.colors.success : context.colors.textSecondary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: AppTypography.label.copyWith(
          color: context.colors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMetricActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color iconColor,
  }) {
    return BaseCard(
      child: Container(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                Text(
                  subtitle,
                  style: AppTypography.label.copyWith(
                    color: context.colors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.heading.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
