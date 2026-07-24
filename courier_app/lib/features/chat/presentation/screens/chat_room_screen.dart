import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/chat_room_model.dart';
import '../../domain/models/chat_message_model.dart';
import '../providers/chat_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final ChatRoomModel room;

  const ChatRoomScreen({super.key, required this.room});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Quick replies untuk kurir
  final List<String> _quickReplies = [
    'Sedang dalam perjalanan 🛵',
    'Sudah sampai lokasi jemput 📍',
    'Pesanan sudah diambil ✅',
    'Dalam perjalanan ke tujuan 🚀',
    'Hampir sampai, sekitar 5 menit lagi',
    'Terima kasih! Semoga puas 🙏',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref
        .read(chatRoomMessagesProvider(widget.room.id).notifier)
        .sendTextMessage(text);
    _scrollToBottom();
  }

  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Kirim Media',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.camera_alt,
                      color: Colors.purple,
                      label: 'Kamera',
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(chatRoomMessagesProvider(widget.room.id).notifier).pickAndSendMedia(MessageType.image, ImageSource.camera);
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.photo_library,
                      color: Colors.blue,
                      label: 'Galeri Foto',
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(chatRoomMessagesProvider(widget.room.id).notifier).pickAndSendMedia(MessageType.image, ImageSource.gallery);
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.videocam,
                      color: Colors.orange,
                      label: 'Video',
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(chatRoomMessagesProvider(widget.room.id).notifier).pickAndSendMedia(MessageType.video, ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatRoomMessagesProvider(widget.room.id));

    ref.listen(chatRoomMessagesProvider(widget.room.id), (_, __) {
      _scrollToBottom();
    });

    bool isExpired = false;
    if (widget.room.orderStatus == 'completed' && widget.room.orderUpdatedAt != null) {
      final diff = DateTime.now().difference(widget.room.orderUpdatedAt!);
      if (diff.inHours >= 6) {
        isExpired = true;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyMessages()
                : _buildMessageList(messages),
          ),
          if (isExpired)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50,
              child: const Text(
                'Sesi chat telah berakhir (melewati batas 6 jam setelah pesanan selesai).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            )
          else ...[
            _buildQuickReplies(),
            _buildInputBar(),
          ],
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final orderBadge = widget.room.orderType == 'jastip' ? 'Jastip' : 'Suruh';
    final badgeColor = widget.room.orderType == 'jastip'
        ? AppColors.primary
        : AppColors.warning;

    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: widget.room.avatarUrl.isNotEmpty
                ? NetworkImage(widget.room.avatarUrl)
                : null,
            child: widget.room.avatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.customerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        orderBadge,
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (widget.room.orderTitle.isNotEmpty)
                      Flexible(
                        child: Text(
                          widget.room.orderTitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada pesan',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mulai chat dengan pelanggan',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isFirst = index == 0 ||
            messages[index - 1].isMine != msg.isMine;
        return _buildMessageBubble(msg, showAvatar: isFirst && !msg.isMine);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, {bool showAvatar = false}) {
    final isMine = msg.isMine;

    return Padding(
      padding: EdgeInsets.only(
        top: 3,
        bottom: 3,
        left: isMine ? 60 : 0,
        right: isMine ? 0 : 60,
      ),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar pelanggan
          if (!isMine) ...[
            SizedBox(
              width: 32,
              child: showAvatar
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: widget.room.avatarUrl.isNotEmpty
                          ? NetworkImage(widget.room.avatarUrl)
                          : null,
                      child: widget.room.avatarUrl.isEmpty
                          ? const Icon(Icons.person,
                              size: 14, color: AppColors.primary)
                          : null,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          // Bubble
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMine
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isMine
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (msg.messageType == MessageType.image && msg.mediaUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          msg.mediaUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      ),
                    )
                  else if (msg.messageType == MessageType.video && msg.mediaUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(msg.mediaUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                        child: Container(
                          width: 200,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.play_circle_fill, size: 48, color: Colors.white70),
                          ),
                        ),
                      ),
                    ),
                  if (msg.text.isNotEmpty) ...[
                    Text(
                      msg.text,
                      style: TextStyle(
                        color: isMine ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.formattedTime,
                        style: TextStyle(
                          color: isMine
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.status == MessageStatus.read
                              ? Icons.done_all
                              : msg.status == MessageStatus.delivered
                                  ? Icons.done_all
                                  : Icons.done,
                          size: 13,
                          color: msg.status == MessageStatus.read
                              ? Colors.lightBlueAccent
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      height: 40,
      color: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              ref
                  .read(chatRoomMessagesProvider(widget.room.id).notifier)
                  .sendTextMessage(_quickReplies[index]);
              _scrollToBottom();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                _quickReplies[index],
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: AppColors.primary),
                onPressed: _showAttachmentBottomSheet,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan...',
                      hintStyle: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol kirim
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
