import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../jastip/domain/models/pickup_location_data.dart';
import '../../../../jastip/presentation/screens/widgets/map_picker_sheet.dart';
import '../../../domain/models/address_model.dart';
import '../../providers/address_provider.dart';

class AddressFormModal extends ConsumerStatefulWidget {
  final AddressModel? initialAddress;

  const AddressFormModal({super.key, this.initialAddress});

  static Future<void> show(BuildContext context, {AddressModel? address}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormModal(initialAddress: address),
    );
  }

  @override
  ConsumerState<AddressFormModal> createState() => _AddressFormModalState();
}

class _AddressFormModalState extends ConsumerState<AddressFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _detailsController;
  late TextEditingController _customLabelController;
  late String _selectedLabel;
  late bool _isPrimary;
  bool _isLoading = false;

  final List<String> _labelOptions = ['Rumah', 'Kantor', 'Apartemen', 'Lainnya'];

  @override
  void initState() {
    super.initState();
    final addr = widget.initialAddress;
    _nameController = TextEditingController(text: addr?.recipientName ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _addressController = TextEditingController(text: addr?.fullAddress ?? '');
    _detailsController = TextEditingController(text: addr?.details ?? '');
    _selectedLabel = addr?.label ?? 'Rumah';
    if (!_labelOptions.sublist(0, 3).contains(_selectedLabel)) {
      final customText = (_selectedLabel == 'Lainnya' || _selectedLabel.isEmpty) ? '' : _selectedLabel;
      _customLabelController = TextEditingController(text: customText);
      _selectedLabel = 'Lainnya';
    } else {
      _customLabelController = TextEditingController();
    }
    _isPrimary = addr?.isPrimary ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _detailsController.dispose();
    _customLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickFromMap() async {
    final result = await showModalBottomSheet<PickupLocationData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const MapPickerSheet(
        title: 'Pilih Titik Alamat dari Peta',
      ),
    );

    if (result != null) {
      setState(() {
        _addressController.text = result.address;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLabel == 'Lainnya' && _customLabelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tulis label alamat (misal: Kos, Toko)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final finalLabel = _selectedLabel == 'Lainnya'
        ? _customLabelController.text.trim()
        : _selectedLabel;

    setState(() {
      _isLoading = true;
    });

    final notifier = ref.read(savedAddressesProvider.notifier);
    final newAddr = AddressModel(
      id: widget.initialAddress?.id ?? '',
      label: finalLabel,
      recipientName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      fullAddress: _addressController.text.trim(),
      details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
      isPrimary: _isPrimary,
    );

    if (widget.initialAddress != null) {
      await notifier.updateAddress(newAddr);
    } else {
      await notifier.addAddress(newAddr);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.initialAddress != null
                ? 'Alamat berhasil diperbarui!'
                : 'Alamat baru berhasil ditambahkan!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.initialAddress != null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
        child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEditing ? 'Edit Alamat' : 'Tambah Alamat Baru',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),

              // ── Label Alamat (Choice Chips) ──
              Text(
                'Label Alamat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _labelOptions.map((label) {
                  final isSelected = _selectedLabel == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedLabel = label);
                      }
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.12),
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedLabel == 'Lainnya') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customLabelController,
                  decoration: const InputDecoration(
                    hintText: 'Tulis nama label alamat (contoh: Kos, Toko, Rumah Nenek)',
                    prefixIcon: Icon(Icons.label_outline, color: AppColors.textSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ── Nama Penerima ──
              Row(
                children: [
                  Text(
                    'Nama Penerima',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Budi Santoso',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '⚠️ Nama penerima wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Nomor Telepon ──
              Row(
                children: [
                  Text(
                    'Nomor Telepon / WhatsApp',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Contoh: 081234567890',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '⚠️ Nomor telepon/WhatsApp wajib diisi';
                  }
                  if (value.trim().length < 8) {
                    return '⚠️ Nomor telepon minimal 8 angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Alamat Lengkap ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Alamat Lengkap',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _pickFromMap,
                    icon: const Icon(Icons.map_outlined, size: 18, color: AppColors.primary),
                    label: const Text(
                      'Pilih dari Peta',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Contoh: Jl. Ahmad Yani No. 12, Bekasi Barat, Kota Bekasi...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    tooltip: 'Pilih dari Peta',
                    onPressed: _pickFromMap,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '⚠️ Alamat lengkap wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Catatan Tambahan ──
              Text(
                'Catatan Tambahan (Opsi)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Pagar hitam depan pos satpam, ketuk pintu',
                ),
              ),
              const SizedBox(height: 16),

              // ── Switch Alamat Utama ──
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SwitchListTile(
                  value: _isPrimary,
                  onChanged: (val) {
                    setState(() => _isPrimary = val);
                  },
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    'Atur sebagai Alamat Utama',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: Text(
                    'Alamat ini akan otomatis dipilih saat membuat pesanan.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Tombol Simpan ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEditing ? 'Simpan Perubahan' : 'Simpan Alamat',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ));
  }
}
