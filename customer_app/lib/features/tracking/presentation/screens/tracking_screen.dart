import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_service.dart';
import '../../../order/domain/models/order_model.dart';
import '../../../order/data/repositories/order_repository.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const TrackingScreen({super.key, required this.order});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  late OrderModel _order;
  Map<String, dynamic>? _courierData;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _fetchCourierData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;
      await _refreshOrder();
    });
  }

  Future<void> _refreshOrder() async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      final updated = await repo.getOrderById(_order.id);
      if (updated != null && mounted) {
        setState(() => _order = updated);
        if (_order.courierId.isNotEmpty && _courierData == null) {
          await _fetchCourierData();
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchCourierData() async {
    if (_order.courierId.isEmpty) return;
    try {
      final db = ref.read(databaseServiceProvider);
      final data = await db.getCourierById(_order.courierId);
      if (mounted) setState(() => _courierData = data);
    } catch (_) {}
  }

  String get _courierName =>
      _courierData?['name'] as String? ??
      (_order.courierName.isNotEmpty ? _order.courierName : '');

  String get _courierPhone =>
      _courierData?['phone'] as String? ?? _order.courierPhone;

  String get _courierAvatar =>
      _courierData?['photoUrl'] as String? ?? _order.courierAvatar;

  /// Tentukan step aktif berdasarkan statusText
  int _getCurrentStep() {
    final st = _order.statusText.toLowerCase();
    final hasCourier = _order.courierId.isNotEmpty;

    if (_order.status == OrderStatus.completed || st == 'pesanan selesai') return 4;
    // Barang dibeli / Tugas selesai -> Tahap 'Sedang Dibelikan' selesai, masuk ke tahap pengantaran
    if (st.contains('dalam perjalanan ke tujuan') || st.contains('barang dibeli') || st.contains('tugas selesai')) return 3;
    if (st.contains('sampai di lokasi') || st.contains('dibelikan') || st.contains('diambil')) return 2;
    if (st.contains('menuju lokasi') || st.contains('jemput') || st.contains('assigned') || hasCourier) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isJastip = _order.orderType == 'jastip';
    final currentStep = _getCurrentStep();
    final hasCourier = _courierName.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(isJastip ? 'Lacak Titip Belanja' : 'Lacak Suruh Kurir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrder,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCourierCard(context, isJastip, hasCourier, currentStep),
            const SizedBox(height: 24),
            _buildTimeline(context, isJastip, currentStep),
            if (isJastip) ...[
              const SizedBox(height: 24),
              _buildShoppingInfo(context),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierCard(BuildContext context, bool isJastip, bool hasCourier, int currentStep) {
    // Status teks yang ditampilkan di bawah nama kurir
    final String statusLabel;
    if (_order.status == OrderStatus.completed) {
      statusLabel = 'Pesanan telah selesai ✓';
    } else if (_order.statusText.isNotEmpty) {
      statusLabel = _order.statusText;
    } else if (hasCourier) {
      statusLabel = isJastip ? 'Kurir sedang menuju toko' : 'Kurir menuju lokasi penjemputan';
    } else {
      statusLabel = 'Sedang mencari kurir terdekat...';
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCourier
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          width: hasCourier ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar kurir
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: _courierAvatar.isNotEmpty ? NetworkImage(_courierAvatar) : null,
            onBackgroundImageError: _courierAvatar.isNotEmpty ? (_, __) {} : null,
            child: _courierAvatar.isEmpty
                ? Icon(
                    hasCourier
                        ? Icons.person
                        : (isJastip ? Icons.search : Icons.search),
                    color: AppColors.primary,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCourier ? _courierName : 'Mencari Kurir...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasCourier ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _order.status == OrderStatus.completed
                            ? AppColors.success
                            : (hasCourier ? AppColors.primary : AppColors.textSecondary),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (hasCourier && _courierPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _courierPhone,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Estimasi waktu atau badge selesai
          if (_order.status == OrderStatus.completed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Selesai ✓',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _order.estimasiWaktu ?? '~30 min',
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

  Widget _buildTimeline(BuildContext context, bool isJastip, int currentStep) {
    final steps = isJastip ? _jastipSteps(currentStep) : _suruhSteps(currentStep);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: steps),
    );
  }

  List<Widget> _jastipSteps(int currentStep) {
    return [
      _buildTimelineItem(
        icon: Icons.check_circle,
        title: 'Pesanan Dibuat',
        subtitle: 'Pesanan berhasil dibuat & dikirim ke kurir',
        isCompleted: currentStep >= 0,
        isCurrent: currentStep == 0,
        isLast: false,
      ),
      _buildTimelineItem(
        icon: Icons.motorcycle_rounded,
        title: 'Kurir Menuju Toko',
        subtitle: 'Kurir sedang dalam perjalanan ke lokasi pembelian',
        isCompleted: currentStep >= 2,
        isCurrent: currentStep == 1,
        isLast: false,
      ),
      _buildTimelineItem(
        icon: Icons.shopping_bag_rounded,
        title: 'Sedang Dibelikan Kurir',
        subtitle: 'Kurir membeli barang pesanan kamu di toko',
        isCompleted: currentStep >= 3,
        isCurrent: currentStep == 2,
        isLast: false,
      ),
      _buildTimelineItem(
        icon: Icons.delivery_dining_rounded,
        title: 'Dalam Perjalanan ke Customer',
        subtitle: 'Kurir menuju lokasi pengantaran kamu',
        isCompleted: currentStep >= 4,
        isCurrent: currentStep == 3,
        isLast: false,
      ),
      _buildTimelineItem(
        icon: Icons.location_on_rounded,
        title: 'Pesanan Selesai',
        subtitle: 'Barang telah diterima',
        isCompleted: currentStep >= 4,
        isCurrent: currentStep == 4,
        isLast: true,
      ),
    ];
  }

  List<Widget> _suruhSteps(int currentStep) {
    return [
      _buildTimelineItem(
        icon: Icons.check_circle,
        title: 'Pesanan Dibuat',
        subtitle: 'Tugas berhasil dikirim ke kurir',
        isCompleted: currentStep >= 0,
        isCurrent: currentStep == 0,
        isLast: false,
      ),
      _buildTimelineItem(
        icon: Icons.motorcycle_rounded,
        title: 'Kurir Menuju Penjemputan',
        subtitle: 'Kurir menuju lokasi yang ditentukan',
        isCompleted: currentStep >= 2,
        isCurrent: currentStep == 1,
        isLast: false,
      ),
      _buildTimelineItem(
        icon: Icons.assignment_turned_in_rounded,
        title: 'Tugas Sedang Dilakukan',
        subtitle: 'Kurir sedang menjalankan tugas kamu',
        isCompleted: currentStep >= 3,
        isCurrent: currentStep == 2,
        isLast: false,
      ),
      _buildTimelineItem(
        icon: Icons.delivery_dining_rounded,
        title: 'Dalam Perjalanan ke Tujuan',
        subtitle: 'Kurir menuju lokasi tujuan',
        isCompleted: currentStep >= 4,
        isCurrent: currentStep == 3,
        isLast: false,
      ),
      _buildTimelineItem(
        icon: Icons.flag_rounded,
        title: 'Pesanan Selesai',
        subtitle: 'Tugas telah selesai dilaksanakan',
        isCompleted: currentStep >= 4,
        isCurrent: currentStep == 4,
        isLast: true,
      ),
    ];
  }

  Widget _buildTimelineItem({
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

    return Builder(builder: (context) {
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
    });
  }

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
              Text(
                'Informasi Belanja',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(context, 'Dana Belanja', _formatCurrency(_order.danaBelanja)),
          const SizedBox(height: 6),
          _infoRow(context, 'Ongkir', _formatCurrency(_order.ongkir)),
          const SizedBox(height: 6),
          _infoRow(context, 'Total Dibayar', _formatCurrency(_order.totalAmount), isBold: true),
          if (_order.pickupAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _infoRow(context, 'Lokasi Toko', _order.pickupAddress),
            const SizedBox(height: 6),
            _infoRow(context, 'Tujuan', _order.deliveryAddress),
          ],
          if (_courierName.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _infoRow(context, 'Kurir', _courierName),
            if (_courierPhone.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(context, 'Telepon Kurir', _courierPhone),
            ],
          ],
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
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  Widget _infoRow(BuildContext context, String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
