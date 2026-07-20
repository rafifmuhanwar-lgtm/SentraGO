
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class JastipSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const JastipSummaryScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Ringkasan Pesanan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Detail Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Detail Pesanan', style: Theme.of(context).textTheme.titleMedium),
                  const Divider(height: 24),
                  Text('Item', style: Theme.of(context).textTheme.bodySmall),
                  Text(data['item'] ?? '-', style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Text('Catatan', style: Theme.of(context).textTheme.bodySmall),
                  Text(data['notes']?.isEmpty ?? true ? '-' : data['notes'], style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Text('Budget Maksimal', style: Theme.of(context).textTheme.bodySmall),
                  Text('Rp ${data['budget']?.isEmpty ?? true ? '0' : data['budget']}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Pricing Details
            Text('Rincian Biaya', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jasa Kurir', style: Theme.of(context).textTheme.bodyMedium),
                Text('Rp 10.000', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Biaya Platform', style: Theme.of(context).textTheme.bodyMedium),
                Text('Rp 2.000', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Pembayaran', style: Theme.of(context).textTheme.titleMedium),
                Text('Rp 12.000', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary)),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // Trigger payment processing / order submission
            context.go('/jastip/success');
          },
          child: const Text('Bayar Sekarang - Rp 12.000'),
        ),
      ),
    );
  }
}
