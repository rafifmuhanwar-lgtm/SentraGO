import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/appwrite_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  File? _ktpImage;
  File? _selfieImage;
  bool _isSubmitting = false;

  Future<void> _pickKtp() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file != null) setState(() => _ktpImage = File(file.path));
  }

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file != null) setState(() => _selfieImage = File(file.path));
  }

  Future<String> _uploadImage(File image, String prefix) async {
    final storage = ref.read(appwriteStorageProvider);
    final courierId = ref.read(authStateProvider).courier?.id ?? 'unknown';

    final uploaded = await storage.createFile(
      bucketId: AppConfig.storageBucketId,
      fileId: ID.unique(),
      file: InputFile.fromPath(
        path: image.path,
        filename:
            '${prefix}_${courierId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    return uploaded.$id;
  }

  Future<void> _submit() async {
    if (_ktpImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap foto KTP dan Selfie terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Upload KTP & Selfie ke Appwrite Storage
      await _uploadImage(_ktpImage!, 'ktp');
      await _uploadImage(_selfieImage!, 'selfie');

      // Update courier document dengan kycVerified = true
      final courier = ref.read(authStateProvider).courier;
      if (courier != null) {
        final updated = courier.copyWith(kycVerified: true);
        final repository = ref.read(authRepositoryProvider);
        await repository.updateCourierProfile(updated);
      }

      if (!mounted) return;

      ref.read(authStateProvider.notifier).completeKyc();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifikasi KYC berhasil! Selamat bertugas 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verifikasi KYC'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text('Verifikasi Identitas',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kamu wajib verifikasi identitas sebelum bisa bertugas. Siapkan KTP dan foto selfie.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // KTP Upload
            _buildPhotoCard(
              title: 'Foto KTP',
              subtitle: 'Ambil foto KTP jelas dan terbaca',
              imageFile: _ktpImage,
              onPick: _pickKtp,
            ),
            const SizedBox(height: 16),

            // Selfie Upload
            _buildPhotoCard(
              title: 'Foto Selfie',
              subtitle: 'Selfie sambil memegang KTP',
              imageFile: _selfieImage,
              onPick: _pickSelfie,
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Kirim Verifikasi',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String subtitle,
    required File? imageFile,
    required VoidCallback onPick,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onPick,
            child: Container(
              height: 160,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.border, style: BorderStyle.solid),
              ),
              child: imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          Image.file(imageFile, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder()),
                    )
                  : _buildPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text('Tap untuk foto',
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7))),
      ],
    );
  }
}
