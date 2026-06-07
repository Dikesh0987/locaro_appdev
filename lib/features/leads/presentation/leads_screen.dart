import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/lead_model.dart';

class LeadsScreen extends ConsumerWidget {
  const LeadsScreen({super.key});

  String _getLeadTypeString(LeadType type) {
    switch (type) {
      case LeadType.interested:
        return 'Interested';
      case LeadType.saved:
        return 'Saved';
      case LeadType.discountRequest:
        return 'Discount Request';
      case LeadType.whatsappClick:
        return 'WhatsApp Click';
      case LeadType.callClick:
        return 'Call Click';
    }
  }

  Color _getLeadTypeColor(BuildContext context, LeadType type) {
    switch (type) {
      case LeadType.discountRequest:
        return context.colors.offerOrange;
      case LeadType.whatsappClick:
        return Colors.green.shade600;
      case LeadType.interested:
        return context.colors.primary;
      case LeadType.saved:
        return context.colors.secondary;
      case LeadType.callClick:
        return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseProvider);
    final shop = state.currentShop;
    
    // Get leads for this shop
    final leads = state.leads.where((l) => l.shopId == shop.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Leads'),
        centerTitle: false,
      ),
      body: leads.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.users, size: 48, color: context.colors.textSecondary),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'No active leads yet.',
                    style: AppTypography.body.copyWith(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Leads are generated when users tap WhatsApp, Interested, or Ask Discount on your products.',
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.mobilePadding),
              itemCount: leads.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                final lead = leads[index];
                final typeColor = _getLeadTypeColor(context, lead.type);
                final typeText = _getLeadTypeString(lead.type);

                return BaseCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    lead.type == LeadType.whatsappClick
                                        ? LucideIcons.messageSquare
                                        : (lead.type == LeadType.discountRequest
                                            ? LucideIcons.percent
                                            : LucideIcons.user),
                                    size: 10,
                                    color: typeColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    typeText,
                                    style: AppTypography.label.copyWith(
                                      color: typeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${DateTime.now().difference(lead.createdAt).inMinutes}m ago',
                              style: AppTypography.label.copyWith(
                                color: context.colors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Text(
                          lead.userName,
                          style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Phone: ${lead.userPhone}',
                          style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          'Product: ${lead.productName}',
                          style: AppTypography.caption.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Divider(color: context.colors.border, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  decoration: BoxDecoration(
                                    color: lead.status == 'New' ? context.colors.offerOrange : context.colors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  lead.status,
                                  style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (lead.status == 'New')
                              TextButton(
                                onPressed: () {
                                  ref.read(databaseProvider.notifier).markLeadContacted(lead.id);
                                },
                                child: Text(
                                  'Mark Contacted',
                                  style: AppTypography.label.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
