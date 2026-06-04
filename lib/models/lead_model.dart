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
}
