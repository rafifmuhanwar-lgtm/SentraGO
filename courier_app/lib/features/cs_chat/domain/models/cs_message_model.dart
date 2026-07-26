class CsChatMessage {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isFromAdmin;
  final String senderName;
  final String senderRole;

  const CsChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isFromAdmin,
    this.senderName = '',
    this.senderRole = '',
  });

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  factory CsChatMessage.fromMap(Map<String, dynamic> map, String currentUserId) {
    final senderId = map['senderId'] ?? '';
    final senderRole = map['senderRole'] as String? ?? '';
    return CsChatMessage(
      id: map['\$id'] ?? map['id'] ?? '',
      text: map['message'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      isFromAdmin: senderRole == 'admin',
      senderName: map['senderName'] as String? ?? '',
      senderRole: senderRole,
    );
  }
}
