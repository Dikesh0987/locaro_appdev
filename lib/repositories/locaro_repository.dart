import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../models/product_model.dart';
import '../models/post_model.dart';
import '../models/offer_model.dart';
import '../models/lead_model.dart';

class LocaroDatabase {
  static final UserModel defaultUser = UserModel.empty();
  static final ShopModel defaultShop = ShopModel.empty();

  static final List<ShopModel> initialShops = [];
  static final List<ProductModel> initialProducts = [];
  static final List<OfferModel> initialOffers = [];
  static final List<PostModel> initialPosts = [];
  static final List<LeadModel> initialLeads = [];
}

