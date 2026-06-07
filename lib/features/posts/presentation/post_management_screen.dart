import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/post_model.dart';
import '../../auth/data/auth_repository.dart';

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

  File? _selectedImageFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null) {
      setState(() {
        _selectedImageFile = File(image.path);
        _imageUrl = null; // Clear network image
      });
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or upload a post photo')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final shop = ref.read(databaseProvider).currentShop;
      String finalImageUrl = _imageUrl ?? '';
      final postId = 'post_${DateTime.now().millisecondsSinceEpoch}';

      if (_selectedImageFile != null) {
        finalImageUrl = await ref.read(authRepositoryProvider).uploadShopAsset(shop.id, 'post_$postId', _selectedImageFile!);
      }

      final newPost = PostModel(
        id: postId,
        shopId: shop.id,
        type: _selectedType,
        caption: _captionController.text,
        image: finalImageUrl,
        likes: 0,
        comments: 0,
        createdAt: DateTime.now(),
      );

      ref.read(databaseProvider.notifier).addPost(newPost);

      // Reset Form
      if (mounted) {
        _captionController.clear();
        setState(() {
          _imageUrl = null;
          _selectedImageFile = null;
          _selectedType = PostType.product;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published successfully to local Feed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing post: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
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
              SizedBox(height: AppSpacing.s8),
              Text(
                'Publish product updates, announcements, or custom limited offers to neighborhood feeds.',
                style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
              ),
              SizedBox(height: AppSpacing.s24),

              // Post Type Selector
              Text('Select Post Category', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  _buildTypeTab(PostType.product, 'Product', LucideIcons.shoppingBag),
                  SizedBox(width: AppSpacing.s8),
                  _buildTypeTab(PostType.offer, 'Offer Coupon', LucideIcons.percent),
                  SizedBox(width: AppSpacing.s8),
                  _buildTypeTab(PostType.update, 'Status Update', LucideIcons.sparkles),
                ],
              ),
              SizedBox(height: AppSpacing.s24),

              // Image simulation picker
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    image: _selectedImageFile != null
                        ? DecorationImage(image: FileImage(_selectedImageFile!), fit: BoxFit.cover)
                        : (_imageUrl != null ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover) : null),
                  ),
                  alignment: Alignment.center,
                  child: _selectedImageFile == null && _imageUrl == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.image, size: 36, color: context.colors.textSecondary),
                            SizedBox(height: 8),
                            Text('Tap to choose photo', style: TextStyle(color: context.colors.textSecondary)),
                          ],
                        )
                      : null,
                ),
              ),
              SizedBox(height: AppSpacing.s24),

              // Caption input
              Text('Caption Text', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: AppSpacing.s12),
              TextFormField(
                controller: _captionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'What is happening in your shop today?',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a caption' : null,
              ),
              SizedBox(height: 32),

              PrimaryButton(
                text: _isUploading ? 'Publishing...' : 'Publish Post',
                onPressed: _isUploading ? () {} : _submitPost,
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
            color: isSelected ? context.colors.primary : context.colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: Border.all(color: isSelected ? context.colors.primary : context.colors.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? context.colors.surface : context.colors.primary),
              SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: isSelected ? context.colors.surface : context.colors.textPrimary,
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
