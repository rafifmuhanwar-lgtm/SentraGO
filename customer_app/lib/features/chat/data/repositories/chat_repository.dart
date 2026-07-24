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

    // Customer Service room (mock)
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
        orderStatus: 'ongoing',
      ),
    );

    // Satu room per order (pakai order.id sebagai orderId/roomId)
    for (var order in orders) {
      String courierAvatar = order.courierAvatar;
      
      // Ambil foto profil terbaru dari database
      if (order.courierId.isNotEmpty) {
        final courierData = await _dbService.getCourierById(order.courierId);
        if (courierData != null && courierData['photoUrl'] != null && courierData['photoUrl'].toString().isNotEmpty) {
          courierAvatar = courierData['photoUrl'];
        }
      }

      rooms.add(
        ChatRoomModel(
          id: order.id,
          senderName: order.courierName.isNotEmpty ? '${order.courierName} · Kurir' : 'Kurir SentraGO',
          avatarUrl: courierAvatar.isNotEmpty
              ? courierAvatar
              : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
          lastMessage: order.description.isNotEmpty ? order.description : 'Tap untuk mulai chat',
          lastMessageTime: order.createdAt,
          unreadCount: 0,
          isOnline: order.courierName.isNotEmpty,
          lastSeenText: order.courierName.isNotEmpty ? 'Kurir aktif' : 'Menunggu kurir',
          serviceType: order.serviceName,
          isSupport: false,
          orderStatus: order.status.toString().split('.').last,
          orderUpdatedAt: order.updatedAt,
        ),
      );
    }

    return rooms;
  }

  Future<List<ChatMessageModel>> getMessages(String roomId) async {
    final userId = _userId;
    if (userId == null) return [];

    // CS room: mock
    if (roomId == 'room_cs') {
      return [
        ChatMessageModel(
          id: 'msg_cs_1',
          roomId: 'room_cs',
          text: 'Halo ${_userName ?? "Pelanggan"}! Ada yang bisa kami bantu seputar pesanan atau aplikasi SentraGO?',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isMine: false,
          status: MessageStatus.delivered,
          senderRole: 'support',
        ),
      ];
    }

    final docs = await _dbService.getChatMessages(roomId);
    return docs.map((doc) => ChatMessageModel.fromJson(doc, userId)).toList();
  }

  Future<ChatMessageModel> sendMessage(ChatMessageModel message) async {
    final userId = _userId;
    if (userId == null) return message;

    // CS room: mock only
    if (message.roomId == 'room_cs') return message;

    final msgToSave = message.copyWith(id: const Uuid().v4(), senderRole: 'customer');

    await _dbService.createChatMessage(
      data: msgToSave.toJson(userId, _userName ?? 'Customer'),
    );

    return msgToSave;
  }

  Future<void> markRoomAsRead(String roomId) async {
    // Future: update isRead = true WHERE orderId = roomId AND senderId != userId
  }
}
