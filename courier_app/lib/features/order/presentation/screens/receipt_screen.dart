import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/appwrite_client.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/models/order_model.dart';
import '../../../../core/services/database_service.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const ReceiptScreen({super.key, required this.order});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalBelanjaController = TextEditingController();
  final _picker = ImagePicker();
  File? _strukImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _totalBelanjaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _strukImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadStruk(File image) async {
    final storage = ref.read(appwriteStorageProvider);
    final uploaded = await storage.createFile(
      bucketId: AppConfig.storageBucketId,
      fileId: ID.unique(),
      file: InputFile.fromPath(
        path: image.path,
        filename:
            'struk_${widget.order.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    return uploaded.$id;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_strukImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap foto struk belanja terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final totalBelanjaStruk =
          double.parse(_totalBelanjaController.text.trim());
      final danaBelanja = widget.order.danaBelanja;
      final ongkir = widget.order.ongkir;
      final refundCustomer = danaBelanja - totalBelanjaStruk;
      final paymentToCourier = totalBelanjaStruk + ongkir;

      // Upload foto struk ke Appwrite Storage
      await _uploadStruk(_strukImage!);

      // Update order dengan data settlement
      await ref.read(databaseServiceProvider).updateOrderStatus(
        widget.order.id,
        'completed',
        extraData: {
          'statusText': 'Selesai',
          'totalBelanjaStruk': totalBelanjaStruk,
          'refundCustomer': refundCustomer,
          'paymentToCourier': paymentToCourier,
        },
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text(
                'Settlement Berhasil',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: AppColors.divider),
              const SizedBox(height: 8),
              _settlementRow('Dana Belanja', danaBelanja),
              _settlementRow('Total Belanja (Struk)', totalBelanjaStruk),
              const Divider(color: AppColors.divider),
              _settlementRow(
                'Refund ke Customer',
                refundCustomer,
                valueColor:
                    refundCustomer >= 0 ? AppColors.success : AppColors.error,
              ),
              const SizedBox(height: 8),
              _settlementRow(
                'Payment ke Kurir',
                paymentToCourier,
                valueColor: AppColors.primary,
              ),
              const SizedBox(height: 8),
              _settlementRow('Ongkir', ongkir, isSub: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _settlementRow(String label, double amount,
      {Color? valueColor, bool isSub = false}) {
    return Padding(
      padding: EdgeInsets.only(left: isSub ? 16.0 : 0, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSub ? 13 : 14,
              fontWeight: isSub ? FontWeight.normal : FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isSub ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Struk'),
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
              // Order info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.order.type == 'jastip' ? 'Jastip' : 'Suruh',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Divider(color: AppColors.divider),
                    _infoRow('Dana Belanja',
                        'Rp ${widget.order.danaBelanja.toStringAsFixed(0)}'),
                    _infoRow('Ongkir',
                        'Rp ${widget.order.ongkir.toStringAsFixed(0)}'),
                    _infoRow('Biaya Layanan',
                        'Rp ${widget.order.biayaLayanan.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Struk photo upload
              const Text(
                'Foto Struk Belanja',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _strukImage != null
                          ? AppColors.success
                          : AppColors.border,
                      width: _strukImage != null ? 2 : 1,
                    ),
                  ),
                  child: _strukImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_strukImage!, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _strukImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: AppColors.textLight,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.success.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Foto struk diambil',
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 48,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tap untuk foto struk belanja',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Total belanja input
              TextFormField(
                controller: _totalBelanjaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Belanja (Struk)',
                  hintText: 'Masukkan total dari struk',
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
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
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Masukkan total belanja dari struk';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount < 0) {
                    return 'Masukkan nominal yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
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
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.textLight,
                          ),
                        )
                      : const Text(
                          'Submit Settlement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
