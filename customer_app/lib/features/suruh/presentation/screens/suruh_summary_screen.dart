import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/distance_service.dart';
import '../../../../core/services/ongkir_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../order/domain/models/order_model.dart';
import '../../../order/presentation/providers/order_provider.dart';
import '../../../wallet/data/repositories/wallet_repository.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class SuruhSummaryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const SuruhSummaryScreen({super.key, required this.data});

  @override
  ConsumerState<SuruhSummaryScreen> createState() => _SuruhSummaryScreenState();
}

class _SuruhSummaryScreenState extends ConsumerState<SuruhSummaryScreen> {
  final _ongkirService = OngkirService();
  final _distanceService = DistanceService();
  bool _isCalculating = true;
  bool _isSearchingDropoff = false;
  double _danaBelanja = 0;
  double _ongkir = 0;
  double _biayaLayanan = 0;
  double _total = 0;
  double _jarakKm = 0;
  int _estimasiMenit = 0;

  double? _pickupLat;
  double? _pickupLng;
  double? _dropoffLat;
  double? _dropoffLng;
  List<({double lat, double lng})> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    setState(() => _isCalculating = true);

    // Parse budget
    final budgetRaw = (widget.data['budget'] ?? '0').toString().replaceAll('.', '');
    _danaBelanja = (double.tryParse(budgetRaw) ?? 20000);

    // Get coordinates
    final pickupLat = (widget.data['pickupLat'] as num?)?.toDouble();
    final pickupLng = (widget.data['pickupLng'] as num?)?.toDouble();
    _pickupLat = pickupLat;
    _pickupLng = pickupLng;

    if (pickupLat != null && pickupLng != null) {
      // Coba cari koordinat dropoff dari alamat tujuan
      double? dropoffLat;
      double? dropoffLng;

      final dropoffAddress = widget.data['dropoff'] as String?;
      if (dropoffAddress != null && dropoffAddress.isNotEmpty) {
        setState(() => _isSearchingDropoff = true);
        final geocodeResult = await _distanceService.geocode(dropoffAddress);
        if (geocodeResult != null) {
          dropoffLat = geocodeResult.lat;
          dropoffLng = geocodeResult.lng;
        }
        setState(() => _isSearchingDropoff = false);
      }
      _dropoffLat = dropoffLat;
      _dropoffLng = dropoffLng;

      if (dropoffLat != null && dropoffLng != null) {
        final distanceResult = await _distanceService.hitungJarak(
          fromLat: pickupLat,
          fromLng: pickupLng,
          toLat: dropoffLat,
          toLng: dropoffLng,
        );

        if (!mounted) return;

        if (distanceResult != null) {
          _jarakKm = distanceResult.jarakKm;
          _estimasiMenit = distanceResult.estimasiMenit;
          _routePoints = distanceResult.routePoints;
        } else {
          _jarakKm = _estimateDistance(pickupLat, pickupLng, dropoffLat, dropoffLng);
          _estimasiMenit = (_jarakKm * 12).round();
          _routePoints = [
            (lat: pickupLat, lng: pickupLng),
            (lat: dropoffLat, lng: dropoffLng),
          ];
        }
      } else {
        // Fallback estmasi default 3 km
        _jarakKm = 3.0;
        _estimasiMenit = 30;
      }
    } else {
      _jarakKm = 3.0;
      _estimasiMenit = 30;
    }

    _ongkir = _ongkirService.hitungOngkir(_jarakKm);
    _biayaLayanan = _ongkirService.hitungBiayaLayanan(_ongkir);
    _total = _ongkirService.hitungTotal(
      danaBelanja: _danaBelanja,
      ongkir: _ongkir,
      biayaLayanan: _biayaLayanan,
    );

    if (mounted) setState(() => _isCalculating = false);
  }



  double _estimateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * (3.14159 / 180);
    final dLng = (lng2 - lng1) * (3.14159 / 180);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * 3.14159 / 180) * math.cos(lat2 * 3.14159 / 180) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return (R * c) * 1.3;
  }

  String _formatCurrency(dynamic amount) {
    final raw = amount.toString();
    final amt = (double.tryParse(raw) ?? 0).toInt();
    return 'Rp ${amt.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Ringkasan Pesanan'),
      ),
      body: _isCalculating
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Menghitung ongkir...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Task Card ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tugas', style: Theme.of(context).textTheme.titleMedium),
                        const Divider(height: 24),
                        Text(widget.data['task'] ?? '-', style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 12),
                        Text('Catatan', style: Theme.of(context).textTheme.bodySmall),
                        Text((widget.data['notes'] as String?)?.isEmpty ?? true ? '-' : widget.data['notes'], style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Location ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lokasi', style: Theme.of(context).textTheme.titleMedium),
                        const Divider(height: 24),
                        // Pickup
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Lokasi Penjemputan', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(widget.data['pickup'] ?? 'Lokasi Penjemputan', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        // Dropoff
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.flag_outlined, size: 16, color: AppColors.error),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Lokasi Tujuan', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(widget.data['dropoff'] ?? 'Lokasi Tujuan', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        // Jarak & Waktu
                        _buildMapRoutePreview(context),
                        Row(
                          children: [
                            Icon(Icons.straighten, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                            const SizedBox(width: 6),
                            _isSearchingDropoff
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text('${_jarakKm.toStringAsFixed(1)} km', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('~$_estimasiMenit menit', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Pricing ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Rincian Biaya', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildRow(context, 'Biaya Tugas', _formatCurrency(_danaBelanja)),
                        const SizedBox(height: 8),
                        _buildRow(context, 'Ongkir (${_jarakKm.toStringAsFixed(1)} km × Rp2.000/km)', _formatCurrency(_ongkir)),
                        const SizedBox(height: 8),
                        _buildRow(context, 'Biaya Layanan', _formatCurrency(_biayaLayanan)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Dibayar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(_formatCurrency(_total), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user, size: 14, color: AppColors.success),
                              SizedBox(width: 6),
                              Text('Dana Diamankan oleh Escrow', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isCalculating ? null : _pay,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Bayar Sekarang - ${_formatCurrency(_total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildMapRoutePreview(BuildContext context) {
    if (_pickupLat == null || _pickupLng == null || _dropoffLat == null || _dropoffLng == null) {
      return const SizedBox.shrink();
    }
    final pickupLatLng = LatLng(_pickupLat!, _pickupLng!);
    final dropoffLatLng = LatLng(_dropoffLat!, _dropoffLng!);
    final polylinePoints = _routePoints.isNotEmpty
        ? _routePoints.map((p) => LatLng(p.lat, p.lng)).toList()
        : [pickupLatLng, dropoffLatLng];

    final centerLat = (_pickupLat! + _dropoffLat!) / 2;
    final centerLng = (_pickupLng! + _dropoffLng!) / 2;

    return Container(
      height: 190,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            ExcludeSemantics(
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
                        point: pickupLatLng,
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
                        point: dropoffLatLng,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.flag, color: AppColors.error, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.straighten, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${_jarakKm.toStringAsFixed(1)} km (~$_estimasiMenit menit)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))),
        const SizedBox(width: 16),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _pay() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) return;

    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final balance = await walletRepo.getBalance();

      if (balance < _total) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saldo SentraPay tidak cukup. Saldo: Rp ${balance.toStringAsFixed(0)}, Dibutuhkan: Rp ${_total.toStringAsFixed(0)}'),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Top Up',
                textColor: Colors.white,
                onPressed: () => context.push('/wallet/topup'),
              ),
            ),
          );
        }
        return;
      }

      final orderId = 'ord_${const Uuid().v4().substring(0, 24)}';
      final newOrder = OrderModel(
        id: orderId,
        userId: userId,
        serviceName: 'Sentra Suruh',
        title: widget.data['task'] ?? 'Tugas Suruh',
        description: widget.data['notes'] ?? '',
        status: OrderStatus.ongoing,
        statusText: 'Dana Diamankan — Mencari Kurir',
        createdAt: DateTime.now(),
        totalAmount: _total,
        courierName: '',
        courierPhone: '',
        courierAvatar: '',
        pickupAddress: widget.data['pickup'] ?? 'Lokasi Penjemputan',
        deliveryAddress: widget.data['dropoff'] ?? 'Lokasi Tujuan',
        danaBelanja: _danaBelanja,
        ongkir: _ongkir,
        biayaLayanan: _biayaLayanan,
        pickupLat: (widget.data['pickupLat'] as num?)?.toDouble(),
        pickupLng: (widget.data['pickupLng'] as num?)?.toDouble(),
        dropoffLat: _dropoffLat,
        dropoffLng: _dropoffLng,
        jarakKm: _jarakKm,
        estimasiWaktu: '~$_estimasiMenit menit',
        kebijakanLebih: 'jangan_lebih',
        voucherCode: null,
        voucherDiscount: null,
        orderType: 'suruh',
      );

      await ref.read(ordersProvider.notifier).addOrder(newOrder);
      await walletRepo.deductAndEscrow(
        orderId: orderId,
        amount: _total,
        serviceType: 'suruh',
      );

      ref.read(walletBalanceProvider.notifier).refresh();

      if (mounted) {
        context.go('/jastip/success', extra: newOrder);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
