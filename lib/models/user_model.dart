import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String role; // 'user' or 'shop_owner'
  final bool isGuest;
  final List<String> interests;
  final String location;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final DateTime updatedAt;
  final bool isOnboardingCompleted;
  final bool isProfileCompleted;
  final bool notificationEnabled;
  final String language;
  final String themeMode; // 'light', 'dark', 'system'
  final double latitude;
  final double longitude;
  final String? fcmToken;
  final bool phoneVerified;
  final DateTime? verifiedAt;

  // Backward compatibility fields for followed shops and saved products
  final List<String> followingShops;
  final List<String> savedProducts;
  final List<String> likedProducts;
  final List<String> likedPosts;

  // Granular notification settings (Offers, Nearby Deals, Comments, Followers, Announcements, Marketing)
  final Map<String, bool> notificationSettings;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.role,
    required this.isGuest,
    required this.interests,
    required this.location,
    required this.createdAt,
    required this.lastLoginAt,
    required this.updatedAt,
    required this.isOnboardingCompleted,
    required this.isProfileCompleted,
    required this.notificationEnabled,
    required this.language,
    required this.themeMode,
    required this.followingShops,
    required this.savedProducts,
    required this.likedProducts,
    required this.likedPosts,
    required this.notificationSettings,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.fcmToken,
    this.phoneVerified = false,
    this.verifiedAt,
  });

  factory UserModel.empty() {
    return UserModel(
      uid: '',
      name: '',
      email: '',
      phone: '',
      photoUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&q=80', // Professional placeholder
      role: 'user',
      isGuest: true,
      interests: [],
      location: '',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isOnboardingCompleted: false,
      isProfileCompleted: false,
      notificationEnabled: false,
      language: 'English',
      themeMode: 'system',
      followingShops: [],
      savedProducts: [],
      likedProducts: [],
      likedPosts: [],
      notificationSettings: {},
      latitude: 0.0,
      longitude: 0.0,
      fcmToken: null,
      phoneVerified: false,
      verifiedAt: null,
    );
  }

  // Backward compatibility getters
  String get id => uid;
  String get profileImage => photoUrl;

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
    bool? isGuest,
    List<String>? interests,
    String? location,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? updatedAt,
    bool? isOnboardingCompleted,
    bool? isProfileCompleted,
    bool? notificationEnabled,
    String? language,
    String? themeMode,
    List<String>? followingShops,
    List<String>? savedProducts,
    List<String>? likedProducts,
    List<String>? likedPosts,
    Map<String, bool>? notificationSettings,
    double? latitude,
    double? longitude,
    String? fcmToken,
    bool? phoneVerified,
    DateTime? verifiedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isGuest: isGuest ?? this.isGuest,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      followingShops: followingShops ?? this.followingShops,
      savedProducts: savedProducts ?? this.savedProducts,
      likedProducts: likedProducts ?? this.likedProducts,
      likedPosts: likedPosts ?? this.likedPosts,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fcmToken: fcmToken ?? this.fcmToken,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      } else if (val is String) {
        return DateTime.parse(val);
      } else {
        return DateTime.now();
      }
    }

    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      role: map['role'] ?? 'user',
      isGuest: map['isGuest'] ?? false,
      interests: List<String>.from(map['interests'] ?? []),
      location: map['location'] ?? '',
      createdAt: parseDateTime(map['createdAt']),
      lastLoginAt: parseDateTime(map['lastLoginAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      isOnboardingCompleted: map['isOnboardingCompleted'] ?? false,
      isProfileCompleted: map['isProfileCompleted'] ?? false,
      notificationEnabled: map['notificationEnabled'] ?? true,
      language: map['language'] ?? 'English',
      themeMode: map['themeMode'] ?? 'system',
      followingShops: List<String>.from(map['followingShops'] ?? []),
      savedProducts: List<String>.from(map['savedProducts'] ?? []),
      likedProducts: List<String>.from(map['likedProducts'] ?? []),
      likedPosts: List<String>.from(map['likedPosts'] ?? []),
      notificationSettings: Map<String, bool>.from(map['notificationSettings'] ?? {
        'offers': true,
        'nearbyDeals': true,
        'comments': true,
        'followers': true,
        'announcements': true,
        'marketing': false,
      }),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      fcmToken: map['fcmToken'] as String?,
      phoneVerified: map['phoneVerified'] ?? false,
      verifiedAt: map['verifiedAt'] != null ? parseDateTime(map['verifiedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role,
      'isGuest': isGuest,
      'interests': interests,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isOnboardingCompleted': isOnboardingCompleted,
      'isProfileCompleted': isProfileCompleted,
      'notificationEnabled': notificationEnabled,
      'language': language,
      'themeMode': themeMode,
      'followingShops': followingShops,
      'savedProducts': savedProducts,
      'likedProducts': likedProducts,
      'likedPosts': likedPosts,
      'notificationSettings': notificationSettings,
      'latitude': latitude,
      'longitude': longitude,
      'fcmToken': fcmToken,
      'phoneVerified': phoneVerified,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
    };
  }
}
