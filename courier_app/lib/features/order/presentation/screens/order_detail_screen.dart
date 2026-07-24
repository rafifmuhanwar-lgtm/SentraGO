import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/distance_service.dart';
import '../../domain/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/domain/models/chat_room_model.dart';
import 'delivery_proof_screen.dart';
import '../../../../core/services/database_service.dart';
import '../providers/order_provider.dart';
import '../../../profile/presentation/providers/courier_earnings_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  String? _currentCourierStatus;
  bool _isAccepting = false;
  bool _isUpdating = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _currentCourierStatus = widget.order.statusText;
    if (widget.order.status == OrderStatus.ongoing && widget.order.courierName.isNotEmpty) {
      _startTracking();
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update per 10 meter
      ),
    ).listen((Position position) {
      ref.read(orderRepositoryProvider).updateCourierLocation(
        widget.order.id, 
        position.latitude, 
        position.longitude,
      );
    });
  }

  Future<void> _openGoogleMaps() async {
    final isHeadingToPickup = _currentCourierStatus == 'Menuju Lokasi';
    final lat = isHeadingToPickup ? widget.order.pickupLat : widget.order.dropoffLat;
    final lng = isHeadingToPickup ? widget.order.pickupLng : widget.order.dropoffLng;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koordinat lokasi tidak tersedia')));
      return;
    }
    
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak bisa membuka aplikasi Maps')));
      }
    }
  }

  bool get _isAccepted => widget.order.courierName.isNotEmpty;

  List<_StatusOption> get _statusOptions => const [
        _StatusOption('Menuju Lokasi', Icons.navigation),
        _StatusOption('Sampai di Lokasi', Icons.location_on),
        _StatusOption('Barang Dibeli / Tugas Selesai', Icons.shopping_bag),
        _StatusOption('Dalam Perjalanan ke Tujuan', Icons.delivery_dining),
        _StatusOption('Pesanan Selesai', Icons.check_circle),
      ];

  Future<void> _acceptOrder() async {
    final authState = ref.read(authStateProvider);
    final courier = authState.courier;

    if (courier == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    setState(() => _isAccepting = true);

    try {
      await ref.read(orderRepositoryProvider).acceptOrder(
            widget.order.id,
            courier.id,
            courier.name,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil diterima!')),
      );
      setState(() => _currentCourierStatus = 'Menuju Lokasi');
      _startTracking();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menerima pesanan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  Future<void> _updateStatus(String statusText) async {
    if (statusText == 'Barang Dibeli / Tugas Selesai' && widget.order.type == 'jastip') {
      final success = await context.push<bool>('/order/receipt', extra: widget.order);
      if (success == true) {
        setState(() => _currentCourierStatus = statusText);
      }
      return;
    }

    if (statusText == 'Pesanan Selesai') {
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => DeliveryProofScreen(order: widget.order),
        ),
      );
      if (success == true) {
        final courier = ref.read(authStateProvider).courier;
        if (courier != null) {
          ref.read(myOrdersProvider.notifier).refresh(courier.id);
        }
        ref.invalidate(courierEarningsProvider);
        
        if (mounted) {
          context.pop();
        }
      }
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(
            widget.order.id,
            'ongoing',
            statusText: statusText,
          );
      if (!mounted) return;
      setState(() => _currentCourierStatus = statusText);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status: $statusText')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update status: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detail Pesanan',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order type badge & title
            _buildOrderHeader(),
            const SizedBox(height: 20),

            // Map preview
            _buildMapPreview(),
            const SizedBox(height: 12),
            
            // Navigation Button
            if (_isAccepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openGoogleMaps,
                  icon: const Icon(Icons.navigation, size: 18),
                  label: Text('Buka Navigasi ke ${_currentCourierStatus == 'Menuju Lokasi' ? 'Pickup' : 'Tujuan'}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5), // Google Maps Blue
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Pickup & delivery addresses
            _buildAddressCard(),
            const SizedBox(height: 20),

            // Order description
            _buildDescriptionCard(),
            const SizedBox(height: 20),

            // Pricing
            _buildPricingCard(),
            const SizedBox(height: 20),

            // Action buttons
            if (!_isAccepted)
              _buildAcceptButton()
            else
              _buildStatusUpdateSection(),

            const SizedBox(height: 16),
            _buildChatButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.order.type == 'jastip' ? 'Jastip' : 'Suruh',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.order.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    final hasPickupCoords =
        widget.order.pickupLat != null && widget.order.pickupLng != null;
    final hasDropoffCoords =
        widget.order.dropoffLat != null && widget.order.dropoffLng != null;

    if (!hasPickupCoords && !hasDropoffCoords) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 56, color: AppColors.textSecondary),
              SizedBox(height: 8),
              Text('Lokasi tidak tersedia',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // Ambil vehicleType dari kurir yang sedang login
    final authState = ref.watch(authStateProvider);
    final vehicleType = authState.courier?.vehicleType;

    final double centerLat;
    final double centerLng;
    if (hasPickupCoords && hasDropoffCoords) {
      centerLat = (widget.order.pickupLat! + widget.order.dropoffLat!) / 2;
      centerLng = (widget.order.pickupLng! + widget.order.dropoffLng!) / 2;
    } else if (hasPickupCoords) {
      centerLat = widget.order.pickupLat!;
      centerLng = widget.order.pickupLng!;
    } else {
      centerLat = widget.order.dropoffLat!;
      centerLng = widget.order.dropoffLng!;
    }

    return _VehicleRouteMap(
      order: widget.order,
      vehicleType: vehicleType,
      centerLat: centerLat,
      centerLng: centerLng,
      hasPickup: hasPickupCoords,
      hasDropoff: hasDropoffCoords,
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alamat Pickup',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.order.pickupAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 6, bottom: 6),
            child: Container(
              width: 2,
              height: 20,
              color: AppColors.border,
            ),
          ),
          // Delivery
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alamat Tujuan',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.order.deliveryAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Deskripsi Pesanan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.order.description.isEmpty
                ? 'Tidak ada deskripsi'
                : widget.order.description,
            style: TextStyle(
              fontSize: 14,
              color: widget.order.description.isEmpty
                  ? AppColors.textSecondary.withValues(alpha: 0.6)
                  : AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Rincian Biaya',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _priceRow('Dana Belanja', widget.order.danaBelanja),
          const SizedBox(height: 8),
          _priceRow('Ongkir', widget.order.ongkir),
          const SizedBox(height: 8),
          _priceRow('Biaya Layanan', widget.order.biayaLayanan),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _formatCurrency(widget.order.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isAccepting ? null : _acceptOrder,
        icon: _isAccepting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.textLight,
                ),
              )
            : const Icon(Icons.handshake_outlined),
        label: Text(
          _isAccepting ? 'Memproses...' : 'Terima Pesanan',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  int get _currentStatusIndex {
    if (_currentCourierStatus == null || _currentCourierStatus!.isEmpty) return -1;
    return _statusOptions.indexWhere((opt) => opt.label == _currentCourierStatus);
  }

  Widget _buildStatusUpdateSection() {
    final currentIndex = _currentStatusIndex;
    final nextIndex = currentIndex + 1;
    
    // Jika pesanan sudah selesai
    if (widget.order.status == OrderStatus.completed || currentIndex == _statusOptions.length - 1) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            SizedBox(width: 8),
            Text(
              'Pesanan Telah Selesai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    final nextOption = _statusOptions[nextIndex];
    final isDisabled = _isUpdating;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.update, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Langkah Selanjutnya',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (_currentCourierStatus != null && _currentCourierStatus!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Status saat ini: $_currentCourierStatus',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isDisabled ? null : () => _updateStatus(nextOption.label),
              icon: isDisabled 
                ? const SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                  )
                : Icon(nextOption.icon),
              label: Text(
                isDisabled 
                  ? 'Mengupdate...' 
                  : 'Update: ${nextOption.label == 'Barang Dibeli / Tugas Selesai' ? (widget.order.type == 'jastip' ? 'Barang Dibeli' : 'Tugas Selesai') : nextOption.label}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: nextIndex == _statusOptions.length - 1 
                    ? AppColors.success 
                    : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildChatButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          String customerName = widget.order.userId.isNotEmpty
              ? 'Customer #${widget.order.userId.substring(0, 6).toUpperCase()}'
              : 'Customer';
          String avatarUrl = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';

          // Ambil data pelanggan asli dari database
          if (widget.order.userId.isNotEmpty) {
            // Tampilkan loading dialog sebentar
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(child: CircularProgressIndicator()),
            );
            
            try {
              final userDoc = await ref.read(databaseServiceProvider).getUser(widget.order.userId);
              if (userDoc != null) {
                if (userDoc['name'] != null && userDoc['name'].toString().isNotEmpty) {
                  customerName = userDoc['name'];
                }
                if (userDoc['photoUrl'] != null && userDoc['photoUrl'].toString().isNotEmpty) {
                  avatarUrl = userDoc['photoUrl'];
                } else if (userDoc['avatarUrl'] != null && userDoc['avatarUrl'].toString().isNotEmpty) {
                  avatarUrl = userDoc['avatarUrl'];
                }
              }
            } catch (e) {
              debugPrint('Gagal fetch data customer: $e');
            }
            
            if (!mounted) return;
            Navigator.of(context).pop(); // tutup loading dialog
          }

          if (!mounted) return;
              
          final room = ChatRoomModel(
            id: widget.order.id,
            customerName: customerName,
            avatarUrl: avatarUrl,
            lastMessage: 'Chat dengan customer',
            lastMessageTime: widget.order.createdAt,
            isOnline: true,
            orderType: widget.order.type,
            orderTitle: widget.order.title,
          );
          context.push('/chat/room', extra: room);
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text(
          'Chat dengan Customer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
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

class _StatusOption {
  final String label;
  final IconData icon;

  const _StatusOption(this.label, this.icon);
}

// ── Vehicle-aware route map ───────────────────────────────────────────────────

class _VehicleRouteMap extends StatefulWidget {
  final OrderModel order;
  final String? vehicleType;
  final double centerLat;
  final double centerLng;
  final bool hasPickup;
  final bool hasDropoff;

  const _VehicleRouteMap({
    required this.order,
    required this.vehicleType,
    required this.centerLat,
    required this.centerLng,
    required this.hasPickup,
    required this.hasDropoff,
  });

  @override
  State<_VehicleRouteMap> createState() => _VehicleRouteMapState();
}

class _VehicleRouteMapState extends State<_VehicleRouteMap> {
  List<LatLng> _polylinePoints = [];
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  @override
  void didUpdateWidget(_VehicleRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicleType != widget.vehicleType) {
      _fetchRoute();
    }
  }

  Future<void> _fetchRoute() async {
    if (!widget.hasPickup || !widget.hasDropoff) {
      setState(() => _isLoadingRoute = false);
      return;
    }
    try {
      final svc = DistanceService();
      final points = await svc.getRouteCoordinates(
        fromLat: widget.order.pickupLat!,
        fromLng: widget.order.pickupLng!,
        toLat: widget.order.dropoffLat!,
        toLng: widget.order.dropoffLng!,
        vehicleType: widget.vehicleType,
      );
      if (mounted) {
        setState(() {
          _polylinePoints =
              points.map((p) => LatLng(p.lat, p.lng)).toList();
          _isLoadingRoute = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  /// Warna polyline sesuai tipe kendaraan
  Color get _routeColor {
    final type = widget.vehicleType?.toLowerCase().trim() ?? '';
    if (type == 'motor' || type == 'motorcycle' || type == 'sepeda motor') {
      return const Color(0xFFFF6B00); // oranye untuk motor
    } else if (type == 'sepeda' || type == 'bicycle' || type == 'bike') {
      return const Color(0xFF00AA44); // hijau untuk sepeda
    } else if (type == 'jalan kaki' || type == 'walking') {
      return const Color(0xFF8B5CF6); // ungu untuk jalan kaki
    }
    return AppColors.primary; // biru default untuk mobil
  }

  /// Ikon kendaraan
  IconData get _vehicleIcon {
    final type = widget.vehicleType?.toLowerCase().trim() ?? '';
    if (type == 'motor' || type == 'motorcycle' || type == 'sepeda motor') {
      return Icons.two_wheeler;
    } else if (type == 'sepeda' || type == 'bicycle' || type == 'bike') {
      return Icons.directions_bike;
    } else if (type == 'jalan kaki' || type == 'walking') {
      return Icons.directions_walk;
    }
    return Icons.directions_car;
  }

  /// Label rute
  String get _routeLabel {
    final type = widget.vehicleType?.toLowerCase().trim() ?? '';
    if (type == 'motor' || type == 'motorcycle' || type == 'sepeda motor') {
      return 'Rute Motor · Tanpa Tol';
    } else if (type == 'sepeda' || type == 'bicycle' || type == 'bike') {
      return 'Rute Sepeda';
    } else if (type == 'jalan kaki' || type == 'walking') {
      return 'Rute Jalan Kaki';
    }
    if (type.isNotEmpty) {
      return 'Rute ${_capitalize(type)}';
    }
    return 'Rute Normal';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final pickup = widget.hasPickup
        ? LatLng(widget.order.pickupLat!, widget.order.pickupLng!)
        : null;
    final dropoff = widget.hasDropoff
        ? LatLng(widget.order.dropoffLat!, widget.order.dropoffLng!)
        : null;

    final fallbackPolyline = [
      if (pickup != null) pickup,
      if (dropoff != null) dropoff,
    ];

    final polylinePoints =
        _polylinePoints.isNotEmpty ? _polylinePoints : fallbackPolyline;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(widget.centerLat, widget.centerLng),
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: AppConfig.mapboxAccessToken.isNotEmpty
                    ? 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${AppConfig.mapboxAccessToken}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sentrago.courier_app',
              ),
              if (polylinePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 5.0,
                      color: _routeColor,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (pickup != null)
                    Marker(
                      point: pickup,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4)
                          ],
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const Icon(Icons.storefront,
                            color: AppColors.primary, size: 22),
                      ),
                    ),
                  if (dropoff != null)
                    Marker(
                      point: dropoff,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4)
                          ],
                          border: Border.all(color: AppColors.error, width: 2),
                        ),
                        child: const Icon(Icons.location_on,
                            color: AppColors.error, size: 22),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Badge kendaraan — pojok kiri bawah
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _routeColor.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_vehicleIcon, color: Colors.white, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    _routeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading shimmer indicator
          if (_isLoadingRoute)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _routeColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Memuat rute...',
                        style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            )
          else ...[
            // Legend badge — pojok kanan atas
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront, size: 13, color: AppColors.primary),
                    const SizedBox(width: 3),
                    const Text('Pickup',
                        style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 8),
                    Icon(Icons.location_on, size: 13, color: AppColors.error),
                    const SizedBox(width: 3),
                    const Text('Tujuan',
                        style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

