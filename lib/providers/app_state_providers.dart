import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';
import '../models/post_model.dart';
import '../models/offer_model.dart';
import '../models/query_model.dart';
import '../repositories/Locaro_repository.dart';


// State wrapper for the in-memory database
class LocaroDataState {
  final bool isLoading;
  final List<ShopModel> shops;
  final List<ProductModel> products;
  final List<OfferModel> offers;
  final List<PostModel> posts;
  final List<QueryModel> queries;
  final UserModel currentUser;
  final ShopModel currentShop;

  LocaroDataState({
    this.isLoading = true,
    required this.shops,
    required this.products,
    required this.offers,
    required this.posts,
    required this.queries,
    required this.currentUser,
    required this.currentShop,
  });

  LocaroDataState copyWith({
    bool? isLoading,
    List<ShopModel>? shops,
    List<ProductModel>? products,
    List<OfferModel>? offers,
    List<PostModel>? posts,
    List<QueryModel>? queries,
    UserModel? currentUser,
    ShopModel? currentShop,
  }) {
    return LocaroDataState(
      isLoading: isLoading ?? this.isLoading,
      shops: shops ?? this.shops,
      products: products ?? this.products,
      offers: offers ?? this.offers,
      posts: posts ?? this.posts,
      queries: queries ?? this.queries,
      currentUser: currentUser ?? this.currentUser,
      currentShop: currentShop ?? this.currentShop,
    );
  }
}

// Database notifier that handles all CRUD and in-memory updates synced with Firestore
class LocaroDatabaseNotifier extends Notifier<LocaroDataState> {
  StreamSubscription? _shopsSub;
  StreamSubscription? _productsSub;
  StreamSubscription? _postsSub;
  StreamSubscription? _offersSub;
  StreamSubscription? _queriesSub;

  @override
  LocaroDataState build() {
    _listenToFirestore();
    // _seedDatabaseIfNeeded(); // Disabled to use only real user data

    // Clean up streams when provider is disposed
    ref.onDispose(() {
      _shopsSub?.cancel();
      _productsSub?.cancel();
      _postsSub?.cancel();
      _offersSub?.cancel();
      _queriesSub?.cancel();
    });

    return LocaroDataState(
      shops: [],
      products: [],
      offers: [],
      posts: [],
      queries: [],
      currentUser: LocaroDatabase.defaultUser,
      currentShop: LocaroDatabase.defaultShop,
    );
  }

  bool _deferredStarted = false;

  void _listenToFirestore() {
    final firestore = FirebaseFirestore.instance;

    // Phase 1: Load shops first (smallest collection, needed for shell/home)
    _shopsSub = firestore.collection('shops').limit(50).snapshots().listen((snapshot) {
      final shops = snapshot.docs.map((doc) => ShopModel.fromMap(doc.data())).toList();
      state = state.copyWith(shops: shops, isLoading: false);
      
      // Update currentShop if currentUser is owner of a shop
      final user = state.currentUser;
      if (user.role == 'shop_owner') {
        final currentShopIndex = shops.indexWhere((s) => s.ownerUid == user.uid);
        if (currentShopIndex != -1) {
          state = state.copyWith(currentShop: shops[currentShopIndex]);
        }
      }

      // Phase 2: Start remaining listeners after shops data is ready
      _startDeferredListeners(firestore);
    });
  }

  void _startDeferredListeners(FirebaseFirestore firestore) {
    if (_deferredStarted) return;
    _deferredStarted = true;

    _productsSub = firestore.collection('products').orderBy('createdAt', descending: true).limit(20).snapshots().listen((snapshot) {
      final products = snapshot.docs.map((doc) => ProductModel.fromMap(doc.data())).toList();
      state = state.copyWith(products: products);
    });

    _postsSub = firestore.collection('posts').orderBy('createdAt', descending: true).limit(20).snapshots().listen((snapshot) {
      final posts = snapshot.docs.map((doc) => PostModel.fromMap(doc.data())).toList();
      state = state.copyWith(posts: posts);
    });

    _offersSub = firestore.collection('offers').orderBy('createdAt', descending: true).limit(20).snapshots().listen((snapshot) {
      final offers = snapshot.docs.map((doc) => OfferModel.fromMap(doc.data())).toList();
      state = state.copyWith(offers: offers);
    });

    _queriesSub = firestore.collection('queries').orderBy('createdAt', descending: true).limit(20).snapshots().listen((snapshot) {
      final queries = snapshot.docs.map((doc) => QueryModel.fromMap(doc.data())).toList();
      state = state.copyWith(queries: queries);
    });
  }


  bool _isLoadingMoreProducts = false;
  Future<void> loadMoreProducts() async {
    if (_isLoadingMoreProducts || state.products.isEmpty) return;
    _isLoadingMoreProducts = true;
    try {
      final lastProduct = state.products.last;
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .startAfter([Timestamp.fromDate(lastProduct.createdAt)])
          .limit(20)
          .get(const GetOptions(source: Source.serverAndCache));
      
      if (snapshot.docs.isNotEmpty) {
        final newProducts = snapshot.docs.map((doc) => ProductModel.fromMap(doc.data())).toList();
        state = state.copyWith(products: [...state.products, ...newProducts]);
      }
    } finally {
      _isLoadingMoreProducts = false;
    }
  }

  bool _isLoadingMorePosts = false;
  Future<void> loadMorePosts() async {
    if (_isLoadingMorePosts || state.posts.isEmpty) return;
    _isLoadingMorePosts = true;
    try {
      final lastPost = state.posts.last;
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .startAfter([Timestamp.fromDate(lastPost.createdAt)])
          .limit(20)
          .get(const GetOptions(source: Source.serverAndCache));
      
      if (snapshot.docs.isNotEmpty) {
        final newPosts = snapshot.docs.map((doc) => PostModel.fromMap(doc.data())).toList();
        state = state.copyWith(posts: [...state.posts, ...newPosts]);
      }
    } finally {
      _isLoadingMorePosts = false;
    }
  }

  // Update current user locally
  void setCurrentUser(UserModel user) {
    ShopModel currentShop = state.currentShop;
    if (user.role == 'shop_owner') {
      final currentShopIndex = state.shops.indexWhere((s) => s.ownerUid == user.uid);
      if (currentShopIndex != -1) {
        currentShop = state.shops[currentShopIndex];
      }
    }
    state = state.copyWith(currentUser: user, currentShop: currentShop);
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
      imageUrl: product.images.isNotEmpty ? product.images.first : null,
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
  Future<void> addPost(
    PostModel post, {
    String? offerTitle,
    String? offerDiscount,
    int? offerValidityDays,
  }) async {
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
        title: offerTitle ?? 'Special Offer',
        description: post.caption,
        discount: offerDiscount ?? 'Deal',
        expiryDate: DateTime.now().add(Duration(days: offerValidityDays ?? 7)),
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
      imageUrl: post.image.isNotEmpty ? post.image : null,
    );
  }

  Future<void> _notifyFollowers({
    required String shopId,
    required String title,
    required String body,
    required String category,
    String? imageUrl,
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
          'type': category,
          'referenceId': shopId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'imageUrl': ?imageUrl,
        };
        final docRef = firestore.collection('notifications').doc(notificationId);
        batch.set(docRef, newNotification);
      }
      await batch.commit();
    } catch (e) {
      // ignore
    }
  }



  // Submit a Query
  Future<void> submitQuery(QueryModel query) async {
    await FirebaseFirestore.instance
        .collection('queries')
        .doc(query.id)
        .set(query.toMap());

    try {
      final shop = state.shops.where((s) => s.id == query.shopId).firstOrNull;
      if (shop == null) return;
      final notificationId = 'notif_query_${query.id}_${query.userId}';
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .set({
            'id': notificationId,
            'userId': shop.ownerUid,
            'title': 'New Query Received',
            'body': 'A customer asked: ${query.question}',
            'type': 'System',
            'referenceId': query.id,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  // Answer a Query
  Future<void> answerQuery(String queryId, String answer) async {
    await FirebaseFirestore.instance.collection('queries').doc(queryId).update({
      'answer': answer,
      'status': 'answered',
      'answeredAt': DateTime.now().millisecondsSinceEpoch,
    });

    try {
      final query = state.queries.where((q) => q.id == queryId).firstOrNull;
      if (query == null) return;
      final shop = state.shops.where((s) => s.id == query.shopId).firstOrNull;
      if (shop == null) return;
      final notificationId = 'notif_query_reply_${query.id}';
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .set({
            'id': notificationId,
            'userId': query.userId,
            'title': '${shop.shopName} replied to your query',
            'body': answer,
            'type': 'query_reply',
            'referenceId': query.id,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  // Close a Query
  Future<void> closeQuery(String queryId) async {
    await FirebaseFirestore.instance.collection('queries').doc(queryId).update({
      'status': 'closed',
    });
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
      await FirebaseFirestore.instance.collection('shops').doc(shopId).update({
        'followers': FieldValue.increment(following.contains(shopId) ? 1 : -1),
      });

      // Notify owner if they started following
      if (following.contains(shopId)) {
        try {
          final notificationId = 'notif_follow_${shopId}_${user.uid}';
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notificationId)
              .set({
                'id': notificationId,
                'userId': shop.ownerUid,
                'title': user.name,
                'body': 'Started following your shop updates.',
                'type': 'Followers',
                'referenceId': user.uid,
                'isRead': false,
                'createdAt': FieldValue.serverTimestamp(),
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

    // Update product saves counter atomically
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'saves': FieldValue.increment(saved.contains(productId) ? 1 : -1),
      });
    } catch (_) {}

    // Notify owner if saved
    if (saved.contains(productId)) {
      try {
        final product = state.products.where((p) => p.id == productId).firstOrNull;
        if (product == null) return;
        final shop = state.shops.where((s) => s.id == product.shopId).firstOrNull;
        if (shop == null) return;
        final notificationId = 'notif_save_${productId}_${user.uid}';
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId)
            .set({
              'id': notificationId,
              'userId': shop.ownerUid,
              'title': 'Product Saved',
              'body': '${user.name} bookmarked ${product.name}.',
              'type': 'System',
              'referenceId': productId,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
      } catch (_) {}
    }
  }

  // Increment view count silently
  Future<void> incrementProductView(String productId) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'views': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  // Like a product
  Future<void> toggleLikeProduct(String productId) async {
    final user = state.currentUser;
    if (user.isGuest) return;

    final liked = List<String>.from(user.likedProducts);
    bool isLiking = !liked.contains(productId);

    if (isLiking) {
      liked.add(productId);
    } else {
      liked.remove(productId);
    }

    final updatedUser = user.copyWith(likedProducts: liked);
    state = state.copyWith(currentUser: updatedUser);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'likedProducts': liked,
    });

    final productIndex = state.products.indexWhere((p) => p.id == productId);
    if (productIndex != -1) {
      final product = state.products[productIndex];
      
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'likes': FieldValue.increment(isLiking ? 1 : -1),
      });

      // Notify owner of the product like
      if (isLiking) {
        try {
          final shop = state.shops.where((s) => s.id == product.shopId).firstOrNull;
          if (shop == null) return;
          final notificationId = 'notif_like_${productId}_${user.uid}';
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notificationId)
              .set({
                'id': notificationId,
                'userId': shop.ownerUid,
                'title': 'Product Liked',
                'body': '${state.currentUser.name} liked ${product.name}.',
                'type': 'System',
                'referenceId': productId,
                'isRead': false,
                'createdAt': FieldValue.serverTimestamp(),
              });
        } catch (_) {}
      }
    }
  }

  // Like a post
  Future<void> toggleLikePost(String postId) async {
    final user = state.currentUser;
    if (user.isGuest) return;

    final liked = List<String>.from(user.likedPosts);
    bool isLiking = !liked.contains(postId);

    if (isLiking) {
      liked.add(postId);
    } else {
      liked.remove(postId);
    }

    final updatedUser = user.copyWith(likedPosts: liked);
    state = state.copyWith(currentUser: updatedUser);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'likedPosts': liked,
    });

    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'likes': FieldValue.increment(isLiking ? 1 : -1),
      });
    }
  }

  // Update current user profile
  Future<void> updateCurrentUser(UserModel user) async {
    state = state.copyWith(currentUser: user);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(user.toMap());
  }

  // Add Comment
  Future<void> addComment(String itemId, String text) async {
    final user = state.currentUser;
    if (user.isGuest) return;

    final commentId = 'comment_${DateTime.now().millisecondsSinceEpoch}_${user.uid}';
    final newComment = {
      'id': commentId,
      'itemId': itemId,
      'userId': user.uid,
      'userName': user.name,
      'userImage': user.profileImage,
      'text': text,
      'createdAt': Timestamp.now(),
      'likes': 0,
    };

    await FirebaseFirestore.instance.collection('comments').doc(commentId).set(newComment);
  }

  // Update current shop profile
  Future<void> updateCurrentShop(ShopModel shop) async {
    final updatedShops = List<ShopModel>.from(state.shops);
    final index = updatedShops.indexWhere((s) => s.id == shop.id);
    if (index != -1) {
      updatedShops[index] = shop;
    }
    state = state.copyWith(currentShop: shop, shops: updatedShops);
    
    // We use set with merge: true to avoid losing unmapped fields while ensuring all current fields are updated
    await FirebaseFirestore.instance.collection('shops').doc(shop.id).set(shop.toMap(), SetOptions(merge: true));
  }


}

// Global Providers
final databaseProvider = NotifierProvider<LocaroDatabaseNotifier, LocaroDataState>(() {
  return LocaroDatabaseNotifier();
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

// Pending Deep Link Provider
class PendingDeepLinkNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  @override
  set state(Map<String, dynamic>? value) => super.state = value;
}

final pendingDeepLinkProvider = NotifierProvider<PendingDeepLinkNotifier, Map<String, dynamic>?>(() {
  return PendingDeepLinkNotifier();
});
