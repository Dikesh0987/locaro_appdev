import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  final String id;
  final String shopId;
  final String title;
  final String description;
  final String discount; // e.g. "20% OFF", "BOGO"
  final DateTime expiryDate;
  final String banner;
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
  final double? rating;
  final int? reviewCount;
  final bool? isFeatured;
  final bool? isDeleted;
  final bool? isVisible;

  OfferModel({
    required this.id,
    required this.shopId,
    required this.title,
    required this.description,
    required this.discount,
    required this.expiryDate,
    required this.banner,
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
    this.rating,
    this.reviewCount,
    this.isFeatured,
    this.isDeleted,
    this.isVisible,
  });

  OfferModel copyWith({
    String? id,
    String? shopId,
    String? title,
    String? description,
    String? discount,
    DateTime? expiryDate,
    String? banner,
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
    double? rating,
    int? reviewCount,
    bool? isFeatured,
    bool? isDeleted,
    bool? isVisible,
  }) {
    return OfferModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      title: title ?? this.title,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      expiryDate: expiryDate ?? this.expiryDate,
      banner: banner ?? this.banner,
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
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isDeleted: isDeleted ?? this.isDeleted,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  factory OfferModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      } else if (val is String) {
        return DateTime.parse(val);
      } else {
        return DateTime.now();
      }
    }

    return OfferModel(
      id: map['offerId'] ?? map['id'] ?? '',
      shopId: map['shopId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discount: map['discount'] ?? '',
      expiryDate: parseDateTime(map['expiryDate']),
      banner: map['banner'] ?? '',
      createdAt: map['createdAt'] != null ? parseDateTime(map['createdAt']) : DateTime.now(),
      slug: map['slug'] as String?,
      status: map['status'] as String?,
      updatedAt: map['updatedAt'] != null ? parseDateTime(map['updatedAt']) : null,
      searchKeywords: map['searchKeywords'] != null ? List<String>.from(map['searchKeywords']) : null,
      categoryId: map['categoryId'] as String?,
      categoryName: map['categoryName'] as String?,
      views: map['views'] as int?,
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
      'offerId': id,
      'shopId': shopId,
      'title': title,
      'description': description,
      'discount': discount,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'banner': banner,
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
      if (rating != null) 'rating': rating,
      if (reviewCount != null) 'reviewCount': reviewCount,
      if (isFeatured != null) 'isFeatured': isFeatured,
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (isVisible != null) 'isVisible': isVisible,
    };
  }
}
