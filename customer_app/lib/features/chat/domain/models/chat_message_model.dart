enum MessageType { text, image, video }

enum MessageStatus { sent, delivered, read }

class ChatMessageModel {
  final String id;
  final String roomId;
  final String text;
  final DateTime timestamp;
  final bool isMine;
  final MessageStatus status;
  final MessageType messageType;
  final String? mediaUrl;

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.text,
    required this.timestamp,
    required this.isMine,
    this.status = MessageStatus.sent,
    this.messageType = MessageType.text,
    this.mediaUrl,
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
    );
  }
}
