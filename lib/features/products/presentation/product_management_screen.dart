import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/product_model.dart';
import '../../auth/data/auth_repository.dart';

class ProductManagementScreen extends ConsumerWidget {
  const ProductManagementScreen({super.key});

  void _showProductForm(BuildContext context, WidgetRef ref, {ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
      ),
      builder: (context) => _ProductFormSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseProvider);
    final shop = state.currentShop;
    
    // Filter products belonging to this shop owner
    final shopProducts = state.products.where((p) => p.shopId == shop.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus, color: context.colors.primary),
            onPressed: () => _showProductForm(context, ref),
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: shopProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.shoppingBag, size: 48, color: context.colors.border),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'No products in your catalog yet.',
                    style: AppTypography.body.copyWith(color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  SizedBox(
                    width: 180,
                    child: PrimaryButton(
                      text: 'Add Product',
                      onPressed: () => _showProductForm(context, ref),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.mobilePadding),
              itemCount: shopProducts.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                final p = shopProducts[index];
                return BaseCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: FallbackImage(
                            imageUrl: p.images.isNotEmpty ? p.images.first : '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Stock: ${p.stock}',
                                    style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${p.discountPrice?.toStringAsFixed(0) ?? p.price.toStringAsFixed(0)}',
                                    style: AppTypography.label.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.edit3, size: 16),
                          onPressed: () => _showProductForm(context, ref, product: p),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.trash2, size: 16, color: context.colors.error),
                          onPressed: () {
                            ref.read(databaseProvider.notifier).deleteProduct(p.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Product deleted successfully')),
                            );
                          },
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

class _ProductFormSheet extends ConsumerStatefulWidget {
  final ProductModel? product;

  const _ProductFormSheet({this.product});

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _stockController;
  late String _selectedCategory;
  String? _imageUrl;
  File? _selectedImageFile;
  bool _isUploading = false;

  final List<String> _categories = ['Cafe', 'Groceries', 'Electronics', 'Fashion', 'Bakery'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _discountController = TextEditingController(
        text: widget.product?.discountPrice != null ? widget.product!.discountPrice.toString() : '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '10');
    _selectedCategory = widget.product?.category ?? 'Cafe';
    _imageUrl = widget.product?.images.isNotEmpty == true ? widget.product?.images.first : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null) {
      setState(() {
        _selectedImageFile = File(image.path);
        _imageUrl = null; // Clear network image since we have local file now
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_isUploading) return;
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageUrl == null && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a product image.')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final shop = ref.read(databaseProvider).currentShop;
      String finalImageUrl = _imageUrl ?? '';
      final productId = widget.product?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}';

      if (_selectedImageFile != null) {
        finalImageUrl = await ref.read(authRepositoryProvider).uploadShopAsset(shop.id, 'product_$productId', _selectedImageFile!);
      }

      if (widget.product == null) {
        final newProduct = ProductModel(
          id: productId,
          shopId: shop.id,
          name: _nameController.text,
          images: [finalImageUrl],
          description: _descController.text,
          price: double.parse(_priceController.text),
          discountPrice: _discountController.text.isNotEmpty ? double.parse(_discountController.text) : null,
          stock: int.parse(_stockController.text),
          category: _selectedCategory,
          likes: 0,
          views: 0,
          createdAt: DateTime.now(),
        );
        ref.read(databaseProvider.notifier).addProduct(newProduct);
      } else {
        final updatedProduct = widget.product!.copyWith(
          name: _nameController.text,
          images: [finalImageUrl],
          description: _descController.text,
          price: double.parse(_priceController.text),
          discountPrice: _discountController.text.isNotEmpty ? double.parse(_discountController.text) : null,
          stock: int.parse(_stockController.text),
          category: _selectedCategory,
        );
        ref.read(databaseProvider.notifier).editProduct(updatedProduct);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.product == null ? 'Product added successfully' : 'Product updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
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
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.mobilePadding,
        right: AppSpacing.mobilePadding,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product == null ? 'Add Product' : 'Edit Product',
                style: AppTypography.heading,
              ),
              const SizedBox(height: AppSpacing.s24),

              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 120,
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
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.image, size: 28),
                            SizedBox(height: 4),
                            Text('Tap to add product photo', style: TextStyle(fontSize: 10)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),

              AppTextField(
                controller: _nameController,
                hintText: 'Product Name',
                validator: (val) => val == null || val.isEmpty ? 'Field required' : null,
              ),
              const SizedBox(height: AppSpacing.s12),
              
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Product Description',
                ),
                validator: (val) => val == null || val.isEmpty ? 'Field required' : null,
              ),
              const SizedBox(height: AppSpacing.s12),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _priceController,
                      hintText: 'Price (₹)',
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: AppTextField(
                      controller: _discountController,
                      hintText: 'Discount Price (₹)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _stockController,
                      hintText: 'Stock Count',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                        border: Border.all(color: context.colors.border),
                      ),
                      alignment: Alignment.center,
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(c, style: AppTypography.body),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s24),

              PrimaryButton(
                text: _isUploading ? 'Uploading...' : (widget.product == null ? 'Create Product' : 'Save Changes'),
                onPressed: _isUploading ? () {} : _saveProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
