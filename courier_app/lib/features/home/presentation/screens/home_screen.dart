import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/courier_earnings_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final courier = authState.courier;
    final earningsAsync = ref.watch(courierEarningsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Profile Info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.background,
                              backgroundImage: courier?.photoUrl != null
                                  ? NetworkImage(courier!.photoUrl!)
                                  : null,
                              child: courier?.photoUrl == null
                                  ? Text(
                                      (courier?.name.isNotEmpty == true
                                              ? courier!.name[0]
                                              : 'K')
                                          .toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo,',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textLight.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  courier?.name ?? 'Kurir',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Online/Offline Toggle
                        if (courier != null)
                          GestureDetector(
                            onTap: () => ref.read(authStateProvider.notifier).toggleOnline(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: courier.isOnline
                                    ? AppColors.success
                                    : AppColors.textSecondary.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.textLight.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    courier.isOnline ? Icons.check_circle : Icons.power_settings_new,
                                    size: 14,
                                    color: AppColors.textLight,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    courier.isOnline ? 'Online' : 'Offline',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quick Stats (Hari Ini)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.textLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickStat(
                            title: 'Poin',
                            value: '600',
                            icon: Icons.stars,
                            color: Colors.orange,
                          ),
                          Container(width: 1, height: 40, color: AppColors.border),
                          _buildQuickStat(
                            title: 'Performa',
                            value: '80%',
                            icon: Icons.trending_up,
                            color: Colors.blue,
                          ),
                          Container(width: 1, height: 40, color: AppColors.border),
                          _buildQuickStat(
                            title: 'Saldo',
                            value: earningsAsync.when(
                              data: (data) {
                                if (data.saldo >= 1000000) {
                                  return 'Rp${(data.saldo / 1000000).toStringAsFixed(1)}jt';
                                } else if (data.saldo >= 1000) {
                                  return 'Rp${(data.saldo / 1000).toStringAsFixed(0)}rb';
                                }
                                return 'Rp${data.saldo.toInt()}';
                              },
                              loading: () => '...',
                              error: (_, __) => 'Rp0',
                            ),
                            icon: Icons.account_balance_wallet,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Shortcut Menus
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menu Pintas',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMenuShortcut(
                          context,
                          title: 'Pesanan',
                          icon: Icons.assignment_outlined,
                          color: Colors.blue,
                          onTap: () => context.go('/orders'), // GoRouter will handle tab switch
                        ),
                        _buildMenuShortcut(
                          context,
                          title: 'Pendapatan',
                          icon: Icons.monetization_on_outlined,
                          color: Colors.green,
                          onTap: () => context.go('/profile'), // Temporarily map to profile
                        ),
                        _buildMenuShortcut(
                          context,
                          title: 'Riwayat',
                          icon: Icons.history,
                          color: Colors.orange,
                          onTap: () => context.go('/orders?tab=2'),
                        ),
                        _buildMenuShortcut(
                          context,
                          title: 'Swadaya',
                          icon: Icons.handshake_outlined,
                          color: Colors.purple,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fitur segera hadir')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Info & Tips Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Info Terkini',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      title: 'Bonus Target Mingguan!',
                      description: 'Selesaikan 50 order minggu ini dan dapatkan bonus saldo tambahan Rp100.000.',
                      imageUrl: 'https://via.placeholder.com/400x200.png?text=Promo',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      title: 'Tips Berkendara Aman',
                      description: 'Pastikan kondisi kendaraanmu prima dan patuhi rambu lalu lintas selama bertugas.',
                      imageUrl: 'https://via.placeholder.com/400x200.png?text=Tips+Aman',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuShortcut(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            imageUrl,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 120,
              width: double.infinity,
              color: AppColors.primaryLight.withValues(alpha: 0.3),
              child: const Icon(Icons.image_outlined, size: 40, color: AppColors.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
