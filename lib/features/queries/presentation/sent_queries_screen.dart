import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../providers/app_state_providers.dart';

import '../../../core/widgets/navigation/top_app_bar.dart';

class SentQueriesScreen extends ConsumerWidget {
  const SentQueriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseProvider);
    final userId = state.currentUser.id;

    // Get queries sent by this user
    final queries = state.queries
        .where((q) => q.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: const TopAppBar(),
      body: queries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.messageSquare, size: 48, color: context.colors.border),
                  const SizedBox(height: 16),
                  Text('No queries sent yet', style: AppTypography.body),
                  const SizedBox(height: 8),
                  Text(
                    'Ask questions directly to shops and track them here.',
                    style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.mobilePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Queries', style: AppTypography.heading),
                      const SizedBox(height: 4),
                      Text(
                        'Track and manage your questions to shops.',
                        style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.mobilePadding),
              itemCount: queries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final query = queries[index];
                
                // Find shop name
                String shopName = 'Unknown Shop';
                try {
                  shopName = state.shops.firstWhere((s) => s.id == query.shopId).shopName;
                } catch (_) {}

                Color statusColor;
                String statusLabel;
                if (query.status == 'answered') {
                  statusColor = context.colors.success;
                  statusLabel = 'Answered';
                } else if (query.status == 'closed') {
                  statusColor = context.colors.textSecondary;
                  statusLabel = 'Closed';
                } else {
                  statusColor = context.colors.offerOrange;
                  statusLabel = 'Pending Reply';
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.store, size: 14, color: context.colors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                shopName,
                                style: AppTypography.label.copyWith(
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusLabel,
                              style: AppTypography.label.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Q: ${query.question}', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                      
                      if (query.status == 'answered' && query.answer != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Shop replied:', style: AppTypography.label.copyWith(color: context.colors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(query.answer!, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(query.createdAt),
                            style: AppTypography.label.copyWith(color: context.colors.textSecondary, fontSize: 10),
                          ),
                          Text(
                            'Category: ${query.category}',
                            style: AppTypography.label.copyWith(color: context.colors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
