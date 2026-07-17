import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_room_model.dart';
import '../../domain/models/chat_message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

class ChatRepository {
  final List<ChatRoomModel> _rooms = [
    ChatRoomModel(
      id: 'room_1',
      senderName: 'Budi - Kurir SentraGO',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      lastMessage: 'Posisi saya sudah di depan pintu ya kak, membawa titipan jastipnya.',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 2)),
      unreadCount: 2,
      isOnline: true,
      lastSeenText: 'Aktif sekarang',
      serviceType: 'Jastip #1024',
      isSupport: false,
    ),
    ChatRoomModel(
      id: 'room_cs',
      senderName: 'Customer Service SentraGO',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      lastMessage: 'Halo Dinda! Ada yang bisa kami bantu seputar pesanan atau aplikasi SentraGO?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 1,
      isOnline: true,
      lastSeenText: 'Aktif 24 Jam',
      serviceType: 'Bantuan & Kendala',
      isSupport: true,
    ),
    ChatRoomModel(
      id: 'room_2',
      senderName: 'Siti - Kurir SentraGO',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      lastMessage: 'Siap kak, barang belanjanya sudah dibelikan semua sesuai catatan.',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      unreadCount: 0,
      isOnline: false,
      lastSeenText: 'Terakhir online 12:45',
      serviceType: 'Jastip #0981',
      isSupport: false,
    ),
    ChatRoomModel(
      id: 'room_3',
      senderName: 'Rizky - Kurir SentraGO',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      lastMessage: 'Terima kasih kak, pesanan sudah selesai diantar kemarin sore.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
      lastSeenText: 'Terakhir online kemarin',
      serviceType: 'Jastip #0842',
      isSupport: false,
    ),
  ];

  final Map<String, List<ChatMessageModel>> _messages = {
    'room_1': [
      ChatMessageModel(
        id: 'msg_1',
        roomId: 'room_1',
        text: 'Halo kak Dinda, saya Budi kurir yang menangani pesanan Jastip #1024 kakak ya.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        isMine: false,
        status: MessageStatus.read,
      ),
      ChatMessageModel(
        id: 'msg_2',
        roomId: 'room_1',
        text: 'Halo mas Budi, siap! Tolong dipastikan barangnya tidak ada cacat ya mas.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        isMine: true,
        status: MessageStatus.read,
      ),
      ChatMessageModel(
        id: 'msg_3',
        roomId: 'room_1',
        text: 'Sudah saya periksa kak, semuanya aman dan lengkap sesuai struk.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
        isMine: false,
        status: MessageStatus.read,
      ),
      ChatMessageModel(
        id: 'msg_4',
        roomId: 'room_1',
        text: 'Posisi saya sudah di depan pintu ya kak, membawa titipan jastipnya.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        isMine: false,
        status: MessageStatus.delivered,
      ),
    ],
    'room_cs': [
      ChatMessageModel(
        id: 'msg_cs_1',
        roomId: 'room_cs',
        text: 'Halo Dinda! Ada yang bisa kami bantu seputar pesanan atau aplikasi SentraGO?',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isMine: false,
        status: MessageStatus.delivered,
      ),
    ],
    'room_2': [
      ChatMessageModel(
        id: 'msg_r2_1',
        roomId: 'room_2',
        text: 'Siap kak, barang belanjanya sudah dibelikan semua sesuai catatan.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        isMine: false,
        status: MessageStatus.read,
      ),
    ],
    'room_3': [
      ChatMessageModel(
        id: 'msg_r3_1',
        roomId: 'room_3',
        text: 'Terima kasih kak, pesanan sudah selesai diantar kemarin sore.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isMine: false,
        status: MessageStatus.read,
      ),
    ],
  };

  Future<List<ChatRoomModel>> getChatRooms() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_rooms);
  }

  Future<List<ChatMessageModel>> getMessages(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_messages[roomId] ?? []);
  }

  Future<ChatMessageModel> sendMessage(ChatMessageModel message) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!_messages.containsKey(message.roomId)) {
      _messages[message.roomId] = [];
    }
    _messages[message.roomId]!.add(message);

    // Update room last message
    final index = _rooms.indexWhere((r) => r.id == message.roomId);
    if (index != -1) {
      final room = _rooms[index];
      String displayMsg = message.text;
      if (message.messageType == MessageType.image) {
        displayMsg = '📷 Foto';
      } else if (message.messageType == MessageType.video) {
        displayMsg = '🎥 Video';
      }
      _rooms[index] = room.copyWith(
        lastMessage: displayMsg,
        lastMessageTime: message.timestamp,
      );
    }
    return message;
  }

  Future<void> markRoomAsRead(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      _rooms[index] = _rooms[index].copyWith(unreadCount: 0);
    }
    final msgs = _messages[roomId] ?? [];
    for (int i = 0; i < msgs.length; i++) {
      if (!msgs[i].isMine && msgs[i].status != MessageStatus.read) {
        msgs[i] = msgs[i].copyWith(status: MessageStatus.read);
      }
    }
  }

  // Simulated Auto-Reply from courier/CS for realism
  Future<ChatMessageModel?> generateAutoReply(String roomId, ChatMessageModel triggerMsg) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final room = _rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => ChatRoomModel(
        id: roomId,
        senderName: 'Kurir SentraGO',
        avatarUrl: '',
        lastMessage: '',
        lastMessageTime: DateTime.now(),
      ),
    );

    String replyText;
    if (room.isSupport) {
      replyText = 'Terima kasih atas pesannya kak. Tim CS kami sedang meninjau kendala Anda dan akan segera membantu menyelesaikan dalam waktu dekat.';
    } else {
      if (triggerMsg.messageType == MessageType.image || triggerMsg.messageType == MessageType.video) {
        replyText = 'Mantap kak, lampiran medianya sudah saya terima dan dicek ya!';
      } else if (triggerMsg.text.toLowerCase().contains('posisi')) {
        replyText = 'Saya sedang dalam perjalanan menuju lokasi titik antar kak, sekitar 5-10 menit lagi sampai.';
      } else if (triggerMsg.text.toLowerCase().contains('terima kasih') || triggerMsg.text.toLowerCase().contains('makasih')) {
        replyText = 'Sama-sama kak Dinda! Semoga puas dengan layanan SentraGO 🙏';
      } else {
        replyText = 'Siap kak! Sudah saya catat dan pastikan semuanya sesuai instruksi pesanan ya 👍';
      }
    }

    final replyMessage = ChatMessageModel(
      id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId,
      text: replyText,
      timestamp: DateTime.now(),
      isMine: false,
      status: MessageStatus.delivered,
    );

    await sendMessage(replyMessage);
    return replyMessage;
  }
}
