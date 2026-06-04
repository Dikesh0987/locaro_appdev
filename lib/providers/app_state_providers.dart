import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Database notifier that handles all CRUD and in-memory updates
class NearoDatabaseNotifier extends Notifier<NearoDataState> {
  @override
  NearoDataState build() {
    return NearoDataState(
      shops: NearoDatabase.initialShops,
      products: NearoDatabase.initialProducts,
      offers: NearoDatabase.initialOffers,
      posts: NearoDatabase.initialPosts,
      leads: NearoDatabase.initialLeads,
      currentUser: NearoDatabase.defaultUser,
      currentShop: NearoDatabase.defaultShop,
    );
  }

  // Product CRUD
  void addProduct(ProductModel product) {
    state = state.copyWith(products: [product, ...state.products]);
  }

  void editProduct(ProductModel updatedProduct) {
    state = state.copyWith(
      products: state.products.map((p) => p.id == updatedProduct.id ? updatedProduct : p).toList(),
    );
  }

  void deleteProduct(String id) {
    state = state.copyWith(
      products: state.products.where((p) => p.id != id).toList(),
    );
  }

  // Post creation
  void addPost(PostModel post) {
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  // Lead Generation
  void addLead(LeadModel lead) {
    state = state.copyWith(leads: [lead, ...state.leads]);
  }

  // Toggle user follow shop
  void toggleFollowShop(String shopId) {
    final following = List<String>.from(state.currentUser.followingShops);
    if (following.contains(shopId)) {
      following.remove(shopId);
    } else {
      following.add(shopId);
    }

    final updatedUser = state.currentUser.copyWith(followingShops: following);
    final updatedShops = state.shops.map((s) {
      if (s.id == shopId) {
        return s.copyWith(followers: s.followers + (following.contains(shopId) ? 1 : -1));
      }
      return s;
    }).toList();

    state = state.copyWith(
      currentUser: updatedUser,
      shops: updatedShops,
    );
  }

  // Toggle user save product
  void toggleSaveProduct(String productId) {
    final saved = List<String>.from(state.currentUser.savedProducts);
    if (saved.contains(productId)) {
      saved.remove(productId);
    } else {
      saved.add(productId);
    }

    final updatedUser = state.currentUser.copyWith(savedProducts: saved);
    state = state.copyWith(currentUser: updatedUser);
  }

  // Like a product
  void toggleLikeProduct(String productId) {
    final updatedProducts = state.products.map((p) {
      if (p.id == productId) {
        return p.copyWith(likes: p.likes + 1);
      }
      return p;
    }).toList();
    state = state.copyWith(products: updatedProducts);
  }

  // Like a post
  void toggleLikePost(String postId) {
    final updatedPosts = state.posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(likes: p.likes + 1);
      }
      return p;
    }).toList();
    state = state.copyWith(posts: updatedPosts);
  }

  // Update current user profile (onboarding)
  void updateCurrentUser(UserModel user) {
    state = state.copyWith(currentUser: user);
  }

  // Update current shop profile (onboarding)
  void updateCurrentShop(ShopModel shop) {
    state = state.copyWith(currentShop: shop, shops: [shop, ...state.shops.where((s) => s.id != shop.id)]);
  }

  // Mark a lead as contacted
  void markLeadContacted(String leadId) {
    state = state.copyWith(
      leads: state.leads.map((l) {
        if (l.id == leadId) {
          return l.copyWith(status: 'Contacted');
        }
        return l;
      }).toList(),
    );
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
