import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/photo_picker_tile.dart';
import '../../../profile/domain/models/address_model.dart';
import '../../../jastip/domain/models/pickup_location_data.dart';
import '../../../jastip/presentation/screens/widgets/map_picker_sheet.dart';

class SuruhFormScreen extends ConsumerStatefulWidget {
  const SuruhFormScreen({super.key});

  @override
  ConsumerState<SuruhFormScreen> createState() => _SuruhFormScreenState();
}

class _SuruhFormScreenState extends ConsumerState<SuruhFormScreen> {
  final _taskController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();

  PickupLocationData? _pickupLocation;
  String? _taskImageUrl;
  String? _dropoffAddress;
  AddressModel? _dropoffAddressData;

  @override
  void dispose() {
    _taskController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_taskController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas harus diisi')),
      );
      return;
    }
    if (_pickupLocation == null || _dropoffAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi Penjemputan dan Tujuan harus dipilih')),
      );
      return;
    }

    final budgetRaw = _budgetController.text.replaceAll(RegExp(r'[^0-9]'), '');

    context.push('/suruh/summary', extra: {
      'task': _taskController.text,
      'budget': budgetRaw.isEmpty ? '20000' : budgetRaw,
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
      builder: (context) => const MapPickerSheet(title: 'Lokasi Penjemputan'),
    );

    if (result != null) {
      setState(() => _pickupLocation = result);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Suruh Kurir'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.motorcycle_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suruh Kurir',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kurir siap bantuin tugas kamu',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Task Input ──
            Text('Apa yang perlu dilakukan?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Ambil paket di JNE, anter dokumen ke kantor...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ── Pickup Location (Map Pin) ──
            Text('Lokasi Penjemputan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildLocationTile(
              value: _pickupLocation?.address,
              hint: 'Tentukan di peta',
              icon: Icons.location_on_outlined,
              onTap: _pickPickupLocation,
            ),
            const SizedBox(height: 24),

            // ── Destination (Saved Addresses) ──
            Text('Lokasi Tujuan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildLocationTile(
              value: _dropoffAddress,
              hint: 'Pilih alamat tujuan',
              icon: Icons.flag_outlined,
              onTap: _pickDropoffAddress,
            ),
            const SizedBox(height: 24),

            // ── Budget ──
            Text('Estimasi Budget (Maksimal)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '20.000',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Biaya akan disesuaikan dengan jarak dan tugas.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),

            // ── Notes ──
            Text('Catatan Tambahan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Contoh: titipkan ke resepsionis, jam 5 sore...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // ── Photo (Opsional) ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 12, left: 16),
                    child: Row(
                      children: [
                        Text('Foto Tugas (Opsional)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  PhotoPickerTile(
                    imageUrl: _taskImageUrl,
                    hintText: 'Ambil foto tugas atau lokasi',
                    onImagePicked: (path) {
                      setState(() => _taskImageUrl = path);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ── Submit Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Lanjut ke Rincian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile({
    String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          value ?? hint,
          style: TextStyle(
            fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
            color: value != null ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
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
