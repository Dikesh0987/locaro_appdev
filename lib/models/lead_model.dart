import 'package:cloud_firestore/cloud_firestore.dart';

enum LeadType { interested, saved, discountRequest, whatsappClick, callClick }

class LeadModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String productId;
  final String productName;
  final String shopId;
  final LeadType type;
  final String status; // "New", "Contacted", "Closed"
  final DateTime createdAt;

  LeadModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.productId,
    required this.productName,
    required this.shopId,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  LeadModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? productId,
    String? productName,
    String? shopId,
    LeadType? type,
    String? status,
    DateTime? createdAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      shopId: shopId ?? this.shopId,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory LeadModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) {
        return val.toDate();
      } else if (val is String) {
        return DateTime.parse(val);
      } else {
        return DateTime.now();
      }
    }

    LeadType parseLeadType(String typeStr) {
      switch (typeStr) {
        case 'interested':
          return LeadType.interested;
        case 'saved':
          return LeadType.saved;
        case 'discountRequest':
          return LeadType.discountRequest;
        case 'whatsappClick':
          return LeadType.whatsappClick;
        case 'callClick':
        default:
          return LeadType.callClick;
      }
    }

    return LeadModel(
      id: map['leadId'] ?? map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      shopId: map['shopId'] ?? '',
      type: parseLeadType(map['type'] ?? 'interested'),
      status: map['status'] ?? 'New',
      createdAt: parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'leadId': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'productId': productId,
      'productName': productName,
      'shopId': shopId,
      'type': type.name,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
