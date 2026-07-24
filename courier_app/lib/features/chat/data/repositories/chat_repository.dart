import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../order/data/repositories/order_repository.dart';
import '../../domain/models/chat_room_model.dart';
import '../../domain/models/chat_message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  final orderRepo = ref.watch(orderRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return ChatRepository(
    dbService,
    orderRepo,
    authState.courier?.id,
    authState.courier?.name,
  );
});

class ChatRepository {
  final DatabaseService _dbService;
  final OrderRepository _orderRepo;
  final String? _courierId;
  final String? _courierName;

  ChatRepository(
    this._dbService,
    this._orderRepo,
    this._courierId,
    this._courierName,
  );

  /// Ambil semua room chat dari order yang dikerjakan kurir ini
  Future<List<ChatRoomModel>> getChatRooms() async {
    final courierId = _courierId;
    if (courierId == null || courierId.isEmpty) return [];

    try {
      final orders = await _orderRepo.getMyOrders(courierId);
      final List<ChatRoomModel> rooms = [];

      for (var order in orders) {
        // Ambil nama customer dari userId (tampilkan singkat)
        final customerLabel = order.userId.isNotEmpty
            ? 'Customer #${order.userId.substring(0, 6).toUpperCase()}'
            : 'Customer';

        String avatarUrl = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';

        // Ambil foto profil terbaru dari database
        if (order.userId.isNotEmpty) {
          final customerData = await _dbService.getUserById(order.userId);
          if (customerData != null && customerData['photoUrl'] != null && customerData['photoUrl'].toString().isNotEmpty) {
            avatarUrl = customerData['photoUrl'];
          }
        }

        rooms.add(ChatRoomModel(
          id: order.id,
          customerName: customerLabel,
          avatarUrl: avatarUrl,
          lastMessage: order.statusText.isNotEmpty
              ? order.statusText
              : 'Tap untuk mulai chat',
          lastMessageTime: order.createdAt,
          isOnline: true,
          orderType: order.type,
          orderTitle: order.title,
          orderStatus: order.status.toString().split('.').last,
          orderUpdatedAt: order.updatedAt,
        ));
      }
      return rooms;
    } catch (e) {
      return [];
    }
  }

  /// Ambil semua pesan untuk satu order (room)
  Future<List<ChatMessageModel>> getMessages(String orderId) async {
    final courierId = _courierId;
    if (courierId == null) return [];

    final docs = await _dbService.getChatMessages(orderId);
    return docs
        .map((doc) => ChatMessageModel.fromJson(doc, courierId))
        .toList();
  }

  /// Kirim pesan dari kurir
  Future<ChatMessageModel> sendMessage(ChatMessageModel message) async {
    final courierId = _courierId;
    if (courierId == null) return message;

    final msgToSave = message.copyWith(
      id: const Uuid().v4(),
      senderRole: 'courier',
    );

    await _dbService.createChatMessage(
      data: msgToSave.toJson(courierId, _courierName ?? 'Kurir'),
    );

    return msgToSave;
  }

  Future<void> markRoomAsRead(String orderId) async {
    // Future: update isRead flag di Appwrite
  }
}
