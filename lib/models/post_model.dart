import 'package:cloud_firestore/cloud_firestore.dart';

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
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': id,
      'shopId': shopId,
      'type': type.name,
      'caption': caption,
      'image': image,
      'likes': likes,
      'comments': comments,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
