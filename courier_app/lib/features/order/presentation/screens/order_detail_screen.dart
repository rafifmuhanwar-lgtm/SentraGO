import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
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

      if (statusText == 'Pesanan Selesai') {
        await ref.read(orderRepositoryProvider).updateOrderStatus(
              widget.order.id,
              'completed',
              statusText: 'Pesanan Selesai',
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan telah selesai!')),
        );
      }
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
            else ...[
              _buildStatusUpdateSection(),
              const SizedBox(height: 16),
              if (widget.order.type == 'jastip')
                _buildUploadStrukButton(),
            ],

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
        clipBehavior: Clip.antiAlias,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined,
                  size: 56,
                  color: AppColors.textSecondary),
              SizedBox(height: 8),
              Text(
                'Lokasi tidak tersedia',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Center map between pickup and dropoff
    final lat = hasPickupCoords
        ? (widget.order.pickupLat! +
                (hasDropoffCoords ? widget.order.dropoffLat! : widget.order.pickupLat!)) /
            2
        : widget.order.dropoffLat!;
    final lng = hasPickupCoords
        ? (widget.order.pickupLng! +
                (hasDropoffCoords ? widget.order.dropoffLng! : widget.order.pickupLng!)) /
            2
        : widget.order.dropoffLng!;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
                additionalOptions: const {
                  'accessToken': AppConfig.mapboxAccessToken,
                },
                userAgentPackageName: 'com.sentrago.courier_app',
              ),
              MarkerLayer(
                markers: [
                  if (hasPickupCoords)
                    Marker(
                      point: LatLng(widget.order.pickupLat!, widget.order.pickupLng!),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront,
                              color: AppColors.primary, size: 32),
                          Text('Pickup',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  if (hasDropoffCoords)
                    Marker(
                      point:
                          LatLng(widget.order.dropoffLat!, widget.order.dropoffLng!),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on,
                              color: AppColors.error, size: 32),
                          Text('Tujuan',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Legend overlay
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.my_location, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  const Text('Pickup',
                      style: TextStyle(fontSize: 10)),
                  if (hasDropoffCoords) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.location_on,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    const Text('Tujuan',
                        style: TextStyle(fontSize: 10)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildStatusUpdateSection() {
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
              Icon(Icons.update, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Update Status',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._statusOptions.map((option) {
            final isSelected = _currentCourierStatus == option.label;
            final isDisabled = _isUpdating;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isDisabled
                      ? null
                      : () => _updateStatus(option.label),
                  icon: isSelected
                      ? const Icon(Icons.check_circle, size: 20, color: AppColors.success)
                      : Icon(option.icon, size: 20),
                  label: Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isSelected ? AppColors.success : AppColors.textPrimary,
                    side: BorderSide(
                      color: isSelected ? AppColors.success : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    backgroundColor: isSelected
                        ? AppColors.success.withValues(alpha: 0.05)
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUploadStrukButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          context.push('/order/receipt', extra: widget.order);
        },
        icon: const Icon(Icons.receipt),
        label: const Text(
          'Upload Struk',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warning,
          foregroundColor: AppColors.textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur chat akan segera tersedia')),
          );
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
