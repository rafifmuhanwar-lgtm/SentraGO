import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class JastipSuccessScreen extends StatelessWidget {
  const JastipSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 32),
              Text(
                'Pesanan Dibuat!',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Kurir sedang mencari pesananmu.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Navigate to Tracking
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('Lihat Detail Order'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.go('/main');
                },
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
