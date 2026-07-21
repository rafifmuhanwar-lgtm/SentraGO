class ChatRoomModel {
  final String id;
  final String senderName;
  final String avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final String lastSeenText;
  final String serviceType;
  final bool isSupport;

  const ChatRoomModel({
    required this.id,
    required this.senderName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.lastSeenText = 'Offline',
    this.serviceType = '',
    this.isSupport = false,
  });

  ChatRoomModel copyWith({
    String? id,
    String? senderName,
    String? avatarUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    String? lastSeenText,
    String? serviceType,
    bool? isSupport,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      lastSeenText: lastSeenText ?? this.lastSeenText,
      serviceType: serviceType ?? this.serviceType,
      isSupport: isSupport ?? this.isSupport,
    );
  }
}
