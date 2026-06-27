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
  final String description;
  final String openTime;
  final String closeTime;
  final bool showOnlineStatus;
  final bool isWhatsappVerified;
  final bool isWhatsappEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;
  final bool isActive;

  // --- NEW OPTIONAL FIELDS ---
  final String? slug;
  final String? status;
  final List<String>? searchKeywords;
  final String? categoryId;
  final String? categoryName;
  final int? views;
  final int? shares;
  final int? saves;
  final int? reviewCount;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final bool? isFeatured;
  final bool? isDeleted;
  final bool? isVisible;
  final DateTime? lastSeen;


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
    required this.description,
    required this.openTime,
    required this.closeTime,
    required this.showOnlineStatus,
    required this.isWhatsappVerified,
    required this.isWhatsappEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
    this.isActive = true,
    this.slug,
    this.status,
    this.searchKeywords,
    this.categoryId,
    this.categoryName,
    this.views,
    this.shares,
    this.saves,
    this.reviewCount,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.isFeatured,
    this.isDeleted,
    this.isVisible,
    this.lastSeen,
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
      description: '',
      openTime: '09:00',
      closeTime: '21:00',
      showOnlineStatus: true,
      isWhatsappVerified: false,
      isWhatsappEnabled: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isVerified: false,
      isActive: true,
      slug: null,
      status: null,
      searchKeywords: null,
      categoryId: null,
      categoryName: null,
      views: 0,
      shares: 0,
      saves: 0,
      reviewCount: 0,
      city: null,
      state: null,
      country: null,
      pincode: null,
      isFeatured: false,
      isDeleted: false,
      isVisible: true,
      lastSeen: null,
    );
  }

  // Backward compatibility getters
  String get logo => logoUrl;
  String get banner => bannerUrl;

  bool get isOnline {
    if (!showOnlineStatus || !isActive) return false;
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
    String? description,
    String? openTime,
    String? closeTime,
    bool? showOnlineStatus,
    bool? isWhatsappVerified,
    bool? isWhatsappEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
    bool? isActive,
    String? slug,
    String? status,
    List<String>? searchKeywords,
    String? categoryId,
    String? categoryName,
    int? views,
    int? shares,
    int? saves,
    int? reviewCount,
    String? city,
    String? state,
    String? country,
    String? pincode,
    bool? isFeatured,
    bool? isDeleted,
    bool? isVisible,
    DateTime? lastSeen,
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
      description: description ?? this.description,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      isWhatsappVerified: isWhatsappVerified ?? this.isWhatsappVerified,
      isWhatsappEnabled: isWhatsappEnabled ?? this.isWhatsappEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      views: views ?? this.views,
      shares: shares ?? this.shares,
      saves: saves ?? this.saves,
      reviewCount: reviewCount ?? this.reviewCount,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      isFeatured: isFeatured ?? this.isFeatured,
      isDeleted: isDeleted ?? this.isDeleted,
      isVisible: isVisible ?? this.isVisible,
      lastSeen: lastSeen ?? this.lastSeen,
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
      description: map['description'] ?? '',
      openTime: map['openTime'] ?? '09:00',
      closeTime: map['closeTime'] ?? '21:00',
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      isWhatsappVerified: map['isWhatsappVerified'] ?? false,
      isWhatsappEnabled: map['isWhatsappEnabled'] ?? true,
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      slug: map['slug'] as String?,
      status: map['status'] as String?,
      searchKeywords: map['searchKeywords'] != null ? List<String>.from(map['searchKeywords']) : null,
      categoryId: map['categoryId'] as String?,
      categoryName: map['categoryName'] as String?,
      views: map['views'] as int?,
      shares: map['shares'] as int?,
      saves: map['saves'] as int?,
      reviewCount: map['reviewCount'] as int?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      country: map['country'] as String?,
      pincode: map['pincode'] as String?,
      isFeatured: map['isFeatured'] as bool?,
      isDeleted: map['isDeleted'] as bool?,
      isVisible: map['isVisible'] as bool?,
      lastSeen: map['lastSeen'] != null ? parseDateTime(map['lastSeen']) : null,
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
      'isWhatsappVerified': isWhatsappVerified,
      'isWhatsappEnabled': isWhatsappEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (slug != null) 'slug': slug,
      if (status != null) 'status': status,
      if (searchKeywords != null) 'searchKeywords': searchKeywords,
      if (categoryId != null) 'categoryId': categoryId,
      if (categoryName != null) 'categoryName': categoryName,
      if (views != null) 'views': views,
      if (shares != null) 'shares': shares,
      if (saves != null) 'saves': saves,
      if (reviewCount != null) 'reviewCount': reviewCount,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (pincode != null) 'pincode': pincode,
      if (isFeatured != null) 'isFeatured': isFeatured,
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (isVisible != null) 'isVisible': isVisible,
      if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
    };
  }
}
