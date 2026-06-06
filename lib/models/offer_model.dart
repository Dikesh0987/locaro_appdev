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

  OfferModel({
    required this.id,
    required this.shopId,
    required this.title,
    required this.description,
    required this.discount,
    required this.expiryDate,
    required this.banner,
    required this.createdAt,
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
    };
  }
}
