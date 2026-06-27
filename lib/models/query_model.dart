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

  // --- NEW OPTIONAL FIELDS ---
  final DateTime? updatedAt;
  final List<String>? searchKeywords;
  final bool? isDeleted;

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
    this.updatedAt,
    this.searchKeywords,
    this.isDeleted,
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
    DateTime? updatedAt,
    List<String>? searchKeywords,
    bool? isDeleted,
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
      updatedAt: updatedAt ?? this.updatedAt,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      isDeleted: isDeleted ?? this.isDeleted,
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
      if (updatedAt != null) 'updatedAt': updatedAt!.millisecondsSinceEpoch,
      if (searchKeywords != null) 'searchKeywords': searchKeywords,
      if (isDeleted != null) 'isDeleted': isDeleted,
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
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate() 
              : DateTime.fromMillisecondsSinceEpoch(map['updatedAt']))
          : null,
      searchKeywords: map['searchKeywords'] != null ? List<String>.from(map['searchKeywords']) : null,
      isDeleted: map['isDeleted'] as bool?,
    );
  }
}
