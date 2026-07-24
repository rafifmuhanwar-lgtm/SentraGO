import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:appwrite/appwrite.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/services/appwrite_client.dart';
import '../../../../core/services/distance_service.dart';
import '../../domain/models/order_model.dart';
import '../../../chat/domain/models/chat_room_model.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../data/repositories/order_repository.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late OrderModel _order;
  Map<String, dynamic>? _courierData;
  Timer? _pollingTimer;
  RealtimeSubscription? _realtimeSubscription;

  double? get _displayKm {
    if (_order.jarakKm != null) return _order.jarakKm;
    if (_order.pickupLat != null && _order.dropoffLat != null) {
      return const Distance().as(
        LengthUnit.Meter,
        LatLng(_order.pickupLat!, _order.pickupLng!),
        LatLng(_order.dropoffLat!, _order.dropoffLng!)
      ) / 1000.0;
    }
    return null;
  }

  String get _displayEstimasi {
    if (_order.estimasiWaktu != null && _order.estimasiWaktu!.isNotEmpty) {
      return _order.estimasiWaktu!;
    }
    final km = _displayKm;
    if (km != null) {
      return '~${(km * 3.5).round()} menit';
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _fetchCourierData();
    _startPolling();
    _setupRealtime();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _realtimeSubscription?.close();
    super.dispose();
  }

  void _setupRealtime() {
    final realtime = ref.read(realtimeProvider);
    _realtimeSubscription = realtime.subscribe([
      'databases.${AppConfig.appwriteDatabaseId}.collections.${AppConfig.ordersCollection}.documents.${_order.id}'
    ]);

    _realtimeSubscription!.stream.listen((response) {
      if (!mounted) return;
      if (response.events.contains('databases.*.collections.*.documents.*.update')) {
        try {
          final updatedOrder = OrderModel.fromJson(response.payload);
          setState(() {
            _order = updatedOrder;
          });
          if (_order.courierId.isNotEmpty && _courierData == null) {
            _fetchCourierData();
          }
        } catch (_) {}
      }
    });
  }

  void _startPolling() {
    // Polling setiap 10 detik untuk update status pesanan
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;
      await _refreshOrder();
    });
  }

  Future<void> _refreshOrder() async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      final orders = await repo.getOrderById(_order.id);
      if (orders != null && mounted) {
        setState(() => _order = orders);
        // Fetch courier data jika courierId berubah
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
      if (mounted) {
        setState(() => _courierData = data);
      }
    } catch (_) {}
  }

  String get _courierName =>
      _courierData?['name'] as String? ??
      (_order.courierName.isNotEmpty ? _order.courierName : '');

  String get _courierPhone =>
      _courierData?['phone'] as String? ?? _order.courierPhone;

  String get _courierAvatar =>
      _courierData?['photoUrl'] as String? ?? _order.courierAvatar;

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
    final isOngoing = _order.status == OrderStatus.ongoing;
    final isCompleted = _order.status == OrderStatus.completed;

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
              _order.id,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _order.serviceName,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
        actions: [
          // Tombol refresh manual
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOrder,
            tooltip: 'Refresh status',
          ),
        ],
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
            _buildCourierCard(context, isOngoing),

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
      bottomNavigationBar: _buildBottomBar(context, isOngoing, isCompleted),
    );
  }

  Widget _buildStatusTracker(BuildContext context, bool isOngoing, bool isCompleted) {
    final currentStep = _getCurrentStep();
    final isJastip = _order.orderType == 'jastip';

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
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOngoing
                        ? AppColors.success.withValues(alpha: 0.12)
                        : (isCompleted ? AppColors.primary.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _order.statusText.isNotEmpty ? _order.statusText : (isOngoing ? 'Memproses Pesanan' : 'Selesai'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isOngoing
                          ? AppColors.success
                          : (isCompleted ? AppColors.primary : AppColors.error),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Steps
          _buildStepRow(
            context,
            title: 'Pesanan Dibuat',
            subtitle: isJastip ? 'Sistem sedang mencari kurir untuk Anda' : 'Tugas berhasil dikirim ke kurir',
            isDone: currentStep >= 0,
            isCurrent: currentStep == 0,
            isLast: false,
          ),
          _buildStepRow(
            context,
            title: isJastip ? 'Kurir Menuju Toko' : 'Kurir Menuju Penjemputan',
            subtitle: isJastip ? 'Kurir sedang dalam perjalanan ke lokasi pembelian' : 'Kurir menuju lokasi yang ditentukan',
            isDone: currentStep >= 2,
            isCurrent: currentStep == 1,
            isLast: false,
          ),
          _buildStepRow(
            context,
            title: isJastip ? 'Sedang Dibelikan' : 'Tugas Sedang Dilakukan',
            subtitle: isJastip ? 'Kurir membeli barang pesanan Anda' : 'Kurir sedang menjalankan tugas',
            isDone: currentStep >= 3,
            isCurrent: currentStep == 2,
            isLast: false,
          ),
          _buildStepRow(
            context,
            title: isJastip ? 'Dalam Perjalanan ke Customer' : 'Dalam Perjalanan ke Tujuan',
            subtitle: isJastip ? 'Kurir menuju lokasi pengantaran' : 'Kurir menuju lokasi tujuan',
            isDone: currentStep >= 4,
            isCurrent: currentStep == 3,
            isLast: false,
          ),
          _buildStepRow(
            context,
            title: 'Pesanan Selesai',
            subtitle: isJastip ? 'Barang telah diterima' : 'Tugas telah selesai dilaksanakan',
            isDone: currentStep >= 4,
            isCurrent: currentStep == 4,
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
    final color = isDone
        ? AppColors.success
        : (isCurrent ? AppColors.primary : AppColors.border);

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
                    ? AppColors.success
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
                color: isDone ? AppColors.success : AppColors.border,
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
                    color: isDone
                        ? AppColors.success
                        : (isCurrent ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.8)),
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

  Widget _buildCourierCard(BuildContext context, bool isOngoing) {
    final hasCourier = _courierName.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasCourier
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Avatar kurir
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: _courierAvatar.isNotEmpty ? NetworkImage(_courierAvatar) : null,
            onBackgroundImageError: _courierAvatar.isNotEmpty ? (_, __) {} : null,
            child: _courierAvatar.isEmpty
                ? Icon(
                    hasCourier ? Icons.person : Icons.search,
                    size: 28,
                    color: AppColors.primary,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCourier ? _courierName : 'Mencari Kurir...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasCourier ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                if (hasCourier)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '4.9 · Kurir Terverifikasi',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Mohon tunggu, kurir sedang dicari...',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          if (hasCourier) ...[
            // Tombol telepon
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Memanggil kurir: $_courierPhone')),
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
              ),
              icon: const Icon(Icons.phone, size: 20),
            ),
            const SizedBox(width: 8),
            // Tombol chat — langsung buka room dari data order
            IconButton(
              onPressed: () {
                final room = ChatRoomModel(
                  id: _order.id,
                  senderName: _courierName.isNotEmpty ? '$_courierName · Kurir' : 'Kurir SentraGO',
                  avatarUrl: _courierAvatar,
                  lastMessage: 'Chat dengan kurir',
                  lastMessageTime: _order.createdAt,
                  isOnline: true,
                  lastSeenText: 'Kurir aktif',
                  serviceType: _order.serviceName,
                  isSupport: false,
                );
                context.push('/chat/room', extra: room);
              },
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
            ),
          ],
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
                    Text(_order.pickupAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                    Text(_order.deliveryAddress, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (_order.pickupLat != null && _order.pickupLng != null && _order.dropoffLat != null && _order.dropoffLng != null) ...[
            const SizedBox(height: 16),
            _buildRoutePreview(context),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.straighten, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Jarak Rute: ', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '${_displayKm?.toStringAsFixed(1) ?? '?'} km ($_displayEstimasi)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoutePreview(BuildContext context) {
    final pickup = LatLng(_order.pickupLat!, _order.pickupLng!);
    final dropoff = LatLng(_order.dropoffLat!, _order.dropoffLng!);
    final centerLat = (_order.pickupLat! + _order.dropoffLat!) / 2;
    final centerLng = (_order.pickupLng! + _order.dropoffLng!) / 2;

    return FutureBuilder<List<({double lat, double lng})>>(
      future: DistanceService().getRouteCoordinates(
        fromLat: _order.pickupLat!,
        fromLng: _order.pickupLng!,
        toLat: _order.dropoffLat!,
        toLng: _order.dropoffLng!,
      ),
      builder: (context, snapshot) {
        final points = snapshot.data ?? [];
        final polylinePoints = points.isNotEmpty
            ? points.map((p) => LatLng(p.lat, p.lng)).toList()
            : [pickup, dropoff];

        return Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ExcludeSemantics(
              child: FlutterMap(
                options: MapOptions(
                initialCenter: LatLng(centerLat, centerLng),
                initialZoom: 13.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.mapboxAccessToken.isNotEmpty
                      ? 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxAccessToken}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sentra.customer_app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 4.5,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pickup,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.store, color: AppColors.primary, size: 20),
                      ),
                    ),
                    Marker(
                      point: dropoff,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.error, size: 20),
                      ),
                    ),
                    if (_order.courierLat != null && _order.courierLng != null)
                      Marker(
                        point: LatLng(_order.courierLat!, _order.courierLng!),
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: const Icon(Icons.motorcycle, color: AppColors.primary, size: 24),
                        ),
                      ),
                  ],
                ),

              ],
            ),
            ),
          ),
        );
      },
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
            _order.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            _order.description,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(BuildContext context) {
    final double itemPrice = _order.danaBelanja > 0 ? _order.danaBelanja : (_order.totalAmount - _order.ongkir - _order.biayaLayanan).clamp(0.0, double.infinity).toDouble();
    final double ongkirPrice = _order.ongkir > 0 ? _order.ongkir : 10000;
    final double layananPrice = _order.biayaLayanan > 0 ? _order.biayaLayanan : 2000;

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
                'Rincian Biaya',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_order.voucherCode != null && _order.voucherCode!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Voucher: ${_order.voucherCode}',
                        style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimasi Harga Item (Dana Belanja)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(_formatCurrency(itemPrice), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jasa Pengantaran Kurir (${_displayKm?.toStringAsFixed(1) ?? '?'} km)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(_formatCurrency(ongkirPrice), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biaya Platform & Layanan', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(_formatCurrency(layananPrice), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          if (_order.voucherDiscount != null && _order.voucherDiscount! > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Diskon Voucher (${_order.voucherCode ?? 'PROMO'})', style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('-${_formatCurrency(_order.voucherDiscount!)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.success)),
              ],
            ),
          ] else if (_order.voucherCode != null && _order.voucherCode!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kode Voucher Terpasang (${_order.voucherCode})', style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
                const Text('Aktif', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.success)),
              ],
            ),
          ],
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
                _formatCurrency(_order.totalAmount),
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

  Widget _buildBottomBar(BuildContext context, bool isOngoing, bool isCompleted) {
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
                          if (_order.serviceName.contains('Jastip')) {
                            context.push('/jastip');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Memesan ulang ${_order.serviceName}...')),
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
