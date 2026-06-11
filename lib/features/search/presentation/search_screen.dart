import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/common/fallback_image.dart';
import '../../../providers/app_state_providers.dart';
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

  @override
  void initState() {
    super.initState();
    // Auto-focus the search bar when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseProvider);
    
    // Filter logic
    final products = _query.isEmpty 
        ? [] 
        : state.products.where((p) => p.name.toLowerCase().contains(_query.toLowerCase()) || p.description.toLowerCase().contains(_query.toLowerCase())).toList();
    
    final shops = _query.isEmpty 
        ? [] 
        : state.shops.where((s) => s.shopName.toLowerCase().contains(_query.toLowerCase()) || s.category.toLowerCase().contains(_query.toLowerCase())).toList();

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
              onChanged: (val) {
                setState(() {
                  _query = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products, shops...',
                hintStyle: AppTypography.body.copyWith(color: context.colors.textSecondary),
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                          });
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
