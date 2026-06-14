import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../models/query_model.dart';
import '../../../providers/app_state_providers.dart';

class QueryCenterScreen extends ConsumerStatefulWidget {
  const QueryCenterScreen({super.key});

  @override
  ConsumerState<QueryCenterScreen> createState() => _QueryCenterScreenState();
}

class _QueryCenterScreenState extends ConsumerState<QueryCenterScreen> {
  String _statusFilter = 'pending'; // 'pending', 'answered', 'closed'

  void _showReplyDialog(QueryModel query) {
    final TextEditingController answerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reply to Query', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer asked:', style: AppTypography.label.copyWith(color: context.colors.textSecondary)),
              const SizedBox(height: 4),
              Text(query.question, style: AppTypography.body),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (answerController.text.trim().isNotEmpty) {
                  ref.read(databaseProvider.notifier).answerQuery(query.id, answerController.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reply sent successfully!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
              child: Text('Send Reply', style: TextStyle(color: context.colors.surface)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseProvider);
    final shopId = state.currentShop.id;

    // Get queries for this shop matching the filter
    final queries = state.queries
        .where((q) => q.shopId == shopId && q.status == _statusFilter)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text('Query Center', style: AppTypography.heading.copyWith(fontSize: 20)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.primary),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(bottom: BorderSide(color: context.colors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterTab('Pending', 'pending'),
                _buildFilterTab('Answered', 'answered'),
                _buildFilterTab('Closed', 'closed'),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: queries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.messageSquare, size: 48, color: context.colors.border),
                        const SizedBox(height: 16),
                        Text('No $_statusFilter queries', style: AppTypography.body),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.mobilePadding),
                    itemCount: queries.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final query = queries[index];
                      // Find product name if applicable
                      String? productName;
                      if (query.productId != null) {
                        try {
                          productName = state.products.firstWhere((p) => p.id == query.productId).name;
                        } catch (_) {}
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.colors.background,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    query.category,
                                    style: AppTypography.label.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                                Text(
                                  _formatDate(query.createdAt),
                                  style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                                ),
                              ],
                            ),
                            if (productName != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(LucideIcons.package, size: 12, color: context.colors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      productName,
                                      style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text('Q: ${query.question}', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                            
                            if (query.status == 'answered' && query.answer != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.colors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Your Reply: ${query.answer}', style: AppTypography.caption),
                              ),
                            ],

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (query.status != 'closed')
                                  TextButton(
                                    onPressed: () {
                                      ref.read(databaseProvider.notifier).closeQuery(query.id);
                                    },
                                    child: Text('Mark Closed', style: TextStyle(color: context.colors.textSecondary)),
                                  ),
                                if (query.status == 'pending')
                                  ElevatedButton(
                                    onPressed: () => _showReplyDialog(query),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.colors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text('Reply', style: TextStyle(color: context.colors.surface)),
                                  ),
                              ],
                            )
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

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? context.colors.primary : context.colors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
