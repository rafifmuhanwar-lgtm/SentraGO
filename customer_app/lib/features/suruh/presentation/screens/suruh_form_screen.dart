import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class SuruhFormScreen extends StatefulWidget {
  const SuruhFormScreen({super.key});

  @override
  State<SuruhFormScreen> createState() => _SuruhFormScreenState();
}

class _SuruhFormScreenState extends State<SuruhFormScreen> {
  final _taskController = TextEditingController();
  final _locationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    _locationController.dispose();
    _destinationController.dispose();
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
    // Navigate to summary or directly to success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pesanan Suruh Kurir sedang diproses!')),
    );
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

            // ── Pickup Location ──
            Text('Lokasi Penjemputan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Pilih di Peta...',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // ── Destination ──
            Text('Lokasi Tujuan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                hintText: 'Pilih di Peta...',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // ── Budget ──
            Text('Estimasi Budget (Maksimal)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
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
            const SizedBox(height: 40),

            // ── Submit Button ──
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Cari Kurir'),
            ),
          ],
        ),
      ),
    );
  }
}
