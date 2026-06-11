import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../models/query_model.dart';
import '../../../providers/app_state_providers.dart';

class QueryBottomSheet extends ConsumerStatefulWidget {
  final String shopId;
  final String? productId;
  final String category;

  const QueryBottomSheet({
    super.key,
    required this.shopId,
    this.productId,
    required this.category,
  });

  @override
  ConsumerState<QueryBottomSheet> createState() => _QueryBottomSheetState();
}

class _QueryBottomSheetState extends ConsumerState<QueryBottomSheet> {
  final TextEditingController _customQuestionController = TextEditingController();
  bool _isSubmitting = false;

  List<String> _getQuickQuestions() {
    switch (widget.category.toUpperCase()) {
      case 'GROCERY':
        return [
          'Is this available?',
          'Current price kya hai?',
          'Bulk quantity par discount milega?',
          'Home delivery available hai?',
          'Fresh stock hai?',
          'Kitna stock available hai?',
        ];
      case 'FRUITS & VEGETABLES':
        return [
          'Fresh stock hai?',
          'Aaj ka rate kya hai?',
          'Bulk order possible hai?',
          'Wholesale price milega?',
          'Delivery available hai?',
        ];
      case 'ELECTRONICS':
        return [
          'Original product hai?',
          'Warranty kitni hai?',
          'Best price kya hoga?',
          'EMI available hai?',
          'Exchange available hai?',
          'Stock available hai?',
        ];
      case 'FASHION':
        return [
          'Size available hai?',
          'Dusre colors available hain?',
          'Trial available hai?',
          'Return possible hai?',
          'Best price kya hoga?',
        ];
      case 'MOBILE ACCESSORIES':
        return [
          'Original product hai?',
          'Warranty hai?',
          'Bulk discount milega?',
          'Available hai?',
          'Latest model hai?',
        ];
      case 'CAFE / RESTAURANT':
        return [
          'Home delivery hai?',
          'Today\'s special kya hai?',
          'Table booking available hai?',
          'Veg options hain?',
          'Kitna time lagega?',
        ];
      case 'SERVICES':
        return [
          'Price kitna hai?',
          'Available slots hain?',
          'Home service available hai?',
          'Advance booking required hai?',
        ];
      case 'OFFERS':
        return [
          'Offer kab tak valid hai?',
          'Terms kya hain?',
          'Bulk order par apply hoga?',
          'Delivery included hai?',
        ];
      case 'SHOP PROFILE':
        return [
          'Shop open hai?',
          'Exact location share kar sakte hain?',
          'WhatsApp number milega?',
          'Home delivery hai?',
        ];
      default:
        return [
          'Is this available?',
          'Current price kya hai?',
          'Home delivery available hai?',
          'More details please?',
        ];
    }
  }

  String _mapQuickQuestionToFull(String shortQuestion) {
    if (shortQuestion == 'Bulk quantity par discount milega?') {
      return 'Agar bulk me purchase karu to kya discount milega?';
    } else if (shortQuestion == 'Fresh stock hai?') {
      return 'Kya aapke paas iska fresh stock available hai?';
    } else if (shortQuestion == 'Current price kya hai?') {
      return 'Iska current best price kya chal raha hai?';
    } else if (shortQuestion == 'Home delivery available hai?') {
      return 'Kya iski home delivery available hai mere location par?';
    } else if (shortQuestion == 'Exact location share kar sakte hain?') {
      return 'Kya aap apne shop ki exact location share kar sakte hain?';
    }
    return shortQuestion;
  }

  void _submitQuery(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final dbState = ref.read(databaseProvider);
    final queryId = 'query_${DateTime.now().millisecondsSinceEpoch}_${dbState.currentUser.id}';
    
    final newQuery = QueryModel(
      id: queryId,
      userId: dbState.currentUser.id,
      shopId: widget.shopId,
      productId: widget.productId,
      category: widget.category,
      question: question.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await ref.read(databaseProvider.notifier).submitQuery(newQuery);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Query sent to the shop successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _getQuickQuestions();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
            left: AppSpacing.mobilePadding,
            right: AppSpacing.mobilePadding,
            top: AppSpacing.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ask the Shop', style: AppTypography.heading),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),

              Text('Quick Questions', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.s12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: questions.map((q) => _buildQuickQuestionChip(q)).toList(),
              ),
              
              const SizedBox(height: AppSpacing.s24),
              Text('Custom Question', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.s12),
              
              TextField(
                controller: _customQuestionController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.colors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: _isSubmitting 
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(LucideIcons.send, color: context.colors.primary),
                        onPressed: () {
                          _submitQuery(_customQuestionController.text);
                        },
                      ),
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQuestionChip(String text) {
    return ActionChip(
      label: Text(text, style: AppTypography.caption),
      backgroundColor: context.colors.surface,
      side: BorderSide(color: context.colors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () {
        final fullQuestion = _mapQuickQuestionToFull(text);
        _customQuestionController.text = fullQuestion;
      },
    );
  }
}

// Helper to show the bottom sheet
void showQueryBottomSheet(BuildContext context, {
  required String shopId,
  String? productId,
  required String category,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QueryBottomSheet(
      shopId: shopId,
      productId: productId,
      category: category,
    ),
  );
}
