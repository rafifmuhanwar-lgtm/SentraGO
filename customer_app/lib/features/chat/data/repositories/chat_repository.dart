import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../order/data/repositories/order_repository.dart';
import '../../domain/models/chat_room_model.dart';
import '../../domain/models/chat_message_model.dart';
import 'package:uuid/uuid.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final orderRepo = ref.watch(orderRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return ChatRepository(dbService, orderRepo, authState.user?.id, authState.user?.name);
});

class ChatRepository {
  final DatabaseService _dbService;
  final OrderRepository _orderRepo;
  final String? _userId;
  final String? _userName;

  ChatRepository(this._dbService, this._orderRepo, this._userId, this._userName);

  Future<List<ChatRoomModel>> getChatRooms() async {
    if (_userId == null) return [];

    final orders = await _orderRepo.getOrders();
    final List<ChatRoomModel> rooms = [];

    // Add Customer Service
    rooms.add(
      ChatRoomModel(
        id: 'room_cs',
        senderName: 'Customer Service SentraGO',
        avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
        lastMessage: 'Halo! Ada yang bisa kami bantu?',
        lastMessageTime: DateTime.now(),
        unreadCount: 0,
        isOnline: true,
        lastSeenText: 'Aktif 24 Jam',
        serviceType: 'Bantuan & Kendala',
        isSupport: true,
      ),
    );

    // Map active/recent orders to chat rooms
    for (var order in orders) {
      rooms.add(
        ChatRoomModel(
          id: order.id,
          senderName: order.courierName.isNotEmpty ? '${order.courierName} - Kurir' : 'Kurir SentraGO',
          avatarUrl: order.courierAvatar.isNotEmpty ? order.courierAvatar : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150', // placeholder
          lastMessage: order.description,
          lastMessageTime: order.createdAt,
          unreadCount: 0,
          isOnline: true,
          lastSeenText: 'Terakhir aktif baru saja',
          serviceType: order.serviceName,
          isSupport: false,
        ),
      );
    }

    return rooms;
  }

  Future<List<ChatMessageModel>> getMessages(String roomId) async {
    final userId = _userId;
    if (userId == null) return [];
    
    // Check if it's CS room mock
    if (roomId == 'room_cs') {
      return [
        ChatMessageModel(
          id: 'msg_cs_1',
          roomId: 'room_cs',
          text: 'Halo ${_userName ?? "Pelanggan"}! Ada yang bisa kami bantu seputar pesanan atau aplikasi SentraGO?',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isMine: false,
          status: MessageStatus.delivered,
        ),
      ];
    }

    final docs = await _dbService.getChatMessages(roomId);
    return docs.map((doc) => ChatMessageModel.fromJson(doc, userId)).toList();
  }

  Future<ChatMessageModel> sendMessage(ChatMessageModel message) async {
    final userId = _userId;
    if (userId == null) return message;

    if (message.roomId == 'room_cs') {
      // Mock for CS
      return message;
    }

    final msgToSave = message.copyWith(id: const Uuid().v4());
    
    await _dbService.createChatMessage(
      data: msgToSave.toJson(userId, _userName ?? 'User'),
    );

    return msgToSave;
  }

  Future<void> markRoomAsRead(String roomId) async {
    // Implementation needed if we store read status
  }

  Future<ChatMessageModel?> generateAutoReply(String roomId, ChatMessageModel triggerMsg) async {
    if (_userId == null) return null;

    String replyText;
    if (roomId == 'room_cs') {
      replyText = 'Terima kasih atas pesannya. Tim CS kami sedang meninjau kendala Anda dan akan segera membantu menyelesaikan dalam waktu dekat.';
    } else {
      if (triggerMsg.messageType == MessageType.image || triggerMsg.messageType == MessageType.video) {
        replyText = 'Mantap kak, lampiran medianya sudah saya terima dan dicek ya!';
      } else if (triggerMsg.text.toLowerCase().contains('posisi')) {
        replyText = 'Saya sedang dalam perjalanan menuju lokasi titik antar kak, sekitar 5-10 menit lagi sampai.';
      } else if (triggerMsg.text.toLowerCase().contains('terima kasih') || triggerMsg.text.toLowerCase().contains('makasih')) {
        replyText = 'Sama-sama kak! Semoga puas dengan layanan SentraGO 🙏';
      } else {
        replyText = 'Siap kak! Sudah saya catat dan pastikan semuanya sesuai instruksi pesanan ya 👍';
      }
    }

    final replyMessage = ChatMessageModel(
      id: const Uuid().v4(),
      roomId: roomId,
      text: replyText,
      timestamp: DateTime.now(),
      isMine: false,
      status: MessageStatus.delivered,
    );

    // Save auto-reply to DB if not CS room
    if (roomId != 'room_cs') {
      await _dbService.createChatMessage(
        data: {
          'orderId': roomId,
          'senderId': 'courier_auto',
          'senderName': 'Kurir',
          'message': replyText,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }

    return replyMessage;
  }
}
