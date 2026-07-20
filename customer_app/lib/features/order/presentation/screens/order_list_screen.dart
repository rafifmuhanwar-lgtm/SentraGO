import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/order_model.dart';
import '../providers/order_provider.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredOrders = ref.watch(filteredOrdersProvider);
    final currentFilter = ref.watch(orderFilterProvider);
    final searchQuery = ref.watch(orderSearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Burgundy Header & Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesanan Saya',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pantau pesanan aktif & riwayat transaksi Anda',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar inside Header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      onChanged: (val) {
                        ref.read(orderSearchQueryProvider.notifier).setSearchQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nomor order, layanan, atau nama kurir...',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                                onPressed: () {
                                  ref.read(orderSearchQueryProvider.notifier).setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category/Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    ref,
                    title: 'Semua',
                    filter: OrderStatusFilter.all,
                    isSelected: currentFilter == OrderStatusFilter.all,
                  ),
                  const SizedBox(height: 0, width: 10),
                  _buildFilterChip(
                    context,
                    ref,
                    title: 'Sedang Berjalan',
                    filter: OrderStatusFilter.ongoing,
                    isSelected: currentFilter == OrderStatusFilter.ongoing,
                    showPulse: true,
                  ),
                  const SizedBox(height: 0, width: 10),
                  _buildFilterChip(
                    context,
                    ref,
                    title: 'Riwayat Selesai',
                    filter: OrderStatusFilter.completed,
                    isSelected: currentFilter == OrderStatusFilter.completed,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Order List Section
            Expanded(
              child: filteredOrders.isEmpty
                  ? _buildEmptyState(context, currentFilter)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return _OrderCard(order: order);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required OrderStatusFilter filter,
    required bool isSelected,
    bool showPulse = false,
  }) {
    return GestureDetector(
      onTap: () => ref.read(orderFilterProvider.notifier).setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
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
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPulse && !isSelected) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, OrderStatusFilter filter) {
    String title = 'Tidak Ada Pesanan';
    String desc = 'Belum ada transaksi yang sesuai dengan pencarian Anda.';
    if (filter == OrderStatusFilter.ongoing) {
      title = 'Belum Ada Pesanan Aktif';
      desc = 'Semua pesanan Anda sudah selesai diantar atau belum ada yang baru dibuat.';
    } else if (filter == OrderStatusFilter.completed) {
      title = 'Belum Ada Riwayat';
      desc = 'Anda belum memiliki riwayat pesanan yang selesai.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOngoing = order.status == OrderStatus.ongoing;
    final isCompleted = order.status == OrderStatus.completed;

    return InkWell(
      onTap: () => context.push('/order/detail', extra: order),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOngoing ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
            width: isOngoing ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Service Pill & Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.serviceName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusPill(context, isOngoing, isCompleted),
              ],
            ),

            const SizedBox(height: 12),

            // Row 2: Title & Order ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  order.id,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Description Snippet
            Text(
              order.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.border),
            ),

            // Row 3: Courier Info & Price
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: NetworkImage(order.courierAvatar),
                  onBackgroundImageError: (_, __) {},
                  child: order.courierAvatar.isEmpty
                      ? const Icon(Icons.person, size: 18, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kurir: ${order.courierName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        _formatTimeAgo(order.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatCurrency(order.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Row 4: Action Buttons
            Row(
              children: [
                if (isOngoing) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to Chat Room with this courier
                        final rooms = ref.read(chatRoomsProvider);
                        try {
                          final room = rooms.firstWhere((r) => r.id == order.chatRoomId);
                          context.push('/chat/room', extra: room);
                        } catch (_) {
                          // Fallback: Show toast / alert if room not found or open first room
                          if (rooms.isNotEmpty) {
                            context.push('/chat/room', extra: rooms.first);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ruang obrolan kurir sedang dimuat...')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Chat Kurir', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Reorder navigation
                        if (order.serviceName.contains('Jastip')) {
                          context.push('/jastip');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Membuat ulang pesanan ${order.serviceName}...')),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Pesan Lagi', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/order/detail', extra: order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOngoing ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: isOngoing ? Colors.white : AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Lihat Detail', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, bool isOngoing, bool isCompleted) {
    Color bg;
    Color fg;
    IconData? icon;

    if (isOngoing) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
    } else if (isCompleted) {
      bg = AppColors.primary.withValues(alpha: 0.1);
      fg = AppColors.primary;
      icon = Icons.check_circle_outline;
    } else {
      bg = AppColors.error.withValues(alpha: 0.12);
      fg = AppColors.error;
      icon = Icons.cancel_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOngoing) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ] else if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            order.statusText,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final intValue = amount.toInt();
    final stringValue = intValue.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = stringValue.length - 1; i >= 0; i--) {
      buffer.write(stringValue[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    } else {
      return '${diff.inDays}h lalu';
    }
  }
}
