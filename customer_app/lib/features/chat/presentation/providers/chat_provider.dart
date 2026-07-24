import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/appwrite_client.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/chat_room_model.dart';
import '../../domain/models/chat_message_model.dart';
import '../../data/repositories/chat_repository.dart';

final chatRoomsProvider = NotifierProvider<ChatRoomsNotifier, List<ChatRoomModel>>(() {
  return ChatRoomsNotifier();
});

class ChatRoomsNotifier extends Notifier<List<ChatRoomModel>> {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  @override
  List<ChatRoomModel> build() {
    Future.microtask(() => loadRooms());
    return [];
  }

  Future<void> loadRooms() async {
    _isLoading = true;
    final rooms = await _repository.getChatRooms();
    state = rooms;
    _isLoading = false;
  }

  Future<void> refresh() async => loadRooms();
}

final chatRoomMessagesProvider =
    NotifierProvider.family<ChatRoomMessagesNotifier, List<ChatMessageModel>, String>(
        (arg) => ChatRoomMessagesNotifier(arg));

class ChatRoomMessagesNotifier extends Notifier<List<ChatMessageModel>> {
  final String arg;
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  RealtimeSubscription? _subscription;

  ChatRoomMessagesNotifier(this.arg);

  @override
  List<ChatMessageModel> build() {
    Future.microtask(() => loadMessages());
    _setupRealtime();

    ref.onDispose(() {
      _subscription?.close();
    });
    return [];
  }

  void _setupRealtime() {
    if (arg == 'room_cs') return;

    final realtime = ref.read(realtimeProvider);
    final userId = ref.read(authStateProvider).user?.id ?? '';

    _subscription = realtime.subscribe([
      'databases.${AppConfig.appwriteDatabaseId}.collections.${AppConfig.chatsCollection}.documents'
    ]);

    _subscription!.stream.listen((response) {
      if (response.events
          .contains('databases.*.collections.*.documents.*.create')) {
        final data = response.payload;
        // Hanya terima pesan untuk room ini yang bukan dari diri sendiri
        if (data['orderId'] == arg && data['senderId'] != userId) {
          final newMsg = ChatMessageModel.fromJson(data, userId);
          if (!state.any((m) => m.id == newMsg.id)) {
            state = [...state, newMsg];
            // Update last message di room list
            ref.read(chatRoomsProvider.notifier).loadRooms();
          }
        }
      }
    });
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
      senderRole: 'customer',
    );
    state = [...state, newMsg];

    final sentMsg = await _repository.sendMessage(newMsg);
    state = state
        .map((m) => m.id == newMsg.id
            ? sentMsg.copyWith(status: MessageStatus.delivered)
            : m)
        .toList();
    ref.read(chatRoomsProvider.notifier).loadRooms();
  }

  Future<void> pickAndSendMedia(MessageType type, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file = type == MessageType.image 
        ? await picker.pickImage(source: source)
        : await picker.pickVideo(source: source);
        
    if (file == null) return;

    final dbService = ref.read(databaseServiceProvider);
    final mediaUrl = await dbService.uploadChatMedia(file.path, file.name);

    if (mediaUrl == null) return;

    final userId = ref.read(authStateProvider).user?.id ?? '';
    final newMsg = ChatMessageModel(
      id: 'msg_media_${DateTime.now().millisecondsSinceEpoch}',
      roomId: arg,
      text: '',
      timestamp: DateTime.now(),
      isMine: true,
      status: MessageStatus.sent,
      messageType: type,
      mediaUrl: mediaUrl,
      senderRole: 'customer',
    );
    state = [...state, newMsg];

    final sentMsg = await _repository.sendMessage(newMsg);
    state = state
        .map((m) => m.id == newMsg.id
            ? sentMsg.copyWith(status: MessageStatus.delivered)
            : m)
        .toList();
    ref.read(chatRoomsProvider.notifier).loadRooms();
  }
}
