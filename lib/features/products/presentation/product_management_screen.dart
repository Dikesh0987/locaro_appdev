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
import '../../../core/widgets/navigation/top_app_bar.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen> {
  String _selectedCategory = 'All';

  void _showProductForm(BuildContext context, {ProductModel? product}) {
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
  Widget build(BuildContext context) {
    final state = ref.watch(databaseProvider);
    final shop = state.currentShop;
    
    // Filter products belonging to this shop owner
    final shopProducts = state.products.where((p) => p.shopId == shop.id).toList();
    
    final categories = ['All', ...shopProducts.map((p) => p.category).toSet().toList()];
    
    // Reset category if it doesn't exist anymore
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }

    final displayedProducts = _selectedCategory == 'All' 
        ? shopProducts 
        : shopProducts.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      appBar: const TopAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(context),
        backgroundColor: context.colors.primary,
        child: Icon(LucideIcons.plus, color: context.colors.surface),
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
                      onPressed: () => _showProductForm(context),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.mobilePadding, vertical: 12),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat == 'All' ? 'All Products' : cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                          selectedColor: context.colors.primary,
                          backgroundColor: context.colors.surface,
                          side: BorderSide(
                            color: isSelected ? context.colors.primary : context.colors.border,
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? context.colors.surface : context.colors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: displayedProducts.isEmpty
                      ? Center(
                          child: Text(
                            'No products in $_selectedCategory category.',
                            style: AppTypography.body.copyWith(color: context.colors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.mobilePadding).copyWith(top: 0),
                          itemCount: displayedProducts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s12),
                          itemBuilder: (context, index) {
                            final p = displayedProducts[index];
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
                                      onPressed: () => _showProductForm(context, product: p),
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
                ),
              ],
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
  List<String> _existingImages = [];
  List<File> _selectedImageFiles = [];
  bool _isUploading = false;

  final List<String> _categories = ['Cafe', 'Groceries', 'Electronics', 'Fashion', 'Bakery', 'Mobiles', 'Accessories', 'Home & Kitchen', 'Beauty', 'Sports', 'Toys', 'Hardware', 'Services'];

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
    _existingImages = widget.product?.images.toList() ?? [];
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

  Future<void> _pickImages() async {
    final currentTotal = _existingImages.length + _selectedImageFiles.length;
    if (currentTotal >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only upload a maximum of 6 photos.')));
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 75);
    
    if (images.isNotEmpty) {
      final allowedCount = 6 - currentTotal;
      final imagesToAdd = images.take(allowedCount).map((img) => File(img.path)).toList();
      
      setState(() {
        _selectedImageFiles.addAll(imagesToAdd);
      });

      if (images.length > allowedCount) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 6 photos allowed. Only the first few were added.')),
          );
        }
      }
    }
  }

  Future<void> _saveProduct() async {
    if (_isUploading) return;
    if (!_formKey.currentState!.validate()) return;
    
    if (_existingImages.isEmpty && _selectedImageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one product image.')));
      return;
    }

    setState(() => _isUploading = true);

    // Extract variables immediately before pop
    final shop = ref.read(databaseProvider).currentShop;
    final productId = widget.product?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}';
    final name = _nameController.text;
    final desc = _descController.text;
    final price = double.parse(_priceController.text);
    final discountStr = _discountController.text;
    final discount = discountStr.isNotEmpty ? double.parse(discountStr) : null;
    final stock = int.parse(_stockController.text);
    final category = _selectedCategory;
    final isNew = widget.product == null;
    final oldProduct = widget.product;
    final newImageFiles = List<File>.from(_selectedImageFiles);
    final existingImages = List<String>.from(_existingImages);
    final databaseNotifier = ref.read(databaseProvider.notifier);
    final authRepo = ref.read(authRepositoryProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Close modal immediately and show toast
    Navigator.pop(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(isNew ? 'Uploading product in background...' : 'Saving changes in background...')),
    );

    // Run in background (fire and forget)
    Future(() async {
      try {
        List<String> finalImageUrls = [...existingImages];

        for (int i = 0; i < newImageFiles.length; i++) {
          final file = newImageFiles[i];
          final url = await authRepo.uploadShopAsset(shop.id, 'product_${productId}_${DateTime.now().millisecondsSinceEpoch}_$i', file);
          finalImageUrls.add(url);
        }

        if (isNew) {
          final newProduct = ProductModel(
            id: productId,
            shopId: shop.id,
            name: name,
            images: finalImageUrls,
            description: desc,
            price: price,
            discountPrice: discount,
            stock: stock,
            category: category,
            likes: 0,
            views: 0,
            createdAt: DateTime.now(),
          );
          await databaseNotifier.addProduct(newProduct);
        } else {
          final updatedProduct = oldProduct!.copyWith(
            name: name,
            images: finalImageUrls,
            description: desc,
            price: price,
            discountPrice: discount,
            stock: stock,
            category: category,
          );
          await databaseNotifier.editProduct(updatedProduct);
        }
        
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(isNew ? 'Product added successfully!' : 'Product updated successfully!')),
        );
      } catch (e) {
        debugPrint('Error uploading product: $e');
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    });
  }

  Widget _buildImageThumbnail({String? url, File? file}) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: context.colors.border,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        image: file != null
            ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
            : (url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (file != null) {
                    _selectedImageFiles.remove(file);
                  } else if (url != null) {
                    _existingImages.remove(url);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
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

              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_existingImages.length + _selectedImageFiles.length < 6)
                      GestureDetector(
                        onTap: _isUploading ? null : _pickImages,
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: context.colors.border,
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.plus, size: 28),
                              SizedBox(height: 4),
                              Text('Add Photo', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ..._existingImages.map((url) => _buildImageThumbnail(url: url)),
                    ..._selectedImageFiles.map((file) => _buildImageThumbnail(file: file)),
                  ],
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
