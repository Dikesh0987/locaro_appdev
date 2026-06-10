import 'package:cloud_firestore/cloud_firestore.dart';

class ShopModel {
  final String id; // maps to shopId in Firestore
  final String ownerUid;
  final String shopName;
  final String ownerName;
  final String logoUrl;
  final String bannerUrl;
  final String category;
  final String address;
  final String phone;
  final String whatsapp;
  final double latitude;
  final double longitude;
  final int followers;
  final double rating;
  final bool isVerified;
  final String description;
  final String openTime;
  final String closeTime;
  final bool showOnlineStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShopModel({
    required this.id,
    required this.ownerUid,
    required this.shopName,
    required this.ownerName,
    required this.logoUrl,
    required this.bannerUrl,
    required this.category,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.latitude,
    required this.longitude,
    required this.followers,
    required this.rating,
    required this.isVerified,
    required this.description,
    required this.openTime,
    required this.closeTime,
    required this.showOnlineStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopModel.empty() {
    return ShopModel(
      id: '',
      ownerUid: '',
      shopName: '',
      ownerName: '',
      logoUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&q=80', // Generic storefront
      bannerUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80',
      category: '',
      address: '',
      phone: '',
      whatsapp: '',
      latitude: 0.0,
      longitude: 0.0,
      followers: 0,
      rating: 0.0,
      isVerified: false,
      description: '',
      openTime: '09:00',
      closeTime: '21:00',
      showOnlineStatus: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Backward compatibility getters
  String get logo => logoUrl;
  String get banner => bannerUrl;

  bool get isOnline {
    if (!showOnlineStatus) return false;
    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final openParts = openTime.split(':');
      final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);

      final closeParts = closeTime.split(':');
      final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

      if (openMinutes <= closeMinutes) {
        return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
      } else {
        return currentMinutes >= openMinutes || currentMinutes <= closeMinutes;
      }
    } catch (e) {
      return true;
    }
  }

  ShopModel copyWith({
    String? id,
    String? ownerUid,
    String? shopName,
    String? ownerName,
    String? logoUrl,
    String? bannerUrl,
    String? category,
    String? address,
    String? phone,
    String? whatsapp,
    double? latitude,
    double? longitude,
    int? followers,
    double? rating,
    bool? isVerified,
    String? description,
    String? openTime,
    String? closeTime,
    bool? showOnlineStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopModel(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      shopName: shopName ?? this.shopName,
      ownerName: ownerName ?? this.ownerName,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      category: category ?? this.category,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      followers: followers ?? this.followers,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
      description: description ?? this.description,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ShopModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      } else if (val is String) {
        return DateTime.parse(val);
      } else {
        return DateTime.now();
      }
    }

    return ShopModel(
      id: map['shopId'] ?? map['id'] ?? '',
      ownerUid: map['ownerUid'] ?? '',
      shopName: map['shopName'] ?? '',
      ownerName: map['ownerName'] ?? '',
      logoUrl: map['logoUrl'] ?? map['logo'] ?? '',
      bannerUrl: map['bannerUrl'] ?? map['banner'] ?? '',
      category: map['category'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      followers: map['followers'] ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      isVerified: map['isVerified'] ?? false,
      description: map['description'] ?? '',
      openTime: map['openTime'] ?? '09:00',
      closeTime: map['closeTime'] ?? '21:00',
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopId': id,
      'ownerUid': ownerUid,
      'shopName': shopName,
      'ownerName': ownerName,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'category': category,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'latitude': latitude,
      'longitude': longitude,
      'followers': followers,
      'rating': rating,
      'isVerified': isVerified,
      'description': description,
      'openTime': openTime,
      'closeTime': closeTime,
      'showOnlineStatus': showOnlineStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
