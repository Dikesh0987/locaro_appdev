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
  }

  // Lead Generation writes to Firestore
  Future<void> addLead(LeadModel lead) async {
    await FirebaseFirestore.instance
        .collection('leads')
        .doc(lead.id)
        .set(lead.toMap());
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
  }

  // Like a product
  Future<void> toggleLikeProduct(String productId) async {
    final productIndex = state.products.indexWhere((p) => p.id == productId);
    if (productIndex != -1) {
      final product = state.products[productIndex];
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'likes': product.likes + 1,
      });
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
