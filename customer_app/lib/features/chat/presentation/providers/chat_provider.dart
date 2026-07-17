import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/chat_room_model.dart';
import '../../domain/models/chat_message_model.dart';
import '../../data/repositories/chat_repository.dart';

final chatRoomsProvider = NotifierProvider<ChatRoomsNotifier, List<ChatRoomModel>>(() {
  return ChatRoomsNotifier();
});

class ChatRoomsNotifier extends Notifier<List<ChatRoomModel>> {
  late final ChatRepository _repository;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  @override
  List<ChatRoomModel> build() {
    _repository = ref.watch(chatRepositoryProvider);
    Future.microtask(() => loadRooms());
    return [];
  }

  Future<void> loadRooms() async {
    _isLoading = true;
    final rooms = await _repository.getChatRooms();
    state = rooms;
    _isLoading = false;
  }

  Future<void> refresh() async {
    await loadRooms();
  }
}

final chatRoomMessagesProvider =
    NotifierProvider.family<ChatRoomMessagesNotifier, List<ChatMessageModel>, String>(
        (arg) => ChatRoomMessagesNotifier(arg));

class ChatRoomMessagesNotifier extends Notifier<List<ChatMessageModel>> {
  final String arg;
  late final ChatRepository _repository;

  ChatRoomMessagesNotifier(this.arg);

  @override
  List<ChatMessageModel> build() {
    _repository = ref.watch(chatRepositoryProvider);
    Future.microtask(() => loadMessages());
    return [];
  }

  Future<void> loadMessages() async {
    final msgs = await _repository.getMessages(arg);
    state = msgs;
    await _repository.markRoomAsRead(arg);
    ref.read(chatRoomsProvider.notifier).loadRooms();
  }

  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    final newMsg = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      roomId: arg,
      text: text.trim(),
      timestamp: DateTime.now(),
      isMine: true,
      status: MessageStatus.sent,
      messageType: MessageType.text,
    );
    state = [...state, newMsg];

    final sentMsg = await _repository.sendMessage(newMsg);
    state = state.map((m) => m.id == sentMsg.id ? sentMsg.copyWith(status: MessageStatus.delivered) : m).toList();
    ref.read(chatRoomsProvider.notifier).loadRooms();

    // Trigger auto reply
    Future.delayed(const Duration(milliseconds: 1500), () async {
      final reply = await _repository.generateAutoReply(arg, newMsg);
      if (reply != null) {
        state = [...state, reply];
        state = state.map((m) => m.isMine ? m.copyWith(status: MessageStatus.read) : m).toList();
        ref.read(chatRoomsProvider.notifier).loadRooms();
      }
    });
  }

  Future<void> sendMediaMessage(MessageType type, String caption, String mediaUrl) async {
    final newMsg = ChatMessageModel(
      id: 'msg_media_${DateTime.now().millisecondsSinceEpoch}',
      roomId: arg,
      text: caption.isNotEmpty ? caption : (type == MessageType.image ? '📷 Foto Lampiran' : '🎥 Video Lampiran'),
      timestamp: DateTime.now(),
      isMine: true,
      status: MessageStatus.sent,
      messageType: type,
      mediaUrl: mediaUrl,
    );
    state = [...state, newMsg];

    final sentMsg = await _repository.sendMessage(newMsg);
    state = state.map((m) => m.id == sentMsg.id ? sentMsg.copyWith(status: MessageStatus.delivered) : m).toList();
    ref.read(chatRoomsProvider.notifier).loadRooms();

    Future.delayed(const Duration(milliseconds: 1800), () async {
      final reply = await _repository.generateAutoReply(arg, newMsg);
      if (reply != null) {
        state = [...state, reply];
        state = state.map((m) => m.isMine ? m.copyWith(status: MessageStatus.read) : m).toList();
        ref.read(chatRoomsProvider.notifier).loadRooms();
      }
    });
  }
}
