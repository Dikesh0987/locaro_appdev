class OfferModel {
  final String id;
  final String shopId;
  final String title;
  final String description;
  final String discount; // e.g. "20% OFF", "BOGO"
  final DateTime expiryDate;
  final String banner;

  OfferModel({
    required this.id,
    required this.shopId,
    required this.title,
    required this.description,
    required this.discount,
    required this.expiryDate,
    required this.banner,
  });

  OfferModel copyWith({
    String? id,
    String? shopId,
    String? title,
    String? description,
    String? discount,
    DateTime? expiryDate,
    String? banner,
  }) {
    return OfferModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      title: title ?? this.title,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      expiryDate: expiryDate ?? this.expiryDate,
      banner: banner ?? this.banner,
    );
  }
}
