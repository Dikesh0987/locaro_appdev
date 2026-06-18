import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/common/fallback_image.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/comments_provider.dart';
import '../../../providers/app_state_providers.dart';
import '../../../core/utils/time_ago.dart';
import '../../auth/application/auth_service.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final String itemId;
  
  const CommentsBottomSheet({super.key, required this.itemId});

  @override
  ConsumerState<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    
    ref.read(authServiceProvider).checkGuest(
      context,
      onAllowed: () {
        final text = _commentController.text.trim();
        _commentController.clear();
        FocusScope.of(context).unfocus();
        ref.read(databaseProvider.notifier).addComment(widget.itemId, text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.itemId));
    final currentUser = ref.watch(databaseProvider).currentUser;

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
                child: commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.s32),
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first to comment!',
                            style: AppTypography.body.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(AppSpacing.mobilePadding),
                      itemCount: comments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 20),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FallbackAvatar(
                              imageUrl: comment.userImage,
                              name: comment.userName,
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
                                        comment.userName,
                                        style: AppTypography.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        timeAgo(comment.createdAt),
                                        style: AppTypography.caption.copyWith(
                                          color: context.colors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.text,
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
                                if (comment.likes > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '${comment.likes}',
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
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.s32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.s32),
                    child: Center(
                      child: Text(
                        'Failed to load comments',
                        style: AppTypography.body.copyWith(
                          color: context.colors.error,
                        ),
                      ),
                    ),
                  ),
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
                    FallbackAvatar(
                      imageUrl: currentUser.profileImage,
                      name: currentUser.name,
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
