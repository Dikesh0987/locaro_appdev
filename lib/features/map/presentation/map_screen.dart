import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/cards/base_card.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/shop_model.dart';
import '../../shop/presentation/shop_profile_screen.dart';
import '../../../core/widgets/common/fallback_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  ShopModel? _selectedShop;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(databaseProvider);
    final shops = state.shops;
    final offers = state.offers;

    return Scaffold(
      body: Stack(
        children: [
          // Flutter Map Integration
          FlutterMap(
            options: MapOptions(
              initialCenter: state.currentUser.latitude != 0.0 
                  ? LatLng(state.currentUser.latitude, state.currentUser.longitude) 
                  : const LatLng(28.6273, 77.3725), // Fallback if no user location
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.Locaro.app',
              ),
              MarkerLayer(
                markers: shops.where((s) => s.latitude != 0.0 && s.longitude != 0.0).map((shop) {
                  final hasOffer = offers.any((o) => o.shopId == shop.id);
                  final isSelected = _selectedShop?.id == shop.id;

                  return Marker(
                    point: LatLng(shop.latitude, shop.longitude),
                    width: 120,
                    height: 50,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedShop = shop;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? context.colors.primary : context.colors.surface,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: context.colors.border, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasOffer ? LucideIcons.percent : LucideIcons.store,
                                  size: 12,
                                  color: isSelected
                                      ? context.colors.surface
                                      : (hasOffer ? context.colors.offerOrange : context.colors.primary),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    shop.shopName,
                                    style: AppTypography.label.copyWith(
                                      color: isSelected ? context.colors.surface : context.colors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CustomPaint(
                            size: const Size(10, 8),
                            painter: _TrianglePainter(
                              color: isSelected ? context.colors.primary : context.colors.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Floating Top Search Bar
          Positioned(
            top: 50,
            left: AppSpacing.mobilePadding,
            right: AppSpacing.mobilePadding,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                border: Border.all(color: context.colors.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Icon(LucideIcons.search, color: context.colors.textSecondary),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Text(
                      'Search area...',
                      style: AppTypography.body.copyWith(color: context.colors.textSecondary),
                    ),
                  ),
                  Icon(LucideIcons.slidersHorizontal, color: context.colors.textSecondary),
                ],
              ),
            ),
          ),

          // Store Preview Card at Bottom
          if (_selectedShop != null)
            Positioned(
              bottom: AppSpacing.s16,
              left: AppSpacing.mobilePadding,
              right: AppSpacing.mobilePadding,
              child: BaseCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: FallbackImage(
                              imageUrl: _selectedShop!.logo,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedShop!.shopName,
                                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedShop!.category,
                                  style: AppTypography.label.copyWith(color: context.colors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.star, size: 12, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      _selectedShop!.rating.toString(),
                                      style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _selectedShop = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: context.colors.border,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.x, size: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: context.colors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShopProfileScreen(shopId: _selectedShop!.id),
                                  ),
                                );
                              },
                              child: Text('View Store', style: TextStyle(color: context.colors.textPrimary)),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(LucideIcons.navigation, size: 14, color: Colors.white),
                              label: const Text('Directions', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Directions to ${_selectedShop!.shopName} simulated.'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Removed Mock MapPainter

// Small pointer pin triangle pointing downwards
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
