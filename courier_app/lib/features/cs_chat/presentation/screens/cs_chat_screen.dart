import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/cs_message_model.dart';

/// Layar Live Chat dengan Customer Service — real dari Appwrite
class CsChatScreen extends ConsumerStatefulWidget {
  const CsChatScreen({super.key});

  @override
  ConsumerState<CsChatScreen> createState() => _CsChatScreenState();
}

class _CsChatScreenState extends ConsumerState<CsChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<CsChatMessage> _messages = [];
  bool _isLoading = false;

  // Room ID khusus CS: cs_chat_{courierId}
  String get _roomId {
    final courier = ref.read(authStateProvider).courier;
    return 'cs_chat_${courier?.id ?? 'guest'}';
  }

  String get _senderName {
    final courier = ref.read(authStateProvider).courier;
    return courier?.name ?? 'Kurir';
  }

  String get _senderId {
    final courier = ref.read(authStateProvider).courier;
    return courier?.id ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseServiceProvider);
      final docs = await db.getChatMessages(_roomId);
      setState(() {
        _messages = docs.map((doc) => CsChatMessage.fromMap(doc, _senderId)).toList();
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();

    try {
      final db = ref.read(databaseServiceProvider);
      await db.createChatMessage(data: {
        'orderId': _roomId,
        'senderId': _senderId,
        'senderName': _senderName,
        'senderRole': 'courier',
        'message': text.trim(),
        'messageType': 'text',
        'timestamp': DateTime.now().toIso8601String(),
      });
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  final List<String> _quickReplies = [
    'Saya ingin bertanya tentang pesanan',
    'Ada kendala dengan aplikasi',
    'Cara tarik saldo?',
    'Hubungkan dengan CS',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Icon(Icons.headset_mic, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer Service', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                    SizedBox(width: 4),
                    Text('Online', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20, color: Colors.white70),
              onPressed: _loadMessages,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          // Quick replies
          Container(
            height: 40,
            color: AppColors.surface,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _sendMessage(_quickReplies[index]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _quickReplies[index],
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
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
                            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (v) { _sendMessage(v); },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendMessage(_messageController.text),
                      child: Container(
                        width: 44, height: 44,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('Mulai chat dengan Customer Service', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _sendMessage('Halo, saya ingin bertanya'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Mulai Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildBubble(msg);
      },
    );
  }

  Widget _buildBubble(CsChatMessage msg) {
    final isCs = msg.isFromAdmin;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: isCs ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isCs) ...[
            const CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Icon(Icons.headset_mic, size: 14, color: Colors.white)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCs ? Colors.white : AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isCs ? const Radius.circular(4) : const Radius.circular(18),
                  bottomRight: isCs ? const Radius.circular(18) : const Radius.circular(4),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: isCs ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  if (isCs && msg.senderName.isNotEmpty)
                    Text(msg.senderName, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    msg.text,
                    style: TextStyle(color: isCs ? AppColors.textPrimary : Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.formattedTime,
                    style: TextStyle(color: isCs ? AppColors.textSecondary : Colors.white.withValues(alpha: 0.7), fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
