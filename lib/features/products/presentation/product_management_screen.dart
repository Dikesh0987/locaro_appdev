import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/product_model.dart';

class ProductManagementScreen extends ConsumerWidget {
  const ProductManagementScreen({super.key});

  void _showProductForm(BuildContext context, WidgetRef ref, {ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
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
            icon: const Icon(LucideIcons.plus, color: AppColors.primary),
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
                  Icon(LucideIcons.shoppingBag, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    'No products in your catalog yet.',
                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
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
                          child: Image.network(
                            p.images.first,
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
                                    style: AppTypography.label.copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${p.discountPrice?.toStringAsFixed(0) ?? p.price.toStringAsFixed(0)}',
                                    style: AppTypography.label.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
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
                          icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
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
    _imageUrl = widget.product?.images.first;
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

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    final shop = ref.read(databaseProvider).currentShop;

    if (widget.product == null) {
      // Add logic
      final newProduct = ProductModel(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        shopId: shop.id,
        name: _nameController.text,
        images: [_imageUrl ?? 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500'],
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
      // Edit logic
      final updatedProduct = widget.product!.copyWith(
        name: _nameController.text,
        images: [_imageUrl ?? widget.product!.images.first],
        description: _descController.text,
        price: double.parse(_priceController.text),
        discountPrice: _discountController.text.isNotEmpty ? double.parse(_discountController.text) : null,
        stock: int.parse(_stockController.text),
        category: _selectedCategory,
      );
      ref.read(databaseProvider.notifier).editProduct(updatedProduct);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.product == null ? 'Product added successfully' : 'Product updated successfully')),
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

              // Image Mock Input
              GestureDetector(
                onTap: () {
                  setState(() => _imageUrl = 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500');
                },
                child: Container(
                  height: 120,
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
                            Icon(LucideIcons.image, size: 28),
                            SizedBox(height: 4),
                            Text('Tap to simulate adding product photo', style: TextStyle(fontSize: 10)),
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                        border: Border.all(color: AppColors.border),
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
                text: widget.product == null ? 'Create Product' : 'Save Changes',
                onPressed: _saveProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
