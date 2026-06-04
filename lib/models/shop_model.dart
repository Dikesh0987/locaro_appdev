class ShopModel {
  final String id;
  final String shopName;
  final String ownerName;
  final String logo;
  final String banner;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int followers;
  final String category;
  final bool isVerified;
  final String phone;
  final String whatsapp;
  final String description;

  ShopModel({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.logo,
    required this.banner,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.followers,
    required this.category,
    required this.isVerified,
    required this.phone,
    required this.whatsapp,
    required this.description,
  });

  ShopModel copyWith({
    String? id,
    String? shopName,
    String? ownerName,
    String? logo,
    String? banner,
    String? address,
    double? latitude,
    double? longitude,
    double? rating,
    int? followers,
    String? category,
    bool? isVerified,
    String? phone,
    String? whatsapp,
    String? description,
  }) {
    return ShopModel(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      logo: logo ?? this.logo,
      banner: banner ?? this.banner,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      followers: followers ?? this.followers,
      category: category ?? this.category,
      isVerified: isVerified ?? this.isVerified,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      description: description ?? this.description,
    );
  }
}
