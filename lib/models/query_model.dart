import 'package:cloud_firestore/cloud_firestore.dart';

class QueryModel {
  final String id;
  final String userId;
  final String shopId;
  final String? productId; // Optional, as queries can be for shop or offers
  final String category;
  final String question;
  final String? answer;
  final String status; // 'pending', 'answered', 'closed'
  final DateTime createdAt;
  final DateTime? answeredAt;

  QueryModel({
    required this.id,
    required this.userId,
    required this.shopId,
    this.productId,
    required this.category,
    required this.question,
    this.answer,
    required this.status,
    required this.createdAt,
    this.answeredAt,
  });

  QueryModel copyWith({
    String? id,
    String? userId,
    String? shopId,
    String? productId,
    String? category,
    String? question,
    String? answer,
    String? status,
    DateTime? createdAt,
    DateTime? answeredAt,
  }) {
    return QueryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shopId: shopId ?? this.shopId,
      productId: productId ?? this.productId,
      category: category ?? this.category,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'shopId': shopId,
      'productId': productId,
      'category': category,
      'question': question,
      'answer': answer,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'answeredAt': answeredAt?.millisecondsSinceEpoch,
    };
  }

  factory QueryModel.fromMap(Map<String, dynamic> map) {
    return QueryModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      shopId: map['shopId'] ?? '',
      productId: map['productId'],
      category: map['category'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'],
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      answeredAt: map['answeredAt'] != null 
          ? (map['answeredAt'] is Timestamp 
              ? (map['answeredAt'] as Timestamp).toDate() 
              : DateTime.fromMillisecondsSinceEpoch(map['answeredAt']))
          : null,
    );
  }
}
