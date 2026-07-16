import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JastipFormScreen extends StatefulWidget {
  const JastipFormScreen({super.key});

  @override
  State<JastipFormScreen> createState() => _JastipFormScreenState();
}

class _JastipFormScreenState extends State<JastipFormScreen> {
  final _itemController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_itemController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item harus diisi')));
      return;
    }
    context.push('/jastip/summary', extra: {
      'item': _itemController.text,
      'budget': _budgetController.text,
      'notes': _notesController.text,
      'pickup': _pickupController.text,
      'dropoff': _dropoffController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Titip Belanja'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mau titip beli apa?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(
                hintText: 'Martabak manis Bang Udin...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text('Lokasi Penjual (Opsional)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _pickupController,
              decoration: const InputDecoration(
                hintText: 'Pilih di Peta...',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),
            Text('Alamat Tujuan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _dropoffController,
              decoration: const InputDecoration(
                hintText: 'Pilih di Peta...',
                prefixIcon: Icon(Icons.home_outlined),
              ),
            ),
            const SizedBox(height: 24),
            Text('Estimasi Budget (Maksimal)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '50.000',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jika harga melebihi budget, kurir akan konfirmasi ke kamu terlebih dahulu.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text('Catatan Tambahan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Contoh: tingkat kemanisan, tidak pedas, dll.',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }
}
