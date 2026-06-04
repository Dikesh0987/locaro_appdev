import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/post_model.dart';

class PostManagementScreen extends ConsumerStatefulWidget {
  const PostManagementScreen({super.key});

  @override
  ConsumerState<PostManagementScreen> createState() => _PostManagementScreenState();
}

class _PostManagementScreenState extends ConsumerState<PostManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _captionController = TextEditingController();
  PostType _selectedType = PostType.product;
  String? _imageUrl;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _submitPost() {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or upload a post photo')),
      );
      return;
    }

    final shop = ref.read(databaseProvider).currentShop;

    final newPost = PostModel(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      shopId: shop.id,
      type: _selectedType,
      caption: _captionController.text,
      image: _imageUrl!,
      likes: 0,
      comments: 0,
      createdAt: DateTime.now(),
    );

    ref.read(databaseProvider.notifier).addPost(newPost);

    // Reset Form
    _captionController.clear();
    setState(() {
      _imageUrl = null;
      _selectedType = PostType.product;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post published successfully to local Feed!')),
    );
    
    // Jump user to home tab (which corresponds to Dashboard, or if they want they can see it in feed when logging back as user)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switch role in Profile tab to see it on User Home Feed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.mobilePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Publish Shop Update', style: AppTypography.heading),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Publish product updates, announcements, or custom limited offers to neighborhood feeds.',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.s24),

              // Post Type Selector
              Text('Select Post Category', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  _buildTypeTab(PostType.product, 'Product', LucideIcons.shoppingBag),
                  const SizedBox(width: AppSpacing.s8),
                  _buildTypeTab(PostType.offer, 'Offer Coupon', LucideIcons.percent),
                  const SizedBox(width: AppSpacing.s8),
                  _buildTypeTab(PostType.update, 'Status Update', LucideIcons.sparkles),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),

              // Image simulation picker
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedType == PostType.offer) {
                      _imageUrl = 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600';
                    } else if (_selectedType == PostType.product) {
                      _imageUrl = 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600';
                    } else {
                      _imageUrl = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600';
                    }
                  });
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    image: _imageUrl != null ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover) : null,
                  ),
                  alignment: Alignment.center,
                  child: _imageUrl == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.image, size: 36, color: AppColors.textSecondary),
                            SizedBox(height: 8),
                            Text('Tap to simulate choosing photo', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),

              // Caption input
              Text('Caption Text', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.s12),
              TextFormField(
                controller: _captionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'What is happening in your shop today?',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a caption' : null,
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Publish Post',
                onPressed: _submitPost,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(PostType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.surface : AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
