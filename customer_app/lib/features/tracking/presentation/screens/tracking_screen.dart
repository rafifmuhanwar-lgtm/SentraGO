import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../order/domain/models/order_model.dart';

class TrackingScreen extends StatelessWidget {
  final OrderModel order;

  const TrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isJastip = order.orderType == 'jastip';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(isJastip ? 'Lacak Titip Belanja' : 'Lacak Suruh Kurir'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCourierCard(context, isJastip),
            const SizedBox(height: 24),
            _buildTimeline(context, isJastip),
            if (isJastip) ...[
              const SizedBox(height: 24),
              _buildShoppingInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCourierCard(BuildContext context, bool isJastip) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Icon(
              isJastip ? Icons.storefront_rounded : Icons.motorcycle_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.courierName != 'Mencari Kurir...' ? order.courierName : 'Kurir',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isJastip
                      ? 'Sedang menuju ke lokasi toko'
                      : 'Menuju lokasi penjemputan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              order.estimasiWaktu ?? '30 min',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, bool isJastip) {
    final steps = isJastip ? _jastipSteps(context) : _suruhSteps(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: steps,
      ),
    );
  }

  List<Widget> _jastipSteps(BuildContext context) {
    // Timeline standar: langkah 1-2 selesai, langkah 3 berlangsung, sisanya menunggu
    return [
      _buildTimelineItem(context,
        icon: Icons.check_circle,
        title: 'Pesanan Dibuat',
        subtitle: 'Pesanan berhasil dibuat & dikirim ke kurir',
        isCompleted: true,
        isLast: false,
      ),
      _buildTimelineItem(context,
        icon: Icons.check_circle,
        title: 'Kurir Menuju Toko',
        subtitle: 'Kurir sedang dalam perjalanan ke lokasi pembelian',
        isCompleted: true,
        isLast: false,
      ),
      _buildTimelineItem(context,
        icon: Icons.shopping_bag_rounded,
        title: 'Sedang Dibelikan Kurir',
        subtitle: 'Kurir membeli barang pesanan kamu di toko',
        isCompleted: false,
        isCurrent: true,
        isLast: false,
      ),
      _buildTimelineItem(context,
        icon: Icons.delivery_dining_rounded,
        title: 'Dalam Perjalanan ke Customer',
        subtitle: 'Kurir menuju lokasi pengantaran kamu',
        isCompleted: false,
        isLast: false,
      ),
      _buildTimelineItem(context,
        icon: Icons.location_on_rounded,
        title: 'Pesanan Selesai',
        subtitle: 'Barang telah diterima',
        isCompleted: false,
        isLast: true,
      ),
    ];
  }

  List<Widget> _suruhSteps(BuildContext context) {
    return [
      _buildTimelineItem(context,
        icon: Icons.check_circle,
        title: 'Pesanan Dibuat',
        subtitle: 'Tugas berhasil dikirim ke kurir',
        isCompleted: true,
        isLast: false,
      ),
      _buildTimelineItem(context,
        icon: Icons.check_circle,
        title: 'Kurir Menuju Penjemputan',
        subtitle: 'Kurir menuju lokasi yang ditentukan',
        isCompleted: true,
        isLast: false,
      ),
      _buildTimelineItem(context,
        icon: Icons.motorcycle_rounded,
        title: 'Tugas Sedang Dilakukan',
        subtitle: 'Kurir sedang menjalankan tugas kamu',
        isCompleted: false,
        isCurrent: true,
        isLast: false,
      ),
      _buildTimelineItem(context,
        icon: Icons.delivery_dining_rounded,
        title: 'Dalam Perjalanan ke Tujuan',
        subtitle: 'Kurir menuju lokasi tujuan',
        isCompleted: false,
        isLast: false,
      ),
      _buildTimelineItem(context,
        icon: Icons.flag_rounded,
        title: 'Pesanan Selesai',
        subtitle: 'Tugas telah selesai dilaksanakan',
        isCompleted: false,
        isLast: true,
      ),
    ];
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isCurrent = false,
    required bool isLast,
  }) {
    final color = isCompleted
        ? AppColors.success
        : (isCurrent ? AppColors.primary : AppColors.border);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : (isCurrent
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
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
                          : Icon(icon, size: 18, color: AppColors.border)),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 50,
                    color: isCompleted ? AppColors.success : AppColors.border,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: isCompleted || isCurrent
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isCompleted || isCurrent
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCompleted
                              ? AppColors.success
                              : (isCurrent
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                          fontWeight:
                              isCompleted ? FontWeight.w500 : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Info belanja — khusus Jastip
  Widget _buildShoppingInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Informasi Belanja', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(context, 'Dana Belanja', 'Rp ${order.danaBelanja.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _infoRow(context, 'Ongkir', 'Rp ${order.ongkir.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          _infoRow(context, 'Total Dibayar', 'Rp ${order.totalAmount.toStringAsFixed(0)}', isBold: true),
          if (order.pickupAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _infoRow(context, 'Lokasi Toko', order.pickupAddress),
            const SizedBox(height: 6),
            _infoRow(context, 'Tujuan', order.deliveryAddress),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
