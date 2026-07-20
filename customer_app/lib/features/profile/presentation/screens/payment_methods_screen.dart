import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/payment_method_model.dart';
import '../providers/payment_provider.dart';
import 'widgets/payment_modals.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentList = ref.watch(paymentMethodsProvider);

    final sentraPay = paymentList.firstWhere(
      (item) => item.id == 'sentrapay',
      orElse: () => const PaymentMethodModel(
        id: 'sentrapay',
        name: 'SentraPay Wallet',
        type: 'wallet',
        balance: 150000,
        isLinked: true,
        isDefault: true,
      ),
    );

    final eWallets = paymentList.where((item) => item.type == 'ewallet').toList();
    final banks = paymentList.where((item) => item.type == 'bank').toList();
    final cashList = paymentList.where((item) => item.type == 'cash').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Metode Pembayaran'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SentraPay Wallet Card (Top Banner) ──
              _buildSentraPayCard(context, sentraPay),
              const SizedBox(height: 28),

              // ── Dompet Digital (E-Wallet) Section ──
              _buildSectionTitle(context, 'Dompet Digital (E-Wallet)'),
              const SizedBox(height: 12),
              ...eWallets.map((item) => _buildPaymentItemCard(context, ref, item)),
              const SizedBox(height: 24),

              // ── Transfer Bank & Virtual Account Section ──
              _buildSectionTitle(context, 'Transfer Bank & Virtual Account'),
              const SizedBox(height: 12),
              ...banks.map((item) => _buildPaymentItemCard(context, ref, item)),
              const SizedBox(height: 24),

              // ── Pembayaran Langsung Section ──
              _buildSectionTitle(context, 'Pembayaran Langsung'),
              const SizedBox(height: 12),
              ...cashList.map((item) => _buildPaymentItemCard(context, ref, item)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentraPayCard(BuildContext context, PaymentMethodModel wallet) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1D3A), Color(0xFF5A1228)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row atas: Nama wallet + Badge Aktif
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SentraPay Wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Aktif & Terproteksi',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (wallet.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Utama',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),

          // Row tengah: Saldo
          Text(
            'Saldo Tersedia',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Rp ${(wallet.balance ?? 0).toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 22),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // Row bawah: Tombol aksi Top Up
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => TopUpModal.show(context, wallet),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Top Up Saldo', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
    );
  }

  Widget _buildPaymentItemCard(BuildContext context, WidgetRef ref, PaymentMethodModel item) {
    final isLinked = item.isLinked;
    final isDefault = item.isDefault;

    IconData iconData = Icons.payment;
    Color iconColor = AppColors.primary;

    if (item.id == 'gopay') {
      iconData = Icons.account_balance_wallet_outlined;
      iconColor = const Color(0xFF00AED6);
    } else if (item.id == 'ovo') {
      iconData = Icons.account_balance_wallet_outlined;
      iconColor = const Color(0xFF4C3494);
    } else if (item.id == 'dana') {
      iconData = Icons.account_balance_wallet_outlined;
      iconColor = const Color(0xFF118EEA);
    } else if (item.id == 'shopeepay') {
      iconData = Icons.shopping_bag_outlined;
      iconColor = const Color(0xFFEE4D2D);
    } else if (item.type == 'bank') {
      iconData = Icons.account_balance_outlined;
      iconColor = const Color(0xFF0066AE);
    } else if (item.type == 'cash') {
      iconData = Icons.money_rounded;
      iconColor = const Color(0xFF2E7D32);
    }

    String subtitle = 'Belum terhubung';
    if (isLinked) {
      if (item.type == 'cash') {
        subtitle = 'Bayar tunai saat kurir atau pesanan tiba';
      } else if (item.balance != null) {
        subtitle = 'Saldo: Rp ${item.balance!.toStringAsFixed(0)} • ${item.accountNumber ?? ""}';
      } else if (item.accountNumber != null) {
        subtitle = 'Terhubung (${item.accountNumber})';
      } else {
        subtitle = 'Terhubung dan siap digunakan';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.border,
          width: isDefault ? 1.8 : 1,
        ),
        boxShadow: isDefault
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                        ),
                        const SizedBox(width: 6),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Utama',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isLinked ? AppColors.textSecondary : AppColors.error,
                            fontStyle: isLinked ? FontStyle.normal : FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action row di bagian bawah kartu
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isLinked) ...[
                TextButton.icon(
                  onPressed: () => LinkPaymentModal.show(context, item),
                  icon: const Icon(Icons.add_link_rounded, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Hubungkan',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                if (!isDefault)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(paymentMethodsProvider.notifier).setDefaultPayment(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} diatur sebagai metode utama'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_border_rounded, size: 18, color: AppColors.primary),
                    label: const Text(
                      'Jadikan Utama',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (item.type != 'cash' && item.id != 'sentrapay')
                  TextButton.icon(
                    onPressed: () {
                      ref.read(paymentMethodsProvider.notifier).unlinkPaymentMethod(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hubungan dengan ${item.name} diputuskan'),
                          backgroundColor: AppColors.textSecondary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.link_off_rounded, size: 17, color: AppColors.textSecondary),
                    label: const Text(
                      'Putuskan',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
