enum MessageType { text, image, video }

enum MessageStatus { sent, delivered, read }

class ChatMessageModel {
  final String id;
  final String roomId; // Appwrite orderId
  final String text; // Appwrite message
  final DateTime timestamp;
  final bool isMine;
  final MessageStatus status;
  final MessageType messageType;
  final String? mediaUrl;
  final String senderRole; // 'customer' atau 'courier'

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.text,
    required this.timestamp,
    required this.isMine,
    this.status = MessageStatus.sent,
    this.messageType = MessageType.text,
    this.mediaUrl,
    this.senderRole = '',
  });

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  ChatMessageModel copyWith({
    String? id,
    String? roomId,
    String? text,
    DateTime? timestamp,
    bool? isMine,
    MessageStatus? status,
    MessageType? messageType,
    String? mediaUrl,
    String? senderRole,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isMine: isMine ?? this.isMine,
      status: status ?? this.status,
      messageType: messageType ?? this.messageType,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      senderRole: senderRole ?? this.senderRole,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessageModel(
      id: json['\$id'] ?? json['id'] ?? '',
      roomId: json['orderId'] ?? '',
      text: json['message'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      isMine: json['senderId'] == currentUserId,
      status: MessageStatus.read,
      messageType: _parseMessageType(json['messageType']),
      mediaUrl: json['mediaUrl'],
      senderRole: json['senderRole'] as String? ?? '',
    );
  }

  static MessageType _parseMessageType(String? type) {
    if (type == 'image') return MessageType.image;
    if (type == 'video') return MessageType.video;
    return MessageType.text;
  }

  Map<String, dynamic> toJson(String currentUserId, String currentUserName) {
    return {
      'orderId': roomId,
      'senderId': currentUserId,
      'senderName': currentUserName,
      'senderRole': senderRole.isNotEmpty ? senderRole : 'customer',
      'message': text,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType.name,
      'mediaUrl': mediaUrl,
    };
  }
}
