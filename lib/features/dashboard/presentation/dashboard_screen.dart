import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/lead_model.dart';


class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseProvider);
    final shop = state.currentShop;
    
    // Dynamically calculate the active leads for this shop
    final shopLeads = state.leads.where((l) => l.shopId == shop.id).toList();
    final newLeadsCount = shopLeads.where((l) => l.status == 'New').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Center'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.mobilePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Welcome Banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.s20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          shop.shopName,
                          style: AppTypography.heading.copyWith(color: AppColors.surface, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            'Store Verified & Online',
                            style: AppTypography.label.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(shop.logo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            Text(
              'Performance Overview',
              style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.s12),

            // Performance Cards Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.s16,
              mainAxisSpacing: AppSpacing.s16,
              childAspectRatio: 1.25,
              children: [
                _buildMetricCard(
                  icon: LucideIcons.users,
                  title: 'Followers',
                  value: shop.followers.toString(),
                  trend: '+24 new today',
                  trendColor: AppColors.success,
                ),
                _buildMetricCard(
                  icon: LucideIcons.eye,
                  title: 'Profile Views',
                  value: '1,420',
                  trend: '+12% this week',
                  trendColor: AppColors.success,
                ),
                _buildMetricCard(
                  icon: LucideIcons.sparkles,
                  title: 'Total Leads',
                  value: shopLeads.length.toString(),
                  trend: '$newLeadsCount uncontacted',
                  trendColor: newLeadsCount > 0 ? AppColors.offerOrange : AppColors.textSecondary,
                ),
                _buildMetricCard(
                  icon: LucideIcons.percent,
                  title: 'Offer Clicks',
                  value: '298',
                  trend: '+45% engagement',
                  trendColor: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),

            // Recent Leads quick access
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Active Leads',
                  style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to Leads Screen tab
                    ref.read(bottomNavIndexProvider.notifier).state = 3;
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),

            shopLeads.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'No customer leads generated yet.',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shopLeads.length > 2 ? 2 : shopLeads.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s12),
                    itemBuilder: (context, index) {
                      final lead = shopLeads[index];
                      return BaseCard(
                        onTap: () {
                          ref.read(bottomNavIndexProvider.notifier).state = 3;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.s16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  lead.type == LeadType.whatsappClick
                                      ? LucideIcons.messageSquare
                                      : (lead.type == LeadType.discountRequest ? LucideIcons.percent : LucideIcons.heart),
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lead.userName,
                                      style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Interested in ${lead.productName}',
                                      style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: lead.status == 'New'
                                      ? AppColors.offerOrange.withValues(alpha: 0.1)
                                      : AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lead.status,
                                  style: AppTypography.label.copyWith(
                                    color: lead.status == 'New' ? AppColors.offerOrange : AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String trend,
    required Color trendColor,
  }) {
    return BaseCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.label.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                ),
                Icon(icon, size: 16, color: AppColors.textSecondary),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.display.copyWith(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              trend,
              style: AppTypography.label.copyWith(color: trendColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
