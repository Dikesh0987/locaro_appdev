import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  // --- NEW OPTIONAL FIELDS ---
  final String? slug;
  final String? status;
  final DateTime? updatedAt;
  final List<String>? searchKeywords;
  final String? categoryId;
  final String? categoryName;
  final int? shares;
  final int? saves;
  final double? rating;
  final int? reviewCount;
  final bool? isFeatured;
  final bool? isDeleted;
  final bool? isVisible;

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
    this.slug,
    this.status,
    this.updatedAt,
    this.searchKeywords,
    this.categoryId,
    this.categoryName,
    this.shares,
    this.saves,
    this.rating,
    this.reviewCount,
    this.isFeatured,
    this.isDeleted,
    this.isVisible,
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
    String? slug,
    String? status,
    DateTime? updatedAt,
    List<String>? searchKeywords,
    String? categoryId,
    String? categoryName,
    int? shares,
    int? saves,
    double? rating,
    int? reviewCount,
    bool? isFeatured,
    bool? isDeleted,
    bool? isVisible,
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
      slug: slug ?? this.slug,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      shares: shares ?? this.shares,
      saves: saves ?? this.saves,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isDeleted: isDeleted ?? this.isDeleted,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      } else if (val is String) {
        return DateTime.parse(val);
      } else {
        return DateTime.now();
      }
    }

    return ProductModel(
      id: map['productId'] ?? map['id'] ?? '',
      shopId: map['shopId'] ?? '',
      name: map['name'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (map['discountPrice'] as num?)?.toDouble(),
      stock: map['stock'] ?? 0,
      category: map['category'] ?? '',
      likes: map['likes'] ?? 0,
      views: map['views'] ?? 0,
      createdAt: parseDateTime(map['createdAt']),
      slug: map['slug'] as String?,
      status: map['status'] as String?,
      updatedAt: map['updatedAt'] != null ? parseDateTime(map['updatedAt']) : null,
      searchKeywords: map['searchKeywords'] != null ? List<String>.from(map['searchKeywords']) : null,
      categoryId: map['categoryId'] as String?,
      categoryName: map['categoryName'] as String?,
      shares: map['shares'] as int?,
      saves: map['saves'] as int?,
      rating: (map['rating'] as num?)?.toDouble(),
      reviewCount: map['reviewCount'] as int?,
      isFeatured: map['isFeatured'] as bool?,
      isDeleted: map['isDeleted'] as bool?,
      isVisible: map['isVisible'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': id,
      'shopId': shopId,
      'name': name,
      'images': images,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'stock': stock,
      'category': category,
      'likes': likes,
      'views': views,
      'createdAt': Timestamp.fromDate(createdAt),
      if (slug != null) 'slug': slug,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (searchKeywords != null) 'searchKeywords': searchKeywords,
      if (categoryId != null) 'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      if (shares != null) 'shares': shares,
      if (saves != null) 'saves': saves,
      if (rating != null) 'rating': rating,
      if (reviewCount != null) 'reviewCount': reviewCount,
      if (isFeatured != null) 'isFeatured': isFeatured,
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (isVisible != null) 'isVisible': isVisible,
    };
  }
}
