import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/appwrite_client.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../notification/domain/services/push_notification_sender.dart';
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

            // Create notification untuk pesan baru dari kurir
            if (newMsg.senderRole == 'courier' || newMsg.senderRole == 'support') {
              ref.read(notificationsProvider.notifier).createNotification(
                userId: userId,
                title: 'Pesan Baru 💬',
                body: newMsg.text.length > 100
                    ? '${newMsg.text.substring(0, 100)}...'
                    : newMsg.text,
                category: 'Pesanan',
                routeName: '/chat/room',
              );

              // Send push
              ref.read(pushNotificationSenderProvider).sendToUser(
                userId: userId,
                title: 'Pesan Baru 💬',
                body: newMsg.text.length > 100
                    ? '${newMsg.text.substring(0, 100)}...'
                    : newMsg.text,
                category: 'Pesanan',
                route: '/chat/room',
              );
            }
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

    // Auto reply for CS room
    if (arg == 'room_cs') {
      _autoReplyCS(text.trim());
    }
  }

  Future<void> _autoReplyCS(String userMessage) async {
    final lower = userMessage.toLowerCase();

    String reply;
    if (lower.contains('top up') || lower.contains('topup') || lower.contains('isi saldo')) {
      reply = 'Untuk melakukan Top Up SentraPay Wallet, silakan buka menu Akun > Pembayaran, '
          'lalu klik tombol "Top Up" pada kartu SentraPay Wallet. Anda bisa mengisi saldo '
          'menggunakan QRIS (Scan & Bayar) tanpa biaya admin. Minimal top up Rp 10.000.';
    } else if (lower.contains('cod') || lower.contains('tunai') || lower.contains('bayar di tempat')) {
      reply = 'Saat ini SentraGO tidak mendukung metode pembayaran Tunai (COD). '
          'Hal ini untuk meminimalisir tindakan order fiktif dan memberikan keamanan '
          'bagi Mitra Kurir maupun Pelanggan. Seluruh transaksi dilakukan secara non-tunai '
          'melalui QRIS atau Saldo SentraPay Wallet.';
    } else if (lower.contains('jastip') || lower.contains('belanja')) {
      reply = 'Layanan Jastip Belanja memungkinkan Anda memesan barang dari toko '
          'dan dikirimkan oleh Mitra Kurir SentraGO. Caranya: buka menu Jastip Belanja '
          'dari Beranda, masukkan nama toko dan rincian barang, tentukan lokasi '
          'penjemputan dan pengiriman, lalu pilih metode pembayaran.';
    } else if (lower.contains('suruh') || lower.contains('kurir') || lower.contains('antar')) {
      reply = 'Layanan Suruh Kurir siap membantu Anda untuk mengirim dokumen, '
          'membeli obat, mengambil barang, atau mengantarkan kado dengan cepat. '
          'Batas berat maksimal 20 kg dengan dimensi maksimal 50x50x50 cm.';
    } else if (lower.contains('lupa') || lower.contains('password') || lower.contains('login') || lower.contains('masuk')) {
      reply = 'Jika Anda mengalami kendala login, silakan coba reset password '
          'melalui halaman login dengan menekan "Lupa Password". '
          'Jika masih terkendala, hubungi kami melalui WhatsApp atau Email.';
    } else if (lower.contains('saldo') || lower.contains('balance') || lower.contains('uang')) {
      reply = 'Saldo SentraPay Wallet Anda bisa dicek di menu Akun > Pembayaran. '
          'Saldo bisa digunakan untuk membayar layanan Jastip Belanja dan Suruh Kurir. '
          'Jika saldo kurang, silakan lakukan Top Up terlebih dahulu.';
    } else if (lower.contains('refund') || lower.contains('kembali') || lower.contains('dana kembali')) {
      reply = 'Untuk pengembalian dana (refund), tim Customer Service kami akan '
          'memprosesnya maksimal 1x24 jam setelah pengajuan diverifikasi. '
          'Dana akan dikembalikan ke Saldo SentraPay Wallet Anda.';
    } else if (lower.contains('terima kasih') || lower.contains('makasih') || lower.contains('thanks')) {
      reply = 'Sama-sama! 😊 Senang bisa membantu. Jika ada pertanyaan lain, '
          'jangan ragu untuk menghubungi kami kembali ya.';
    } else if (lower.contains('halo') || lower.contains('hy') || lower.contains('hai') || lower.contains('pagi') || lower.contains('siang') || lower.contains('sore') || lower.contains('malam')) {
      reply = 'Halo! 👋 Ada yang bisa saya bantu? Silakan tanya seputar layanan SentraGO, '
          'top up saldo, atau kendala pesanan Anda.';
    } else {
      reply = 'Maaf, saya belum bisa menjawab pertanyaan tersebut. '
          'Pertanyaan Anda akan segera dialihkan ke Customer Service '
          'asli kami untuk mendapatkan bantuan lebih lanjut. ⏳\n\n'
          'Atau Anda bisa menghubungi kami langsung melalui:\n'
          '📞 WhatsApp: +62 811-900-800\n'
          '📧 Email: support@sentrago.id';
    }

    // Simulate typing delay
    await Future.delayed(const Duration(milliseconds: 1500));

    final csReply = ChatMessageModel(
      id: 'cs_reply_${DateTime.now().millisecondsSinceEpoch}',
      roomId: arg,
      text: reply,
      timestamp: DateTime.now(),
      isMine: false,
      status: MessageStatus.delivered,
      senderRole: 'support',
    );
    state = [...state, csReply];
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
