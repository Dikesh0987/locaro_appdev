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

  // Backward compatibility fields for followed shops and saved products
  final List<String> followingShops;
  final List<String> savedProducts;

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
    required this.notificationSettings,
  });

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
    Map<String, bool>? notificationSettings,
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
      notificationSettings: notificationSettings ?? this.notificationSettings,
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
      notificationSettings: Map<String, bool>.from(map['notificationSettings'] ?? {
        'offers': true,
        'nearbyDeals': true,
        'comments': true,
        'followers': true,
        'announcements': true,
        'marketing': false,
      }),
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
      'notificationSettings': notificationSettings,
    };
  }
}
