class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String location;
  final List<String> interests;
  final List<String> followingShops; // Shop IDs
  final List<String> savedProducts; // Product IDs
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.location,
    required this.interests,
    required this.followingShops,
    required this.savedProducts,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? location,
    List<String>? interests,
    List<String>? followingShops,
    List<String>? savedProducts,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      followingShops: followingShops ?? this.followingShops,
      savedProducts: savedProducts ?? this.savedProducts,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
