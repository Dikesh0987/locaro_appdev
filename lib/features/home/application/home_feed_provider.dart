import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_state_providers.dart';

enum FeedItemType { post, product, offer }

class MixedFeedItem {
  final String id;
  final String shopId;
  final FeedItemType type;
  final dynamic item; // PostModel, ProductModel, or OfferModel
  final double distance;
  final DateTime createdAt;

  MixedFeedItem({
    required this.id,
    required this.shopId,
    required this.type,
    required this.item,
    required this.distance,
    required this.createdAt,
  });
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // Math.PI / 180
  final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) *
      (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
}

final homeFeedProvider = Provider<List<MixedFeedItem>>((ref) {
  final state = ref.watch(databaseProvider);
  final currentUser = state.currentUser;
  final shops = state.shops;
  final posts = state.posts;
  final offers = state.offers;
  final products = state.products;

  // Early exit: skip expensive computation while data is still loading
  if (state.isLoading || shops.isEmpty) {
    return [];
  }

  final Map<String, double> shopDistances = {};
  for (final shop in shops) {
    final distance = _calculateDistance(
      currentUser.latitude,
      currentUser.longitude,
      shop.latitude,
      shop.longitude,
    );
    shopDistances[shop.id] = distance;
  }

  final List<MixedFeedItem> allItems = [];

  for (final post in posts) {
    allItems.add(MixedFeedItem(
      id: post.id,
      shopId: post.shopId,
      type: FeedItemType.post,
      item: post,
      distance: shopDistances[post.shopId] ?? 999.0,
      createdAt: post.createdAt,
    ));
  }

  for (final offer in offers) {
    allItems.add(MixedFeedItem(
      id: offer.id,
      shopId: offer.shopId,
      type: FeedItemType.offer,
      item: offer,
      distance: shopDistances[offer.shopId] ?? 999.0,
      createdAt: offer.createdAt,
    ));
  }

  for (final product in products) {
    allItems.add(MixedFeedItem(
      id: product.id,
      shopId: product.shopId,
      type: FeedItemType.product,
      item: product,
      distance: shopDistances[product.shopId] ?? 999.0,
      createdAt: product.createdAt,
    ));
  }

  List<MixedFeedItem> feedItems = [];
  
  // Get all items from followed shops
  final followedItems = allItems.where((item) => currentUser.followingShops.contains(item.shopId)).toList();
  
  // Get all items from nearby shops within 100km (excluding those already in followedItems)
  final nearbyItems = allItems.where((item) => 
    !currentUser.followingShops.contains(item.shopId) && item.distance <= 100.0
  ).toList();

  // Combine both lists
  feedItems.addAll(followedItems);
  feedItems.addAll(nearbyItems);

  // If still empty (no followed and no nearby within 100km), fallback to showing closest shops
  if (feedItems.isEmpty) {
    List<MixedFeedItem> remainingItems = List.from(allItems);
    remainingItems.sort((a, b) => a.distance.compareTo(b.distance));
    feedItems = remainingItems.take(20).toList();
  } else {
    // Sort combined list by creation date, newest first
    feedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return feedItems;
});
