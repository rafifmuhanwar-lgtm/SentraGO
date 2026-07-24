import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/database_service.dart';
import '../providers/auth_provider.dart';
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _plateController;
  String? _vehicleType;
  String? _selectedArea;
  bool _isSaving = false;
  XFile? _newProfileImage;

  static const _vehicleTypes = ['Motor', 'Mobil', 'Sepeda'];
  static const _areaOptions = [
    'Jakarta Pusat',
    'Jakarta Utara',
    'Jakarta Barat',
    'Jakarta Selatan',
    'Jakarta Timur',
    'Tangerang',
    'Kota Bekasi',
    'Kabupaten Bekasi',
    'Depok',
    'Bogor',
  ];

  @override
  void initState() {
    super.initState();
    final courier = ref.read(authStateProvider).courier;
    _nameController = TextEditingController(text: courier?.name ?? '');
    _phoneController = TextEditingController(text: courier?.phone ?? '');
    _plateController = TextEditingController(text: courier?.vehiclePlate ?? '');
    _vehicleType = courier?.vehicleType;
    _selectedArea = courier?.selectedArea;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final current = ref.read(authStateProvider).courier;
      if (current == null) return;

      String? uploadedPhotoUrl;
      if (_newProfileImage != null) {
        uploadedPhotoUrl = await ref.read(databaseServiceProvider).uploadProfileImage(
          _newProfileImage!.path,
          _newProfileImage!.name,
        );
      }

      final updated = current.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        vehicleType: _vehicleType,
        vehiclePlate: _plateController.text.trim().toUpperCase(),
        selectedArea: _selectedArea,
        photoUrl: uploadedPhotoUrl ?? current.photoUrl,
      );

      await ref.read(authStateProvider.notifier).updateCourierProfile(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courier = ref.watch(authStateProvider).courier;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar / Photo
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            _newProfileImage = image;
                          });
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundImage: _newProfileImage != null
                                ? FileImage(File(_newProfileImage!.path)) as ImageProvider
                                : (courier?.photoUrl != null ? NetworkImage(courier!.photoUrl!) : null),
                            child: (_newProfileImage == null && courier?.photoUrl == null)
                                ? Text(
                                    (courier?.name.isNotEmpty == true
                                            ? courier!.name[0]
                                            : 'K')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      courier?.email ?? '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Nama
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Nomor Telepon
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  label: 'Nomor Telepon',
                  icon: Icons.phone_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nomor telepon tidak boleh kosong';
                  if (!v.trim().startsWith('08')) return 'Nomor harus dimulai dengan 08';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipe Kendaraan
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: _inputDecoration(
                  label: 'Tipe Kendaraan',
                  icon: Icons.directions_bike_outlined,
                ),
                items: _vehicleTypes
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _vehicleType = v),
                validator: (v) => v == null ? 'Pilih tipe kendaraan' : null,
              ),
              const SizedBox(height: 16),

              // Plat Nomor
              TextFormField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration(
                  label: 'Plat Nomor',
                  icon: Icons.numbers_outlined,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Plat nomor tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Area Tugas
              DropdownButtonFormField<String>(
                value: _selectedArea,
                decoration: _inputDecoration(
                  label: 'Area Tugas',
                  icon: Icons.location_city_outlined,
                ),
                items: _areaOptions
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedArea = v),
                validator: (v) => v == null ? 'Pilih area tugas' : null,
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textLight,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.textLight,
                          ),
                        )
                      : const Text(
                          'Simpan Profil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
    );
  }
}
