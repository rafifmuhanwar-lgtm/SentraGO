class ChatRoomModel {
  final String id; // = orderId
  final String customerName;
  final String avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final String orderType; // 'jastip' atau 'suruh'
  final String orderTitle;
  final String orderStatus;
  final DateTime? orderUpdatedAt;

  const ChatRoomModel({
    required this.id,
    required this.customerName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.orderType = '',
    this.orderTitle = '',
    this.orderStatus = '',
    this.orderUpdatedAt,
  });

  ChatRoomModel copyWith({
    String? id,
    String? customerName,
    String? avatarUrl,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isOnline,
    String? orderType,
    String? orderTitle,
    String? orderStatus,
    DateTime? orderUpdatedAt,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      orderType: orderType ?? this.orderType,
      orderTitle: orderTitle ?? this.orderTitle,
      orderStatus: orderStatus ?? this.orderStatus,
      orderUpdatedAt: orderUpdatedAt ?? this.orderUpdatedAt,
    );
  }
}
