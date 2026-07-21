import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Lacak Pesanan'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCourierCard(context),
            const SizedBox(height: 24),
            _buildTimeline(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierCard(BuildContext context) {
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
            child: const Icon(Icons.motorcycle_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kurir Andi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sedang menuju ke lokasi penjual',
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
            child: const Text(
              '15 min',
              style: TextStyle(
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

  Widget _buildTimeline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildTimelineItem(
            context,
            icon: Icons.check_circle,
            title: 'Pesanan Dibuat',
            subtitle: 'Hari ini, 14:30',
            isCompleted: true,
            isLast: false,
          ),
          _buildTimelineItem(
            context,
            icon: Icons.check_circle,
            title: 'Kurir Diterima',
            subtitle: 'Hari ini, 14:35',
            isCompleted: true,
            isLast: false,
          ),
          _buildTimelineItem(
            context,
            icon: Icons.motorcycle_rounded,
            title: 'Kurir Menuju Penjual',
            subtitle: 'Sedang berlangsung',
            isCompleted: false,
            isLast: false,
          ),
          _buildTimelineItem(
            context,
            icon: Icons.shopping_bag_rounded,
            title: 'Barang Dibeli',
            subtitle: 'Menunggu',
            isCompleted: false,
            isLast: false,
          ),
          _buildTimelineItem(
            context,
            icon: Icons.location_on_rounded,
            title: 'Pesanan Sampai',
            subtitle: 'Estimasi 30 menit',
            isCompleted: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLast,
  }) {
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
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : icon,
                    size: 18,
                    color: isCompleted ? Colors.white : AppColors.primary,
                  ),
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
                          fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isCompleted ? AppColors.success : AppColors.textSecondary,
                          fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
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
}
