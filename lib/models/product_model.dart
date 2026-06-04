class ProductModel {
  final String id;
  final String shopId;
  final String name;
  final List<String> images;
  final String description;
  final double price;
  final double? discountPrice;
  final int stock;
  final String category;
  final int likes;
  final int views;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.images,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.stock,
    required this.category,
    required this.likes,
    required this.views,
    required this.createdAt,
  });

  ProductModel copyWith({
    String? id,
    String? shopId,
    String? name,
    List<String>? images,
    String? description,
    double? price,
    double? discountPrice,
    int? stock,
    String? category,
    int? likes,
    int? views,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      images: images ?? this.images,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
