import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class JastipFormScreen extends StatefulWidget {
  const JastipFormScreen({super.key});

  @override
  State<JastipFormScreen> createState() => _JastipFormScreenState();
}

class _JastipFormScreenState extends State<JastipFormScreen> {
  final _itemController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _pickupAddress;
  String? _dropoffAddress;

  @override
  void dispose() {
    _itemController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_itemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detail barang harus diisi')),
      );
      return;
    }
    if (_pickupAddress == null || _dropoffAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi Pembelian dan Pengiriman harus dipilih')),
      );
      return;
    }

    final budgetRaw = _budgetController.text.replaceAll('.', '');

    context.push('/jastip/summary', extra: {
      'item': _itemController.text,
      'budget': budgetRaw,
      'notes': _notesController.text,
      'pickup': _pickupAddress,
      'dropoff': _dropoffAddress,
    });
  }

  void _showMapPicker(String title, bool isPickup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MapPickerSheet(
        title: title,
        onSelected: (address) {
          setState(() {
            if (isPickup) {
              _pickupAddress = address;
            } else {
              _dropoffAddress = address;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Titip Belanja',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Barang yang mau dititip'),
                  const SizedBox(height: 12),
                  _buildItemInput(),
                  const SizedBox(height: 28),
                  
                  _buildSectionTitle('Lokasi Pembelian & Pengiriman'),
                  const SizedBox(height: 12),
                  _buildLocationCard(),
                  const SizedBox(height: 28),
                  
                  _buildSectionTitle('Estimasi Harga Barang'),
                  const SizedBox(height: 8),
                  const Text(
                    'Jika harga melebihi batas, kurir akan konfirmasi ke kamu.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _buildBudgetInput(),
                  const SizedBox(height: 28),
                  
                  _buildSectionTitle('Catatan Tambahan (Opsional)'),
                  const SizedBox(height: 12),
                  _buildNotesInput(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildItemInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _itemController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Cth: Nasi Goreng Spesial 2 bungkus...',
                hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                border: InputBorder.none,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur kamera akan segera hadir')),
              );
            },
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tambah Foto Barang',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Simulated Map Preview Background
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(-6.200000, 106.816666),
                      zoom: 14.0,
                    ),
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                    scrollGesturesEnabled: false,
                    zoomGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('Pilih Rute di Peta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Location Selectors
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 4),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 44,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    const Icon(Icons.location_on, color: AppColors.error, size: 18),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildLocationTile(
                        title: 'Lokasi Pembelian',
                        value: _pickupAddress,
                        hint: 'Tentukan lokasi toko/warung',
                        onTap: () => _showMapPicker('Lokasi Pembelian', true),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: AppColors.border),
                      ),
                      _buildLocationTile(
                        title: 'Alamat Pengantaran',
                        value: _dropoffAddress,
                        hint: 'Tentukan alamat tujuan',
                        onTap: () => _showMapPicker('Alamat Pengantaran', false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile({
    required String title,
    String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                      color: value != null ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Rp',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [_CurrencyInputFormatter()],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 3,
        minLines: 2,
        decoration: InputDecoration(
          hintText: 'Cth: Tolong belikan yang bungkusnya warna biru ya mas...',
          hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Lanjut ke Rincian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Currency Formatter
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    } else if (newValue.text.compareTo(oldValue.text) != 0) {
      int selectionIndexFromTheRight = newValue.text.length - newValue.selection.end;
      final f = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (f.isEmpty) return newValue.copyWith(text: '');

      int num = int.parse(f);
      String newString = num.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');

      return TextEditingValue(
        text: newString,
        selection: TextSelection.collapsed(offset: newString.length - selectionIndexFromTheRight),
      );
    }
    return newValue;
  }
}

// Custom Currency Formatter mock map picking
class _MapPickerSheet extends StatefulWidget {
  final String title;
  final Function(String) onSelected;

  const _MapPickerSheet({required this.title, required this.onSelected});

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  bool _isMoving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari alamat atau nama tempat...',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _searchController.clear(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Map Area (Mock)
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-6.200000, 106.816666),
                    zoom: 15.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onCameraMoveStarted: () {
                    if (!_isMoving) {
                      setState(() => _isMoving = true);
                    }
                  },
                  onCameraIdle: () {
                    if (_isMoving) {
                      setState(() => _isMoving = false);
                    }
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: _isMoving ? 20 : 0),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Geser peta untuk menentukan titik', style: TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    ],
                  ),
                ),
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: AppColors.primary),
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(const LatLng(-6.200000, 106.816666), 15.0),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
          // Confirm Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lokasi terpilih:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  _searchController.text.isNotEmpty ? _searchController.text : 'Jl. Merdeka Raya No. 45, Jakarta Pusat',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final addr = _searchController.text.isNotEmpty ? _searchController.text : 'Jl. Merdeka Raya No. 45, Jakarta Pusat';
                      widget.onSelected(addr);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Konfirmasi Lokasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
