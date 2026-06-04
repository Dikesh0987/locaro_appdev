enum PostType { product, offer, update }

class PostModel {
  final String id;
  final String shopId;
  final PostType type;
  final String caption;
  final String image;
  final int likes;
  final int comments;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.shopId,
    required this.type,
    required this.caption,
    required this.image,
    required this.likes,
    required this.comments,
    required this.createdAt,
  });

  PostModel copyWith({
    String? id,
    String? shopId,
    PostType? type,
    String? caption,
    String? image,
    int? likes,
    int? comments,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      type: type ?? this.type,
      caption: caption ?? this.caption,
      image: image ?? this.image,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
