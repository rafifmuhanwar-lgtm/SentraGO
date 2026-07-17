import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/order_model.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOngoing = order.status == OrderStatus.ongoing;
    final isCompleted = order.status == OrderStatus.completed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.id,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              order.serviceName,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner / Progress Steps
            _buildStatusTracker(context, isOngoing, isCompleted),

            const SizedBox(height: 20),

            // Courier Card
            _buildCourierCard(context, ref, isOngoing),

            const SizedBox(height: 20),

            // Locations (Pickup -> Delivery)
            _buildLocationCard(context),

            const SizedBox(height: 20),

            // Order Items & Notes
            _buildItemsCard(context),

            const SizedBox(height: 20),

            // Pricing Breakdown
            _buildPricingCard(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, ref, isOngoing, isCompleted),
    );
  }

  Widget _buildStatusTracker(BuildContext context, bool isOngoing, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Pesanan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isOngoing
                      ? AppColors.success.withValues(alpha: 0.12)
                      : (isCompleted ? AppColors.primary.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.statusText,
                  style: TextStyle(
                    color: isOngoing
                        ? AppColors.success
                        : (isCompleted ? AppColors.primary : AppColors.error),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Steps
          _buildStepRow(
            context,
            title: 'Pesanan Dibuat & Dikirim ke Kurir',
            subtitle: 'Sistem telah menemukan kurir untuk Anda',
            isDone: true,
            isCurrent: false,
            isLast: false,
          ),
          _buildStepRow(
            context,
            title: 'Kurir Menuju Toko / Penjemputan',
            subtitle: 'Kurir sedang dalam perjalanan ke lokasi jemput',
            isDone: true,
            isCurrent: isOngoing && order.statusText.contains('Jemput'),
            isLast: false,
          ),
          _buildStepRow(
            context,
            title: 'Sedang Dibelikan / Diambil',
            subtitle: 'Kurir memeriksa barang pesanan Anda',
            isDone: isCompleted || (isOngoing && order.statusText.contains('Dibelikan')),
            isCurrent: isOngoing && order.statusText.contains('Dibelikan'),
            isLast: false,
          ),
          _buildStepRow(
            context,
            title: 'Pesanan Selesai Diantar',
            subtitle: 'Barang telah diterima di lokasi tujuan',
            isDone: isCompleted,
            isCurrent: isCompleted,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
  }) {
    final color = isDone || isCurrent ? AppColors.primary : AppColors.border;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.primary
                    : (isCurrent ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : (isCurrent
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isDone ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isCurrent || isDone ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent || isDone ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourierCard(BuildContext context, WidgetRef ref, bool isOngoing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: NetworkImage(order.courierAvatar),
            onBackgroundImageError: (_, __) {},
            child: order.courierAvatar.isEmpty
                ? const Icon(Icons.person, size: 28, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.courierName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '4.9 (128+ order)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Memanggil kurir di nomor ${order.courierPhone}...')),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.phone),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              final rooms = ref.read(chatRoomsProvider);
              try {
                final room = rooms.firstWhere((r) => r.id == order.chatRoomId);
                context.push('/chat/room', extra: room);
              } catch (_) {
                if (rooms.isNotEmpty) {
                  context.push('/chat/room', extra: rooms.first);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Memuat ruang chat kurir...')),
                  );
                }
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokasi Pengantaran',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.storefront, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lokasi Toko / Jemput', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(order.pickupAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
            child: Container(
              width: 2,
              height: 24,
              color: AppColors.border,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: AppColors.error, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tujuan Pengantaran', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(order.deliveryAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Barang / Pesanan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            order.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            order.description,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context) {
    final double itemPrice = (order.totalAmount - 12000).clamp(0.0, double.infinity).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Biaya',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimasi Harga Item', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(_formatCurrency(itemPrice), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jasa Pengantaran Kurir', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text('Rp 10.000', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Biaya Platform & Layanan', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text('Rp 2.000', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                _formatCurrency(order.totalAmount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, bool isOngoing, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: isOngoing
          ? ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kurir sedang dalam proses pengantaran. Terima kasih!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Konfirmasi & Lacak Kurir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            )
          : (isCompleted
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Terima kasih atas ulasan bintang 5 Anda! ⭐⭐⭐⭐⭐')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Beri Ulasan ⭐', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (order.serviceName.contains('Jastip')) {
                            context.push('/jastip');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Memesan ulang ${order.serviceName}...')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Pesan Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Kembali ke Daftar Pesanan'),
                )),
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
}
