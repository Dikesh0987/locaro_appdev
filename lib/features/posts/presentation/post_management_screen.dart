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
import '../../../core/widgets/navigation/top_app_bar.dart';
import '../../../core/widgets/common/fallback_image.dart';

class PostManagementScreen extends ConsumerStatefulWidget {
  const PostManagementScreen({super.key});

  @override
  ConsumerState<PostManagementScreen> createState() => _PostManagementScreenState();
}

class _PostManagementScreenState extends ConsumerState<PostManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _offerTitleController = TextEditingController();
  final TextEditingController _offerDiscountController = TextEditingController();
  final TextEditingController _offerValidityController = TextEditingController();
  
  PostType _selectedType = PostType.product;
  String? _imageUrl;
  String? _selectedProductId;

  File? _selectedImageFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    _offerTitleController.dispose();
    _offerDiscountController.dispose();
    _offerValidityController.dispose();
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
    if (_isUploading) return;
    if (!_formKey.currentState!.validate()) return;
    
    final isProduct = _selectedType == PostType.product;
    final isOffer = _selectedType == PostType.offer;
    final database = ref.read(databaseProvider);
    
    if (isOffer && (_offerTitleController.text.isEmpty || _offerDiscountController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill offer details')));
      return;
    }
    
    if (isProduct && _selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a product to feature')));
      return;
    }

    String finalImageUrl = _imageUrl ?? '';
    
    if (isProduct && _selectedProductId != null) {
      final p = database.products.where((x) => x.id == _selectedProductId).firstOrNull;
      if (p != null && finalImageUrl.isEmpty && _selectedImageFile == null) {
        finalImageUrl = p.images.isNotEmpty ? p.images.first : '';
      }
    }

    if (finalImageUrl.isEmpty && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or upload a post photo')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final shop = database.currentShop;
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
        linkedProductId: isProduct ? _selectedProductId : null,
        likes: 0,
        comments: 0,
        createdAt: DateTime.now(),
      );

      await ref.read(databaseProvider.notifier).addPost(
        newPost,
        offerTitle: isOffer ? _offerTitleController.text : null,
        offerDiscount: isOffer ? _offerDiscountController.text : null,
        offerValidityDays: isOffer ? int.tryParse(_offerValidityController.text) : null,
      );

      // Reset Form
      if (mounted) {
        _captionController.clear();
        _offerTitleController.clear();
        _offerDiscountController.clear();
        _offerValidityController.clear();
        setState(() {
          _imageUrl = null;
          _selectedImageFile = null;
          _selectedProductId = null;
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
      appBar: const TopAppBar(),
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

              // --- PRODUCT POST UI ---
              if (_selectedType == PostType.product) ...[
                Text('Feature a Product', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.s12),
                Consumer(
                  builder: (context, ref, _) {
                    final shop = ref.watch(databaseProvider).currentShop;
                    final shopProducts = ref.watch(databaseProvider).products.where((p) => p.shopId == shop.id).toList();
                    if (shopProducts.isEmpty) {
                      return Text('No products available. Please create a product first.', style: TextStyle(color: context.colors.error));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedProductId != null && shopProducts.any((p) => p.id == _selectedProductId) ? _selectedProductId : null,
                          hint: const Text('Select a Product'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.inputRadius)),
                          ),
                          items: shopProducts.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                          onChanged: (val) => setState(() => _selectedProductId = val),
                        ),
                        if (_selectedProductId != null) ...[
                          SizedBox(height: AppSpacing.s16),
                          Builder(builder: (ctx) {
                            final p = shopProducts.firstWhere(
                              (x) => x.id == _selectedProductId,
                              orElse: () => shopProducts.first,
                            );
                            return Container(
                              padding: const EdgeInsets.all(AppSpacing.s12),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                border: Border.all(color: context.colors.border),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      color: context.colors.border,
                                      child: p.images.isNotEmpty
                                          ? FallbackImage(imageUrl: p.images.first, fit: BoxFit.cover)
                                          : Icon(LucideIcons.image, color: context.colors.textSecondary),
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.s12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        SizedBox(height: 4),
                                        Text('₹${p.discountPrice?.toStringAsFixed(0) ?? p.price.toStringAsFixed(0)}', style: AppTypography.caption.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    );
                  },
                ),
                SizedBox(height: AppSpacing.s24),
                Text('Add Custom Caption (Optional)', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.s12),
                TextFormField(
                  controller: _captionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Say something about this product...',
                  ),
                ),
                SizedBox(height: AppSpacing.s24),
              ],

              // --- OFFER POST UI ---
              if (_selectedType == PostType.offer) ...[
                Text('Offer Details', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.s12),
                TextFormField(
                  controller: _offerTitleController,
                  decoration: InputDecoration(
                    hintText: 'Offer Title (e.g. Diwali Mega Sale)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.inputRadius)),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                SizedBox(height: AppSpacing.s12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _offerDiscountController,
                        decoration: InputDecoration(
                          hintText: 'Discount (e.g. 50% OFF)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.inputRadius)),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: TextFormField(
                        controller: _offerValidityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Validity (Days)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.inputRadius)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.s24),
                Text('Offer Banner Image', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.s12),
                _buildImagePicker(context),
                SizedBox(height: AppSpacing.s24),
                Text('Caption Text', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.s12),
                TextFormField(
                  controller: _captionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Write details about this offer...',
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter a caption' : null,
                ),
                SizedBox(height: AppSpacing.s24),
              ],

              // --- STATUS UPDATE POST UI ---
              if (_selectedType == PostType.update) ...[
                Text('Status Image', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.s12),
                _buildImagePicker(context),
                SizedBox(height: AppSpacing.s24),
                Text('Status Update Text', style: AppTypography.subheading.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.s12),
                TextFormField(
                  controller: _captionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'What is happening in your shop today?',
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter a caption' : null,
                ),
                SizedBox(height: AppSpacing.s24),
              ],

              SizedBox(height: 8),

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
        onTap: () {
          setState(() {
            _selectedType = type;
            _imageUrl = null;
            _selectedImageFile = null;
            _captionController.clear();
          });
        },
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return GestureDetector(
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
    );
  }
}
