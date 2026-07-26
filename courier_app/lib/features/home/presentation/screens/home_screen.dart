import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/courier_earnings_provider.dart';
import '../../../order/presentation/providers/order_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final courier = authState.courier;
    final earningsAsync = ref.watch(courierEarningsProvider);
    final availableOrders = ref.watch(availableOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ─── HEADER CARD ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // Top bar: avatar + name + online toggle
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          backgroundImage: courier?.photoUrl != null
                              ? NetworkImage(courier!.photoUrl!)
                              : null,
                          child: courier?.photoUrl == null
                              ? Text(
                                  (courier?.name.isNotEmpty == true ? courier!.name[0] : 'K').toUpperCase(),
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Selamat datang,', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                              Text(courier?.name ?? 'Kurir', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                        if (courier != null)
                          GestureDetector(
                            onTap: () => ref.read(authStateProvider.notifier).toggleOnline(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: courier.isOnline ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: courier.isOnline ? const Color(0xFF69F0AE) : Colors.white70,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(courier.isOnline ? 'Online' : 'Offline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Balance Card
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.06)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.amber, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Saldo', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                                const SizedBox(height: 2),
                                earningsAsync.when(
                                  data: (data) => Text(
                                    'Rp${data.saldo.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  loading: () => const SizedBox(height: 24, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))),
                                  error: (_, __) => const Text('Rp0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${availableOrders.length}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(width: 4),
                                Text('order', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          _headerStat(context, Icons.today, 'Hari Ini', earningsAsync.when(data: (d) => 'Rp${d.hariIni.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}', loading: () => '...', error: (_, __) => 'Rp0'), Colors.orange),
                          _headerDivider(),
                          _headerStat(context, Icons.calendar_month, 'Bulan Ini', earningsAsync.when(data: (d) => 'Rp${d.bulanIni.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}', loading: () => '...', error: (_, __) => 'Rp0'), Colors.lightBlue),
                          _headerDivider(),
                          _headerStat(context, Icons.stars, 'Poin', '600', Colors.amber),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── MENU PINTAS ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Menu Pintas'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _menuCard(context, Icons.assignment_rounded, 'Pesanan', Colors.blue, '${availableOrders.length} tersedia', () => context.go('/orders')),
                        const SizedBox(width: 12),
                        _menuCard(context, Icons.monetization_on_rounded, 'Pendapatan', Colors.green, 'Lihat detail', () => context.go('/profile')),
                        const SizedBox(width: 12),
                        _menuCard(context, Icons.history_rounded, 'Riwayat', Colors.orange, 'Pesanan lalu', () => context.go('/orders?tab=2')),
                        const SizedBox(width: 12),
                        _menuCard(context, Icons.notifications_rounded, 'Notifikasi', Colors.purple, 'Info terbaru', () => context.push('/notifications')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ─── INFO TERKINI ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Info Terkini'),
                    const SizedBox(height: 14),
                    _infoCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Bonus Target Mingguan',
                      desc: 'Selesaikan 50 order minggu ini & dapatkan bonus saldo Rp100.000!',
                      color: Colors.amber,
                      bgColor: const Color(0xFFFFF8E1),
                      onTap: () => context.go('/profile'),
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      icon: Icons.shield_rounded,
                      title: 'Tips Berkendara Aman',
                      desc: 'Patuhi rambu lalu lintas & jaga kondisi kendaraan saat bertugas.',
                      color: Colors.blue,
                      bgColor: const Color(0xFFE3F2FD),
                      onTap: () => context.push('/profile/help'),
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      icon: Icons.rocket_launch_rounded,
                      title: 'Mulai Dapatkan Order',
                      desc: 'Buka tab Pesanan & nyalakan status Online untuk mulai menerima order.',
                      color: AppColors.primary,
                      bgColor: const Color(0xFFF3E5F5),
                      onTap: () => context.go('/orders'),
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

  // ─── REUSABLE WIDGETS ─────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
  }

  Widget _headerStat(BuildContext context, IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.65))),
        ],
      ),
    );
  }

  Widget _headerDivider() {
    return Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15));
  }

  Widget _menuCard(BuildContext context, IconData icon, String title, Color color, String subtitle, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
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
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withValues(alpha: 0.75))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required Color bgColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 4)]),
                child: Icon(Icons.chevron_right, color: color, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
