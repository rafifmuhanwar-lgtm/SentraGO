class NotificationModel {
  final String id;
  final String userId;
  final String category;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
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
    );
  }
}
