import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { product, offer, update }

class PostModel {
  final String id;
  final String shopId;
  final PostType type;
  final String caption;
  final String image;
  final String? linkedProductId;
  final int likes;
  final int comments;
  final DateTime createdAt;

  // --- NEW OPTIONAL FIELDS ---
  final String? slug;
  final String? status;
  final DateTime? updatedAt;
  final List<String>? searchKeywords;
  final String? categoryId;
  final String? categoryName;
  final int? views;
  final int? shares;
  final int? saves;
  final bool? isFeatured;
  final bool? isDeleted;
  final bool? isVisible;

  PostModel({
    required this.id,
    required this.shopId,
    required this.type,
    required this.caption,
    required this.image,
    this.linkedProductId,
    required this.likes,
    required this.comments,
    required this.createdAt,
    this.slug,
    this.status,
    this.updatedAt,
    this.searchKeywords,
    this.categoryId,
    this.categoryName,
    this.views,
    this.shares,
    this.saves,
    this.isFeatured,
    this.isDeleted,
    this.isVisible,
  });

  PostModel copyWith({
    String? id,
    String? shopId,
    PostType? type,
    String? caption,
    String? image,
    String? linkedProductId,
    int? likes,
    int? comments,
    DateTime? createdAt,
    String? slug,
    String? status,
    DateTime? updatedAt,
    List<String>? searchKeywords,
    String? categoryId,
    String? categoryName,
    int? views,
    int? shares,
    int? saves,
    bool? isFeatured,
    bool? isDeleted,
    bool? isVisible,
  }) {
    return PostModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      type: type ?? this.type,
      caption: caption ?? this.caption,
      image: image ?? this.image,
      linkedProductId: linkedProductId ?? this.linkedProductId,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      saves: saves ?? this.saves,
      isFeatured: isFeatured ?? this.isFeatured,
      isDeleted: isDeleted ?? this.isDeleted,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  factory PostModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      } else if (val is String) {
        return DateTime.parse(val);
      } else {
        return DateTime.now();
      }
    }

    PostType parsePostType(String typeStr) {
      switch (typeStr) {
        case 'product':
          return PostType.product;
        case 'offer':
          return PostType.offer;
        case 'update':
        default:
          return PostType.update;
      }
    }

    return PostModel(
      id: map['postId'] ?? map['id'] ?? '',
      shopId: map['shopId'] ?? '',
      type: parsePostType(map['type'] ?? 'update'),
      caption: map['caption'] ?? '',
      image: map['image'] ?? '',
      linkedProductId: map['linkedProductId'],
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      createdAt: parseDateTime(map['createdAt']),
      slug: map['slug'] as String?,
      status: map['status'] as String?,
      updatedAt: map['updatedAt'] != null ? parseDateTime(map['updatedAt']) : null,
      searchKeywords: map['searchKeywords'] != null ? List<String>.from(map['searchKeywords']) : null,
      categoryId: map['categoryId'] as String?,
      categoryName: map['categoryName'] as String?,
      views: map['views'] as int?,
      shares: map['shares'] as int?,
      saves: map['saves'] as int?,
      isFeatured: map['isFeatured'] as bool?,
      isDeleted: map['isDeleted'] as bool?,
      isVisible: map['isVisible'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': id,
      'shopId': shopId,
      'type': type.name,
      'caption': caption,
      'image': image,
      'linkedProductId': linkedProductId,
      'likes': likes,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
      if (slug != null) 'slug': slug,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (searchKeywords != null) 'searchKeywords': searchKeywords,
      if (categoryId != null) 'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      if (views != null) 'views': views,
      if (shares != null) 'shares': shares,
      if (saves != null) 'saves': saves,
      if (isFeatured != null) 'isFeatured': isFeatured,
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (isVisible != null) 'isVisible': isVisible,
    };
  }
}
