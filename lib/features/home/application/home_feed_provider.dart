import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_state_providers.dart';
import '../../../models/product_model.dart';

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

  if (shops.isEmpty) {
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
  final followedItems = allItems.where((item) => currentUser.followingShops.contains(item.shopId)).toList();

  if (followedItems.isNotEmpty) {
    followedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    feedItems = followedItems;
  } else {
    List<MixedFeedItem> nearbyItems = allItems.where((item) => item.distance <= 10.0).toList();
    nearbyItems.sort((a, b) => a.distance.compareTo(b.distance));
    nearbyItems = nearbyItems.take(10).toList(); 

    List<MixedFeedItem> interestItems = allItems.where((item) {
      if (item.type == FeedItemType.product) {
        final product = item.item as ProductModel;
        return currentUser.interests.contains(product.category);
      }
      return false;
    }).toList();
    interestItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int nIdx = 0, iIdx = 0;
    final Set<String> addedIds = {};

    while (nIdx < nearbyItems.length || iIdx < interestItems.length) {
      if (nIdx < nearbyItems.length) {
        final item = nearbyItems[nIdx];
        if (!addedIds.contains(item.id)) {
          feedItems.add(item);
          addedIds.add(item.id);
        }
        nIdx++;
      }
      if (iIdx < interestItems.length) {
        final item = interestItems[iIdx];
        if (!addedIds.contains(item.id)) {
          feedItems.add(item);
          addedIds.add(item.id);
        }
        iIdx++;
      }
    }

    if (feedItems.isEmpty) {
      List<MixedFeedItem> remainingItems = List.from(allItems);
      remainingItems.sort((a, b) => a.distance.compareTo(b.distance));
      feedItems = remainingItems.take(10).toList();
    }
  }

  return feedItems;
});
