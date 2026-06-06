import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';
import '../models/post_model.dart';
import '../models/offer_model.dart';
import '../models/lead_model.dart';
import '../repositories/nearo_repository.dart';


// State wrapper for the in-memory database
class NearoDataState {
  final List<ShopModel> shops;
  final List<ProductModel> products;
  final List<OfferModel> offers;
  final List<PostModel> posts;
  final List<LeadModel> leads;
  final UserModel currentUser;
  final ShopModel currentShop;

  NearoDataState({
    required this.shops,
    required this.products,
    required this.offers,
    required this.posts,
    required this.leads,
    required this.currentUser,
    required this.currentShop,
  });

  NearoDataState copyWith({
    List<ShopModel>? shops,
    List<ProductModel>? products,
    List<OfferModel>? offers,
    List<PostModel>? posts,
    List<LeadModel>? leads,
    UserModel? currentUser,
    ShopModel? currentShop,
  }) {
    return NearoDataState(
      shops: shops ?? this.shops,
      products: products ?? this.products,
      offers: offers ?? this.offers,
      posts: posts ?? this.posts,
      leads: leads ?? this.leads,
      currentUser: currentUser ?? this.currentUser,
      currentShop: currentShop ?? this.currentShop,
    );
  }
}

// Database notifier that handles all CRUD and in-memory updates synced with Firestore
class NearoDatabaseNotifier extends Notifier<NearoDataState> {
  StreamSubscription? _shopsSub;
  StreamSubscription? _productsSub;
  StreamSubscription? _postsSub;
  StreamSubscription? _offersSub;
  StreamSubscription? _leadsSub;

  @override
  NearoDataState build() {
    _listenToFirestore();
    _seedDatabaseIfNeeded();

    // Clean up streams when provider is disposed
    ref.onDispose(() {
      _shopsSub?.cancel();
      _productsSub?.cancel();
      _postsSub?.cancel();
      _offersSub?.cancel();
      _leadsSub?.cancel();
    });

    return NearoDataState(
      shops: [],
      products: [],
      offers: [],
      posts: [],
      leads: [],
      currentUser: NearoDatabase.defaultUser,
      currentShop: NearoDatabase.defaultShop,
    );
  }

  void _listenToFirestore() {
    final firestore = FirebaseFirestore.instance;

    _shopsSub = firestore.collection('shops').snapshots().listen((snapshot) {
      final shops = snapshot.docs.map((doc) => ShopModel.fromMap(doc.data())).toList();
      state = state.copyWith(shops: shops);
      
      // Update currentShop if currentUser is owner of a shop
      final user = state.currentUser;
      if (user.role == 'shop_owner') {
        final currentShopIndex = shops.indexWhere((s) => s.ownerUid == user.uid);
        if (currentShopIndex != -1) {
          state = state.copyWith(currentShop: shops[currentShopIndex]);
        }
      }
    });

    _productsSub = firestore.collection('products').snapshots().listen((snapshot) {
      final products = snapshot.docs.map((doc) => ProductModel.fromMap(doc.data())).toList();
      state = state.copyWith(products: products);
    });

    _postsSub = firestore.collection('posts').snapshots().listen((snapshot) {
      final posts = snapshot.docs.map((doc) => PostModel.fromMap(doc.data())).toList();
      state = state.copyWith(posts: posts);
    });

    _offersSub = firestore.collection('offers').snapshots().listen((snapshot) {
      final offers = snapshot.docs.map((doc) => OfferModel.fromMap(doc.data())).toList();
      state = state.copyWith(offers: offers);
    });

    _leadsSub = firestore.collection('leads').snapshots().listen((snapshot) {
      final leads = snapshot.docs.map((doc) => LeadModel.fromMap(doc.data())).toList();
      state = state.copyWith(leads: leads);
    });
  }

  Future<void> _seedDatabaseIfNeeded() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Seed Shops
      final shopsSnapshot = await firestore.collection('shops').limit(1).get();
      if (shopsSnapshot.docs.isEmpty) {
        for (final shop in NearoDatabase.initialShops) {
          // Map mock shopId owner field to placeholder or user id for convenience
          final newShopMap = shop.toMap();
          newShopMap['ownerUid'] = 'u1'; // Default placeholder
          await firestore.collection('shops').doc(shop.id).set(newShopMap);
        }
      }

      // Seed Products
      final productsSnapshot = await firestore.collection('products').limit(1).get();
      if (productsSnapshot.docs.isEmpty) {
        for (final p in NearoDatabase.initialProducts) {
          await firestore.collection('products').doc(p.id).set(p.toMap());
        }
      }

      // Seed Offers
      final offersSnapshot = await firestore.collection('offers').limit(1).get();
      if (offersSnapshot.docs.isEmpty) {
        for (final o in NearoDatabase.initialOffers) {
          await firestore.collection('offers').doc(o.id).set(o.toMap());
        }
      }

      // Seed Posts
      final postsSnapshot = await firestore.collection('posts').limit(1).get();
      if (postsSnapshot.docs.isEmpty) {
        for (final post in NearoDatabase.initialPosts) {
          await firestore.collection('posts').doc(post.id).set(post.toMap());
        }
      }

      // Seed Leads
      final leadsSnapshot = await firestore.collection('leads').limit(1).get();
      if (leadsSnapshot.docs.isEmpty) {
        for (final lead in NearoDatabase.initialLeads) {
          await firestore.collection('leads').doc(lead.id).set(lead.toMap());
        }
      }
    } catch (_) {
      // Ignore seeding errors in offline or restricted permission environments
    }
  }

  // Update current user locally
  void setCurrentUser(UserModel user) {
    state = state.copyWith(currentUser: user);
  }

  // Update current shop locally
  void setCurrentShop(ShopModel shop) {
    state = state.copyWith(currentShop: shop);
  }

  // Product CRUD writes to Firestore
  Future<void> addProduct(ProductModel product) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(product.id)
        .set(product.toMap());

    // Send notifications to followers in real time
    await _notifyFollowers(
      shopId: product.shopId,
      title: state.currentShop.shopName,
      body: 'New Product Added: ${product.name} - Check it out now!',
      category: 'Offers',
    );
  }

  Future<void> editProduct(ProductModel updatedProduct) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(updatedProduct.id)
        .update(updatedProduct.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await FirebaseFirestore.instance.collection('products').doc(id).delete();
  }

  // Post creation writes to Firestore
  Future<void> addPost(PostModel post) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(post.id)
        .set(post.toMap());

    // If post is an offer, also write to the offers collection so it shows up in Offers tab/feed
    if (post.type == PostType.offer) {
      final offerId = 'offer_${post.id}';
      final newOffer = OfferModel(
        id: offerId,
        shopId: post.shopId,
        title: 'Special Offer',
        description: post.caption,
        discount: 'Deal',
        expiryDate: DateTime.now().add(const Duration(days: 7)),
        banner: post.image,
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .set(newOffer.toMap());
    }

    // Send notifications to followers in real time
    String notifBody = 'Published a new update!';
    if (post.type == PostType.offer) {
      notifBody = 'New Offer: ${post.caption}';
    } else if (post.type == PostType.product) {
      notifBody = 'New Product Update: ${post.caption}';
    } else {
      notifBody = 'New announcement: ${post.caption}';
    }

    await _notifyFollowers(
      shopId: post.shopId,
      title: state.currentShop.shopName,
      body: notifBody,
      category: post.type == PostType.offer ? 'Offers' : 'System',
    );
  }

  Future<void> _notifyFollowers({
    required String shopId,
    required String title,
    required String body,
    required String category,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Get all users who follow this shop
      final usersSnapshot = await firestore
          .collection('users')
          .where('followingShops', arrayContains: shopId)
          .get();
      
      final batch = firestore.batch();
      for (final doc in usersSnapshot.docs) {
        final userId = doc.id;
        final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}_$userId';
        final newNotification = {
          'id': notificationId,
          'userId': userId,
          'title': title,
          'body': body,
          'time': 'Just now',
          'createdAt': FieldValue.serverTimestamp(),
          'logoUrl': state.currentShop.logoUrl,
          'isUnread': true,
          'category': category,
        };
        final docRef = firestore.collection('notifications').doc(notificationId);
        batch.set(docRef, newNotification);
      }
      await batch.commit();
    } catch (e) {
      // ignore
    }
  }

  // Lead Generation writes to Firestore
  Future<void> addLead(LeadModel lead) async {
    await FirebaseFirestore.instance
        .collection('leads')
        .doc(lead.id)
        .set(lead.toMap());

    // Notify the shop owner in real time
    try {
      final shop = state.shops.firstWhere((s) => s.id == lead.shopId);
      final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}_owner_lead';
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .set({
            'id': notificationId,
            'userId': shop.ownerUid,
            'title': 'New Lead: ${lead.userName}',
            'body': 'Interested in ${lead.productName} (${lead.type.name})',
            'time': 'Just now',
            'createdAt': FieldValue.serverTimestamp(),
            'logoUrl': state.currentUser.photoUrl,
            'isUnread': true,
            'category': 'Followers',
          });
    } catch (_) {}
  }

  // Toggle user follow shop
  Future<void> toggleFollowShop(String shopId) async {
    final user = state.currentUser;
    if (user.isGuest) return; // Guarded in UI, but safe guard here too

    final following = List<String>.from(user.followingShops);
    if (following.contains(shopId)) {
      following.remove(shopId);
    } else {
      following.add(shopId);
    }

    final updatedUser = user.copyWith(followingShops: following);
    state = state.copyWith(currentUser: updatedUser);

    // Update user in Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'followingShops': following,
    });

    // Update shop followers count
    final shopIndex = state.shops.indexWhere((s) => s.id == shopId);
    if (shopIndex != -1) {
      final shop = state.shops[shopIndex];
      final newFollowers = shop.followers + (following.contains(shopId) ? 1 : -1);
      await FirebaseFirestore.instance.collection('shops').doc(shopId).update({
        'followers': newFollowers,
      });

      // Notify owner if they started following
      if (following.contains(shopId)) {
        try {
          final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}_follow';
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notificationId)
              .set({
                'id': notificationId,
                'userId': shop.ownerUid,
                'title': user.name,
                'body': 'Started following your shop updates.',
                'time': 'Just now',
                'createdAt': FieldValue.serverTimestamp(),
                'logoUrl': user.photoUrl,
                'isUnread': true,
                'category': 'Followers',
              });
        } catch (_) {}
      }
    }
  }

  // Toggle user save product
  Future<void> toggleSaveProduct(String productId) async {
    final user = state.currentUser;
    if (user.isGuest) return;

    final saved = List<String>.from(user.savedProducts);
    if (saved.contains(productId)) {
      saved.remove(productId);
    } else {
      saved.add(productId);
    }

    final updatedUser = user.copyWith(savedProducts: saved);
    state = state.copyWith(currentUser: updatedUser);

    // Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'savedProducts': saved,
    });

    // Notify owner if saved
    if (saved.contains(productId)) {
      try {
        final product = state.products.firstWhere((p) => p.id == productId);
        final shop = state.shops.firstWhere((s) => s.id == product.shopId);
        final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}_save';
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId)
            .set({
              'id': notificationId,
              'userId': shop.ownerUid,
              'title': 'Product Saved',
              'body': '${user.name} bookmarked ${product.name}.',
              'time': 'Just now',
              'createdAt': FieldValue.serverTimestamp(),
              'logoUrl': user.photoUrl,
              'isUnread': true,
              'category': 'System',
            });
      } catch (_) {}
    }
  }

  // Like a product
  Future<void> toggleLikeProduct(String productId) async {
    final productIndex = state.products.indexWhere((p) => p.id == productId);
    if (productIndex != -1) {
      final product = state.products[productIndex];
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'likes': product.likes + 1,
      });

      // Notify owner of the product like
      try {
        final shop = state.shops.firstWhere((s) => s.id == product.shopId);
        final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}_like';
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId)
            .set({
              'id': notificationId,
              'userId': shop.ownerUid,
              'title': 'Product Liked',
              'body': '${state.currentUser.name} liked ${product.name}.',
              'time': 'Just now',
              'createdAt': FieldValue.serverTimestamp(),
              'logoUrl': state.currentUser.photoUrl,
              'isUnread': true,
              'category': 'System',
            });
      } catch (_) {}
    }
  }

  // Like a post
  Future<void> toggleLikePost(String postId) async {
    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = state.posts[postIndex];
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'likes': post.likes + 1,
      });
    }
  }

  // Update current user profile
  Future<void> updateCurrentUser(UserModel user) async {
    state = state.copyWith(currentUser: user);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(user.toMap());
  }

  // Update current shop profile
  Future<void> updateCurrentShop(ShopModel shop) async {
    state = state.copyWith(currentShop: shop);
    await FirebaseFirestore.instance.collection('shops').doc(shop.id).set(shop.toMap());
  }

  // Mark a lead as contacted
  Future<void> markLeadContacted(String leadId) async {
    await FirebaseFirestore.instance.collection('leads').doc(leadId).update({
      'status': 'Contacted',
    });
  }
}

// Global Providers
final databaseProvider = NotifierProvider<NearoDatabaseNotifier, NearoDataState>(() {
  return NearoDatabaseNotifier();
});

// App Role Provider ("user", "owner", or null for auth screen)
class AppRoleNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

final appRoleProvider = NotifierProvider<AppRoleNotifier, String?>(() {
  return AppRoleNotifier();
});

// Navigation Index Provider
class BottomNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;
}

final bottomNavIndexProvider = NotifierProvider<BottomNavIndexNotifier, int>(() {
  return BottomNavIndexNotifier();
});

// App Theme Mode Provider
class AppThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(() {
  return AppThemeModeNotifier();
});
