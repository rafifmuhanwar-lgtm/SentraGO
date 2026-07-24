import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/order_model.dart';
import '../providers/order_provider.dart';
import '../../data/repositories/order_repository.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const OrdersScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String _selectedFilter = 'Semua'; // 'Semua', 'Jastip', 'Suruh'
  String _selectedSort = 'Terbaru'; // 'Terbaru', 'Terdekat', 'Termahal', 'Termurah'
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    // Refresh orders when screen opens
    Future.microtask(() {
      ref.read(availableOrdersProvider.notifier).refresh();
      final courier = ref.read(authStateProvider).courier;
      if (courier != null) {
        ref.read(myOrdersProvider.notifier).refresh(courier.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS tidak aktif. Aktifkan GPS untuk fitur terdekat.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak.')),
            );
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak permanen.')),
          );
        }
        return;
      } 

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  List<OrderModel> _filterAndSortOrders(List<OrderModel> orders) {
    // 1. Filter
    var result = orders.where((order) {
      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Jastip') return order.type.toLowerCase() == 'jastip';
      if (_selectedFilter == 'Suruh') return order.type.toLowerCase() == 'suruh';
      return true;
    }).toList();

    // 2. Sort
    if (_selectedSort == 'Terbaru') {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedSort == 'Termahal') {
      result.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    } else if (_selectedSort == 'Termurah') {
      result.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
    } else if (_selectedSort == 'Terdekat' && _currentPosition != null) {
      result.sort((a, b) {
        final aLat = a.pickupLat ?? 0;
        final aLng = a.pickupLng ?? 0;
        final bLat = b.pickupLat ?? 0;
        final bLng = b.pickupLng ?? 0;
        
        // Push orders without location to the bottom
        if (aLat == 0 && bLat != 0) return 1;
        if (bLat == 0 && aLat != 0) return -1;
        if (aLat == 0 && bLat == 0) return 0;
        
        final distA = Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude, 
          aLat, aLng
        );
        final distB = Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude, 
          bLat, bLng
        );
        return distA.compareTo(distB);
      });
    }

    return result;
  }

  Future<void> _refreshAvailable() async {
    await ref.read(availableOrdersProvider.notifier).refresh();
  }

  Future<void> _refreshMyOrders() async {
    final courier = ref.read(authStateProvider).courier;
    if (courier != null) {
      await ref.read(myOrdersProvider.notifier).refresh(courier.id);
    }
  }

  Future<void> _acceptOrder(OrderModel order) async {
    try {
      final authState = ref.read(authStateProvider);
      final courier = authState.courier;
      if (courier == null) return;

      await ref.read(orderRepositoryProvider).acceptOrder(
            order.id,
            courier.id,
            courier.name,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pesanan berhasil diterima!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh kedua tab
        await _refreshAvailable();
        await _refreshMyOrders();
        // Pindah otomatis ke tab "Pesanan Saya"
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menerima pesanan: $e')),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    final integer = amount.round();
    final formatted = integer.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );
    return 'Rp$formatted';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jenis Pesanan',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedFilter,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      items: ['Semua', 'Jastip', 'Suruh'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFilter = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Urutkan Berdasarkan',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedSort,
                      icon: _isLoadingLocation 
                          ? const SizedBox(
                              width: 16, height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2)
                            )
                          : const Icon(Icons.arrow_drop_down, size: 20),
                      items: ['Terbaru', 'Terdekat', 'Termahal', 'Termurah'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSort = val);
                          if (val == 'Terdekat' && _currentPosition == null) {
                            _fetchLocation();
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableOrders = ref.watch(availableOrdersProvider);
    final myOrders = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        title: const Text(
          'Daftar Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textLight,
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Tersedia (${availableOrders.length})'),
            Tab(text: 'Aktif (${myOrders.where((o) => o.status == OrderStatus.ongoing).length})'),
            Tab(text: 'Riwayat (${myOrders.where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.cancelled).length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableOrders(availableOrders),
          _buildActiveOrders(myOrders),
          _buildHistoryOrders(myOrders),
        ],
      ),
    );
  }

  Widget _buildAvailableOrders(List<OrderModel> orders) {
    final filteredOrders = _filterAndSortOrders(orders);

    return Column(
      children: [
        _buildFilterRow(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshAvailable,
            color: AppColors.primary,
            child: filteredOrders.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 80, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada pesanan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Ubah filter atau tarik ke bawah untuk refresh',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) =>
                        _buildOrderCard(filteredOrders[index], isMyOrder: false),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveOrders(List<OrderModel> orders) {
    final activeOrders = orders.where((o) => o.status == OrderStatus.ongoing).toList();
    final filteredOrders = _filterAndSortOrders(activeOrders);

    return Column(
      children: [
        _buildFilterRow(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshMyOrders,
            color: AppColors.primary,
            child: filteredOrders.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.assignment_outlined,
                                  size: 80, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada pesanan aktif',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Pesanan yang kamu terima akan muncul di sini',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) =>
                        _buildOrderCard(filteredOrders[index], isMyOrder: true),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryOrders(List<OrderModel> orders) {
    final historyOrders = orders.where((o) => o.status == OrderStatus.completed || o.status == OrderStatus.cancelled).toList();
    final filteredOrders = _filterAndSortOrders(historyOrders);

    return Column(
      children: [
        _buildFilterRow(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshMyOrders,
            color: AppColors.primary,
            child: filteredOrders.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history,
                                  size: 80, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada riwayat pesanan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Pesanan yang telah selesai akan muncul di sini',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) =>
                        _buildOrderCard(filteredOrders[index], isMyOrder: true),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order, {required bool isMyOrder}) {
    final isJastip = order.type.toLowerCase() == 'jastip';
    final typeLabel = isJastip ? 'Jastip' : 'Suruh';
    final typeColor =
        isJastip ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final typeIcon =
        isJastip ? Icons.shopping_bag_outlined : Icons.assignment_outlined;

    // Hitung jarak jika ada
    String distanceStr = '';
    if (_currentPosition != null && order.pickupLat != null && order.pickupLng != null) {
      final distMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude, 
        order.pickupLat!, order.pickupLng!
      );
      if (distMeters < 1000) {
        distanceStr = '${distMeters.round()} m';
      } else {
        distanceStr = '${(distMeters / 1000).toStringAsFixed(1)} km';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/order/detail', extra: order),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: type badge + time + distance
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 14, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (distanceStr.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text(
                            distanceStr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatTime(order.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                order.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Tarif & Budget
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Tarif: ${_formatCurrency(order.totalAmount)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isJastip) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '(Budget: ${_formatCurrency(order.danaBelanja)})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Pickup address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pickup',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          order.pickupAddress,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Delivery address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    child: const Icon(Icons.flag_outlined,
                        size: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Antar ke',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          order.deliveryAddress,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action button
              if (!isMyOrder)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _acceptOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Terima Pesanan'),
                  ),
                ),
              if (isMyOrder)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () =>
                        context.push('/order/detail', extra: order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Lihat Detail'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
