import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/product_model.dart';
import '../../../models/shop_model.dart';
import '../../products/presentation/product_details_screen.dart';
import '../../shop/presentation/shop_profile_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  Timer? _debounce;
  bool _isSearching = false;
  List<ProductModel> _searchResults = [];
  List<ShopModel> _shopResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() => _query = val);
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(val);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _shopResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Capitalize first letter to match common Firestore stored strings since it's case sensitive
      String searchStr = query.isNotEmpty ? query[0].toUpperCase() + query.substring(1) : query;
      
      final pDocs = await FirebaseFirestore.instance.collection('products')
          .where('name', isGreaterThanOrEqualTo: searchStr)
          .where('name', isLessThan: '$searchStr\uf8ff')
          .limit(20).get();
      
      final sDocs = await FirebaseFirestore.instance.collection('shops')
          .where('shopName', isGreaterThanOrEqualTo: searchStr)
          .where('shopName', isLessThan: '$searchStr\uf8ff')
          .limit(20).get();

      if (mounted) {
        setState(() {
          _searchResults = pDocs.docs.map((d) => ProductModel.fromMap(d.data())).toList();
          _shopResults = sDocs.docs.map((d) => ShopModel.fromMap(d.data())).toList();
        });
      }
    } catch (e) {
      // Silent fail
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseProvider);
    
    // Combine local results (case-insensitive) with Firebase prefix results
    final localProducts = _query.isEmpty ? <ProductModel>[] : state.products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase()) || p.description.toLowerCase().contains(_query.toLowerCase())).toList();
    final localShops = _query.isEmpty ? <ShopModel>[] : state.shops.where((s) => s.shopName.toLowerCase().contains(_query.toLowerCase()) || s.category.toLowerCase().contains(_query.toLowerCase())).toList();

    final products = {...localProducts, ..._searchResults}.toList();
    final shops = {...localShops, ..._shopResults}.toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: context.colors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.mobilePadding),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              border: Border.all(color: context.colors.border),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search products, shops...',
                hintStyle: AppTypography.body.copyWith(color: context.colors.textSecondary),
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.search, size: 64, color: context.colors.border),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'Search for anything',
                    style: AppTypography.heading.copyWith(color: context.colors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Find products, shops, and offers near you',
                    style: AppTypography.body.copyWith(color: context.colors.textSecondary),
                  ),
                ],
              ),
            )
          : _isSearching 
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty && shops.isEmpty
                  ? Center(
                      child: Text(
                        'No results found for "$_query"',
                        style: AppTypography.body.copyWith(color: context.colors.textSecondary),
                      ),
                    )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.mobilePadding),
                  children: [
                    if (products.isNotEmpty) ...[
                      Text(
                        'Products',
                        style: AppTypography.subheading.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      ...products.map((p) {
                        final shop = state.shops.firstWhere((s) => s.id == p.shopId, orElse: () => state.currentShop);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FallbackImage(
                              imageUrl: p.images.isNotEmpty ? p.images.first : '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            p.name,
                            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '₹${p.discountPrice?.toStringAsFixed(0) ?? p.price.toStringAsFixed(0)} • ${shop.shopName}',
                            style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(productId: p.id),
                              ),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: AppSpacing.sectionGap),
                    ],
                    if (shops.isNotEmpty) ...[
                      Text(
                        'Shops',
                        style: AppTypography.subheading.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      ...shops.map((s) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FallbackImage(
                              imageUrl: s.logo,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            s.shopName,
                            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            s.category,
                            style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShopProfileScreen(shopId: s.id),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ],
                ),
    );
  }
}
