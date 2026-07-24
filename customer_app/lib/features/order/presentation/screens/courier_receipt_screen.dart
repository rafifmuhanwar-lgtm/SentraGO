import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/escrow_settlement_service.dart';
import '../../domain/models/order_model.dart';

class CourierReceiptScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const CourierReceiptScreen({super.key, required this.order});

  @override
  ConsumerState<CourierReceiptScreen> createState() => _CourierReceiptScreenState();
}

class _CourierReceiptScreenState extends ConsumerState<CourierReceiptScreen> {
  final _receiptAmountController = TextEditingController();
  bool _isSaving = false;
  String? _selectedImagePath;

  Widget _buildImagePreview(String path) {
    final bool isNetwork = path.startsWith('http://') || path.startsWith('https://') || (kIsWeb && path.startsWith('blob:'));
    if (isNetwork || kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildUploadPlaceholder(),
      );
    }
    final File file = path.startsWith('file://') ? File.fromUri(Uri.parse(path)) : File(path);
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildUploadPlaceholder(),
    );
  }

  @override
  void dispose() {
    _receiptAmountController.dispose();
    super.dispose();
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
        title: const Text('Upload Struk Belanja'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Informasi Pesanan', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow(context, 'Item', widget.order.title),
                  const SizedBox(height: 6),
                  _infoRow(context, 'Dana Belanja', 'Rp ${widget.order.danaBelanja.toStringAsFixed(0)}'),
                  const SizedBox(height: 6),
                  _infoRow(context, 'Ongkir', 'Rp ${widget.order.ongkir.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dana Belanja info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Belanja Sesuai Struk',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masukkan nominal sesuai struk belanja dari toko',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Photo upload area
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                      ),
                      child: _selectedImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImagePreview(_selectedImagePath!),
                            )
                          : _buildUploadPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount input
                  TextField(
                    controller: _receiptAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      hintText: 'Contoh: 40000',
                      labelText: 'Total Belanja',
                    ),
                  ),
                ],
              ),
            ),

            // Kebijakan jika melebihi dana
            if (widget.order.kebijakanLebih == 'jangan_lebih') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kebijakan: Jangan melebihi dana belanja. Kurangi barang jika total melebihi Rp ${widget.order.danaBelanja.toStringAsFixed(0)}.',
                        style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Simpan & Hitung Refund', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        const SizedBox(height: 8),
        Text('Tap untuk upload foto struk', style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.7))),
      ],
    );
  }

  Future<void> _pickImage() async {
    // In production, use image_picker package. For now, show dialog with mock option.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur upload foto akan segera hadir. Masukkan nominal struk untuk melanjutkan.')),
    );
  }

  Future<void> _submit() async {
    final receiptAmountText = _receiptAmountController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final receiptAmount = double.tryParse(receiptAmountText);

    if (receiptAmount == null || receiptAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan total belanja yang valid')),
      );
      return;
    }

    // Check if exceeds dana belanja and kebijakan is jangan_lebih
    if (receiptAmount > widget.order.danaBelanja && widget.order.kebijakanLebih == 'jangan_lebih') {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Melebihi Dana Belanja'),
            content: Text(
              'Total belanja (Rp ${receiptAmount.toStringAsFixed(0)}) melebihi dana belanja '
              '(Rp ${widget.order.danaBelanja.toStringAsFixed(0)}).\n\n'
              'Kebijakan: Jangan melebihi dana belanja.\n'
              'Kurangi jumlah barang hingga sesuai dana, atau hubungi customer untuk menambah dana.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kembali'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _proceedSettlement(receiptAmount);
                },
                child: const Text('Lanjutkan (Hitung Refund)'),
              ),
            ],
          ),
        );
      }
      return;
    }

    _proceedSettlement(receiptAmount);
  }

  Future<void> _proceedSettlement(double receiptAmount) async {
    setState(() => _isSaving = true);

    try {
      final settlementService = EscrowSettlementService();
      final result = settlementService.hitungSettlement(
        danaBelanja: widget.order.danaBelanja,
        totalBelanjaStruk: receiptAmount,
        ongkir: widget.order.ongkir,
        biayaLayanan: widget.order.biayaLayanan,
        kebijakanLebih: widget.order.kebijakanLebih,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghitung settlement. Periksa kembali total belanja.')),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      // Update order status to completed with receipt data
      // This is a simplified version — in production, save to DB properly
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isOverBudget
                  ? 'Pesanan selesai! Refund: Rp ${result.refundCustomer.toStringAsFixed(0)}'
                  : 'Pesanan selesai! Refund Rp ${result.refundCustomer.toStringAsFixed(0)} ke customer',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate back
        context.pop();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }
}
