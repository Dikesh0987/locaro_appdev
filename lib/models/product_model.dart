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
    };
  }
}
