import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../order/domain/models/order_model.dart';

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
                  final mockOrder = OrderModel(
                    id: 'Jastip #1024',
                    serviceName: 'Jastip SentraGO',
                    title: 'Sate Ayam H. Mamat',
                    description: '10 tusuk sate ayam + lontong + kerupuk. Catatan: bumbu kacang dipisah & jangan pedas.',
                    status: OrderStatus.ongoing,
                    statusText: 'Sedang Dibelikan Kurir',
                    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
                    totalAmount: 35000,
                    courierName: 'Budi',
                    courierPhone: '081234567890',
                    courierAvatar: 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=150',
                    pickupAddress: 'Restoran Sate H. Mamat, Blok A No. 12',
                    deliveryAddress: 'Jl. Sudirman No. 45, Apartemen Sentra Tower Lt. 12',
                    chatRoomId: 'room_1',
                  );
                  context.push('/order/detail', extra: mockOrder);
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
