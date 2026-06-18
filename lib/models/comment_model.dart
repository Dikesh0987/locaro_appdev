import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String itemId;
  final String userId;
  final String userName;
  final String userImage;
  final String text;
  final DateTime createdAt;
  final int likes;

  CommentModel({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.userName,
    required this.userImage,
    required this.text,
    required this.createdAt,
    this.likes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImage: map['userImage'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: map['likes']?.toInt() ?? 0,
    );
  }

  CommentModel copyWith({
    String? id,
    String? itemId,
    String? userId,
    String? userName,
    String? userImage,
    String? text,
    DateTime? createdAt,
    int? likes,
  }) {
    return CommentModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImage: userImage ?? this.userImage,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
    );
  }
}
