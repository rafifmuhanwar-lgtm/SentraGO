import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/ongkir_service.dart';
import '../../../../core/services/distance_service.dart';
import '../../../order/domain/models/order_model.dart';
import '../../../order/presentation/providers/order_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:uuid/uuid.dart';
import '../../../wallet/data/repositories/wallet_repository.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class JastipSummaryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const JastipSummaryScreen({super.key, required this.data});

  @override
  ConsumerState<JastipSummaryScreen> createState() => _JastipSummaryScreenState();
}

class _JastipSummaryScreenState extends ConsumerState<JastipSummaryScreen> {
  final _ongkirService = OngkirService();
  final _distanceService = DistanceService();

  bool _isCalculating = true;
  double _danaBelanja = 0;
  double _ongkir = 0;
  double _biayaLayanan = 0;
  double _total = 0;
  double _jarakKm = 0;
  int _estimasiMenit = 0;
  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    setState(() {
      _isCalculating = true;
    });

    // Parse dana belanja
    final budgetRaw = (widget.data['budget'] ?? '0').toString().replaceAll('.', '');
    _danaBelanja = (double.tryParse(budgetRaw) ?? 0);

    // Get coordinates
    final pickupLat = (widget.data['pickupLat'] as num?)?.toDouble();
    final pickupLng = (widget.data['pickupLng'] as num?)?.toDouble();

    // Get dropoff coordinates from address data if available
    double? dropoffLat;
    double? dropoffLng;
    final dropoffData = widget.data['dropoffData'] as Map<String, dynamic>?;

    if (dropoffData != null) {
      // Try to extract coords from address if available
      dropoffLat = (dropoffData['lat'] as num?)?.toDouble();
      dropoffLng = (dropoffData['lng'] as num?)?.toDouble();
    }

    if (pickupLat != null && pickupLng != null) {
      // Default dropoff to a central location if not set
      dropoffLat ??= -6.250000;
      dropoffLng ??= 106.850000;

      // Hitung jarak via Mapbox API
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
      } else {
        // Fallback: estimasi kasar dari garis lurus
        _jarakKm = _estimateDistance(
          pickupLat, pickupLng,
          dropoffLat, dropoffLng,
        );
        _estimasiMenit = (_jarakKm * 12).round();
      }
    } else {
      // No coordinates, use default estimate
      _jarakKm = 3.0;
      _estimasiMenit = 30;
    }

    // Hitung ongkir & biaya layanan
    _ongkir = _ongkirService.hitungOngkir(_jarakKm);
    _biayaLayanan = _ongkirService.hitungBiayaLayanan(_ongkir);
    _total = _ongkirService.hitungTotal(
      danaBelanja: _danaBelanja,
      ongkir: _ongkir,
      biayaLayanan: _biayaLayanan,
    );

    if (mounted) {
      setState(() => _isCalculating = false);
    }
  }

  double _estimateDistance(double lat1, double lng1, double lat2, double lng2) {
    // Haversine formula for rough estimation
    const R = 6371; // km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = _sinSq(dLat / 2) + math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * _sinSq(dLng / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return (R * c) * 1.3; // multiply by 1.3 for road vs straight line estimate
  }

  double _toRad(double deg) => deg * (math.pi / 180);
  double _sinSq(double x) {
    final s = math.sin(x);
    return s * s;
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
                  Text('Menghitung ongkir dan jarak...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Detail Card
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
                        Text('Detail Pesanan', style: Theme.of(context).textTheme.titleMedium),
                        const Divider(height: 24),
                        Text('Item', style: Theme.of(context).textTheme.bodySmall),
                        Text(widget.data['item'] ?? '-', style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 12),
                        Text('Catatan', style: Theme.of(context).textTheme.bodySmall),
                        Text((widget.data['notes'] as String?)?.isEmpty ?? true ? '-' : widget.data['notes'], style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location Details
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
                        Text('Lokasi & Jarak', style: Theme.of(context).textTheme.titleMedium),
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
                              child: const Icon(Icons.store_outlined, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Lokasi Pembelian', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(widget.data['pickup'] ?? 'Lokasi Penjual', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                              child: const Icon(Icons.location_on, size: 16, color: AppColors.error),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Alamat Pengantaran', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(widget.data['dropoff'] ?? 'Alamat Tujuan', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        // Distance & Time
                        Row(
                          children: [
                            const Icon(Icons.straighten, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Estimasi Jarak: ', style: Theme.of(context).textTheme.bodySmall),
                            Text('${_jarakKm.toStringAsFixed(1)} km', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('~$_estimasiMenit menit', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pricing Breakdown
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
                        _buildPricingRow(context, 'Dana Belanja', _formatCurrency(_danaBelanja)),
                        const SizedBox(height: 8),
                        _buildPricingRow(context, 'Ongkir (${_jarakKm.toStringAsFixed(1)} km × Rp2.000/km)', _formatCurrency(_ongkir)),
                        const SizedBox(height: 8),
                        _buildPricingRow(context, 'Biaya Layanan', _formatCurrency(_biayaLayanan)),
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
                              Text(
                                'Dana Diamankan oleh Escrow',
                                style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                              ),
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
          onPressed: _isCalculating ? null : () => _pay(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isCalculating
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text('Bayar Sekarang - ${_formatCurrency(_total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildPricingRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 16),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _pay(BuildContext context) async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id ?? '';
    if (userId.isEmpty) return;

    try {
      final walletRepo = ref.read(walletRepositoryProvider);

      // Check if balance is sufficient
      final balance = await walletRepo.getBalance();
      if (balance < _total) {
        if (context.mounted) {
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

      // Create order
      final orderId = 'ord_${const Uuid().v4().substring(0, 24)}';
      final newOrder = OrderModel(
        id: orderId,
        userId: userId,
        serviceName: 'Jastip SentraGO',
        title: widget.data['item'] ?? 'Barang Jastip',
        description: widget.data['notes'] ?? '',
        status: OrderStatus.ongoing,
        statusText: 'Dana Diamankan — Mencari Kurir',
        createdAt: DateTime.now(),
        totalAmount: _total,
        courierName: 'Mencari Kurir...',
        courierPhone: '',
        courierAvatar: '',
        pickupAddress: widget.data['pickup'] ?? 'Lokasi Penjual',
        deliveryAddress: widget.data['dropoff'] ?? 'Alamat Tujuan',
        danaBelanja: _danaBelanja,
        ongkir: _ongkir,
        biayaLayanan: _biayaLayanan,
        pickupLat: (widget.data['pickupLat'] as num?)?.toDouble(),
        pickupLng: (widget.data['pickupLng'] as num?)?.toDouble(),
        jarakKm: _jarakKm,
        estimasiWaktu: '~$_estimasiMenit menit',
        kebijakanLebih: 'jangan_lebih',
        orderType: 'jastip',
      );

      await ref.read(ordersProvider.notifier).addOrder(newOrder);

      // Deduct from wallet + hold in escrow (dengan breakdown)
      await walletRepo.deductAndEscrow(
        orderId: orderId,
        amount: _total,
        serviceType: 'jastip',
      );

      // Refresh wallet balance
      ref.read(walletBalanceProvider.notifier).refresh();

      if (context.mounted) {
        context.go('/jastip/success');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pembayaran: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
