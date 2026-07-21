import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/chat_room_model.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _searchQuery = '';
  int _selectedCategoryIndex = 0; // 0: Semua, 1: Kurir, 2: Bantuan CS
  final List<String> _categories = ['Semua', 'Kurir', 'Bantuan CS'];

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(chatRoomsProvider);
    final isLoading = ref.watch(chatRoomsProvider.notifier).isLoading;

    final filteredRooms = rooms.where((room) {
      // Filter by search
      final matchesSearch = room.senderName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          room.serviceType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          room.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by category
      if (_selectedCategoryIndex == 1 && room.isSupport) return false;
      if (_selectedCategoryIndex == 2 && !room.isSupport) return false;

      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top Header Section ──
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesan & Obrolan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hubungi kurir atau layanan bantuan SentraGO',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 18),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Cari nama kurir atau pesanan...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category Filters ──
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Chat Rooms List ──
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredRooms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada obrolan ditemukan',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          await ref.read(chatRoomsProvider.notifier).refresh();
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: filteredRooms.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final room = filteredRooms[index];
                            return _buildChatRoomCard(context, room);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomCard(BuildContext context, ChatRoomModel room) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.push('/chat/room', extra: room);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar with Online indicator
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: CachedNetworkImage(
                        imageUrl: room.avatarUrl,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.primaryLight.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.primaryLight.withValues(alpha: 0.2),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: room.isOnline ? AppColors.success : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              room.senderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(room.lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: room.unreadCount > 0 ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: room.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Service Type Pill & Online/Last Seen text
                      Row(
                        children: [
                          if (room.serviceType.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: room.isSupport
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                room.serviceType,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: room.isSupport ? Colors.blue[800] : AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            room.lastSeenText,
                            style: TextStyle(
                              fontSize: 11,
                              color: room.isOnline ? AppColors.success : AppColors.textSecondary,
                              fontWeight: room.isOnline ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Last Message & Unread Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              room.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: room.unreadCount > 0
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: room.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (room.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                room.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0 && now.day == time.day) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (now.difference(time).inDays == 1 || (now.difference(time).inDays == 0 && now.day != time.day)) {
      return 'Kemarin';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
