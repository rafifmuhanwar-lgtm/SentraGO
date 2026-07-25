class NotificationModel {
  final String id;
  final String userId;
  final String category; // 'Pesanan', 'Promo & Info', 'Sistem & Akun'
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;
  final String? routeName;
  final Map<String, dynamic>? routeExtra;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.routeName,
    this.routeExtra,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}, ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      category: category,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      routeName: routeName,
      routeExtra: routeExtra,
    );
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      userId: map['userId'] ?? '',
      category: map['category'] ?? 'Sistem & Akun',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      isRead: map['isRead'] == true || map['isRead'] == 'true',
      routeName: map['routeName'],
      routeExtra: map['routeExtra'] != null
          ? Map<String, dynamic>.from(map['routeExtra'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      if (routeName != null) 'routeName': routeName,
      if (routeExtra != null) 'routeExtra': routeExtra,
    };
  }
}