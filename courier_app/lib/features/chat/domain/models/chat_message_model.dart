enum MessageType { text, image, video }

enum MessageStatus { sent, delivered, read }

class ChatMessageModel {
  final String id;
  final String roomId; // orderId
  final String text;
  final DateTime timestamp;
  final bool isMine;
  final MessageStatus status;
  final MessageType messageType;
  final String? mediaUrl;
  final String senderRole; // 'customer' atau 'courier'
  final String senderName;

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
    this.senderName = '',
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
    String? senderName,
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
      senderName: senderName ?? this.senderName,
    );
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String currentCourierId) {
    return ChatMessageModel(
      id: json['\$id'] ?? json['id'] ?? '',
      roomId: json['orderId'] ?? '',
      text: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isMine: json['senderId'] == currentCourierId,
      status: MessageStatus.read,
      messageType: _parseMessageType(json['messageType']),
      mediaUrl: json['mediaUrl'],
      senderRole: json['senderRole'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
    );
  }

  static MessageType _parseMessageType(String? type) {
    if (type == 'image') return MessageType.image;
    if (type == 'video') return MessageType.video;
    return MessageType.text;
  }

  Map<String, dynamic> toJson(String courierId, String courierName) {
    return {
      'orderId': roomId,
      'senderId': courierId,
      'senderName': courierName,
      'senderRole': 'courier',
      'message': text,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType.name,
      'mediaUrl': mediaUrl,
    };
  }
}
