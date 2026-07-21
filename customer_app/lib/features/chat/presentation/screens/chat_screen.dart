import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // New chat
            },
          ),
        ],
      ),
      body: _buildChatList(context),
    );
  }

  Widget _buildChatList(BuildContext context) {
    final List<_ChatData> chats = [];

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Belum ada chat',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 80, color: AppColors.divider),
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _buildChatItem(context, chat);
      },
    );
  }

  Widget _buildChatItem(BuildContext context, _ChatData chat) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: chat.color.withValues(alpha: 0.1),
        child: Icon(chat.icon, color: chat.color, size: 24),
      ),
      title: Text(
        chat.name,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: chat.isUnread ? FontWeight.w600 : FontWeight.normal,
            ),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: chat.isUnread ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: chat.isUnread ? FontWeight.w500 : FontWeight.normal,
            ),
      ),
      trailing: Text(
        chat.time,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
      ),
      onTap: () {
        // Open chat detail
      },
    );
  }
}

class _ChatData {
  final String name;
  final String lastMessage;
  final String time;
  final IconData icon;
  final Color color;
  final bool isUnread;

  _ChatData(this.name, this.lastMessage, this.time, this.icon, this.color, this.isUnread);
}
