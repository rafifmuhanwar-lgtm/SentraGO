import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/photo_picker_tile.dart';
import '../../../../core/widgets/address_search_field.dart';
import '../../../profile/domain/models/address_model.dart';
import '../../domain/models/pickup_location_data.dart';
import 'widgets/map_picker_sheet.dart';

class JastipFormScreen extends StatefulWidget {
  const JastipFormScreen({super.key});

  @override
  State<JastipFormScreen> createState() => _JastipFormScreenState();
}

class _JastipFormScreenState extends State<JastipFormScreen> {
  final _itemController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();

  PickupLocationData? _pickupLocation;
  String? _itemImageUrl;
  String? _dropoffAddress;
  AddressModel? _dropoffAddressData;

  @override
  void dispose() {
    _itemController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    debugPrint('===== SUBMIT JASTIP =====');
    debugPrint('item: ${_itemController.text}');
    debugPrint('pickupLocation: ${_pickupLocation?.address}');
    debugPrint('dropoffAddress: $_dropoffAddress');
    debugPrint('budget: ${_budgetController.text}');

    if (_itemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detail barang harus diisi')),
      );
      return;
    }
    if (_pickupLocation == null || _dropoffAddress == null) {
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
      'pickup': _pickupLocation!.address,
      'pickupLat': _pickupLocation!.lat,
      'pickupLng': _pickupLocation!.lng,
      'dropoff': _dropoffAddress,
      'dropoffData': _dropoffAddressData?.toJson(),
    });
  }

  Future<void> _pickPickupLocation() async {
    final result = await showModalBottomSheet<PickupLocationData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MapPickerSheet(),
    );

    if (result != null) {
      setState(() {
        _pickupLocation = result;
      });
    }
  }

  Future<void> _pickDropoffAddress() async {
    final result = await context.push<AddressModel>('/jastip/delivery-address');

    if (result != null) {
      setState(() {
        _dropoffAddress = result.fullAddress;
        _dropoffAddressData = result;
      });
    }
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
          PhotoPickerTile(
            imageUrl: _itemImageUrl,
            hintText: 'Tambah Foto Barang',
            onImagePicked: (path) {
              setState(() => _itemImageUrl = path);
            },
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
          // Location Search Fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cari Lokasi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),

                // Pickup Location - Search
                AddressSearchField(
                  label: 'Lokasi Pembelian',
                  hint: _pickupLocation?.address ?? 'Cari toko atau alamat...',
                  prefixIcon: Icons.store_outlined,
                  proximityLat: -6.2,
                  proximityLng: 106.8,
                  onSelected: (result) {
                    setState(() {
                      _pickupLocation = PickupLocationData(
                        address: result.fullAddress,
                        lat: result.lat,
                        lng: result.lng,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Or use map picker button
                if (_pickupLocation == null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _pickPickupLocation,
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Pilih di Peta', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ),

                if (_pickupLocation != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pickupLocation!.address,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          onPressed: _pickPickupLocation,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 24, color: AppColors.border),

                // Dropoff Location - Search
                AddressSearchField(
                  label: 'Alamat Pengantaran',
                  hint: _dropoffAddress ?? 'Cari alamat tujuan...',
                  prefixIcon: Icons.location_on_outlined,
                  proximityLat: -6.2,
                  proximityLng: 106.8,
                  onSelected: (result) {
                    setState(() {
                      _dropoffAddress = result.fullAddress;
                      _dropoffAddressData = AddressModel(
                        id: '',
                        label: result.placeName,
                        recipientName: '',
                        phone: '',
                        fullAddress: result.fullAddress,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),

                if (_dropoffAddress != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dropoffAddress!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          onPressed: _pickDropoffAddress,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: AppColors.success,
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
                    maxLines: 2,
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

// ─── Currency Input Formatter ───

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


// ─── End of file ───
