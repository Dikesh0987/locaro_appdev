class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String time;
  final String logoUrl;
  final bool isUnread;
  final String category; // 'Offers', 'Followers', 'Comments', 'System'

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.logoUrl,
    required this.isUnread,
    required this.category,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? time,
    String? logoUrl,
    bool? isUnread,
    String? category,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      logoUrl: logoUrl ?? this.logoUrl,
      isUnread: isUnread ?? this.isUnread,
      category: category ?? this.category,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      time: map['time'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      isUnread: map['isUnread'] ?? false,
      category: map['category'] ?? 'System',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'time': time,
      'logoUrl': logoUrl,
      'isUnread': isUnread,
      'category': category,
    };
  }
}
