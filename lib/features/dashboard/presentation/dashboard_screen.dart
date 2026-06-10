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
      appBar: const TopAppBar(title: 'Merchant Center'),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // MERCHANT HEADER (matches User Profile style)
            Row(
              children: [
                FallbackAvatar(
                  imageUrl: shop.logo,
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

            // PERFORMANCE OVERVIEW SECTION
            _buildSectionTitle(context, 'PERFORMANCE OVERVIEW'),
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
                  title: 'Profile Views',
                  value: '0',
                  subtitle: 'Total views',
                  color: Colors.blue.shade50,
                  iconColor: Colors.blue.shade700,
                ),
                _buildMetricActionCard(
                  context: context,
                  icon: LucideIcons.sparkles,
                  title: 'Total Leads',
                  value: shopLeads.length.toString(),
                  subtitle: '$newLeadsCount uncontacted',
                  color: Colors.amber.shade50,
                  iconColor: Colors.amber.shade700,
                ),
                _buildMetricActionCard(
                  context: context,
                  icon: LucideIcons.percent,
                  title: 'Offer Clicks',
                  value: '0',
                  subtitle: 'Total clicks',
                  color: Colors.purple.shade50,
                  iconColor: Colors.purple.shade700,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // RECENT LEADS SECTION
            _buildSectionTitle(context, 'RECENT ACTIVE LEADS'),
            const SizedBox(height: 10),
            shopLeads.isEmpty
                ? _buildEmptyState(context, 'No customer leads generated yet.')
                : _buildSectionCard(
                    context,
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: shopLeads.length > 3 ? 3 : shopLeads.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
                        itemBuilder: (context, index) {
                          final lead = shopLeads[index];
                          return _buildLeadListTile(context, lead, ref);
                        },
                      ),
                    ],
                  ),
            const SizedBox(height: 16),

            // View All Leads Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(LucideIcons.arrowRight, size: 14, color: context.colors.textPrimary),
                label: Text('View All Leads', style: TextStyle(color: context.colors.textPrimary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: context.colors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                onPressed: () {
                  // Navigate to Leads Screen tab (index 3 in shell screen)
                  ref.read(bottomNavIndexProvider.notifier).state = 3;
                },
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

  Widget _buildSectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: context.colors.surface,
          child: Column(
            children: children,
          ),
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

  Widget _buildLeadListTile(BuildContext context, LeadModel lead, WidgetRef ref) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.border,
          shape: BoxShape.circle,
        ),
        child: Icon(
          lead.type == LeadType.whatsappClick
              ? LucideIcons.messageSquare
              : (lead.type == LeadType.discountRequest ? LucideIcons.percent : LucideIcons.heart),
          size: 16,
          color: context.colors.primary,
        ),
      ),
      title: Text(
        lead.userName,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        'Interested in ${lead.productName}',
        style: AppTypography.label.copyWith(
          color: context.colors.textSecondary,
          fontSize: 11,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: lead.status == 'New'
                  ? context.colors.offerOrange.withValues(alpha: 0.1)
                  : context.colors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              lead.status,
              style: AppTypography.label.copyWith(
                color: lead.status == 'New' ? context.colors.offerOrange : context.colors.success,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(LucideIcons.chevronRight, size: 14, color: context.colors.textSecondary.withValues(alpha: 0.7)),
        ],
      ),
      onTap: () {
        // Navigate to Leads Screen tab (index 3 in shell screen)
        ref.read(bottomNavIndexProvider.notifier).state = 3;
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.inbox, size: 40, color: context.colors.border),
            const SizedBox(height: 12),
            Text(msg, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
