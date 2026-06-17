import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/common/fallback_image.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String itemId;
  
  const CommentsBottomSheet({super.key, required this.itemId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final List<Map<String, dynamic>> _mockComments = [
    {
      'username': 'Rahul Sharma',
      'userImage': 'https://i.pravatar.cc/150?img=11',
      'text': 'Wow, that looks amazing! 😍 Is it available in store now?',
      'time': '2h ago',
      'likes': 12,
    },
    {
      'username': 'Priya Patel',
      'userImage': 'https://i.pravatar.cc/150?img=5',
      'text': 'Great quality as always. Will visit soon.',
      'time': '5h ago',
      'likes': 4,
    },
    {
      'username': 'Amit Kumar',
      'userImage': 'https://i.pravatar.cc/150?img=33',
      'text': 'Price please?',
      'time': '1d ago',
      'likes': 0,
    },
  ];

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    setState(() {
      _mockComments.insert(0, {
        'username': 'You',
        'userImage': '',
        'text': _commentController.text.trim(),
        'time': 'Just now',
        'likes': 0,
      });
      _commentController.clear();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s16, bottom: AppSpacing.s8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: AppSpacing.s8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Comments', style: AppTypography.heading.copyWith(fontSize: 18)),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 24),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Comments List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(AppSpacing.mobilePadding),
                  itemCount: _mockComments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final comment = _mockComments[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FallbackAvatar(
                          imageUrl: comment['userImage'],
                          name: comment['username'],
                          radius: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment['username'],
                                    style: AppTypography.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    comment['time'],
                                    style: AppTypography.caption.copyWith(
                                      color: context.colors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment['text'],
                                style: AppTypography.body.copyWith(
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Reply',
                                    style: AppTypography.caption.copyWith(
                                      color: context.colors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Icon(LucideIcons.heart, size: 16, color: context.colors.textSecondary),
                            if (comment['likes'] > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '${comment['likes']}',
                                  style: AppTypography.caption.copyWith(
                                    color: context.colors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Input Field
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  border: Border(
                    top: BorderSide(color: context.colors.border, width: 0.5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.mobilePadding,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const FallbackAvatar(
                      imageUrl: '',
                      name: 'You',
                      radius: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.background,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.colors.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: AppTypography.body.copyWith(fontSize: 14),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _addComment(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder(
                      valueListenable: _commentController,
                      builder: (context, value, child) {
                        final hasText = value.text.trim().isNotEmpty;
                        return IconButton(
                          icon: Icon(
                            LucideIcons.send,
                            color: hasText ? context.colors.primary : context.colors.textSecondary.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          onPressed: hasText ? _addComment : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showCommentsBottomSheet(BuildContext context, {required String itemId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    builder: (context) => CommentsBottomSheet(itemId: itemId),
  );
}
