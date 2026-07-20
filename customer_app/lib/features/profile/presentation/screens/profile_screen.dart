import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Akun Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Pengguna',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // ── Menu List ──
            _buildMenuList(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, WidgetRef ref) {
    final menuItems = [
      _MenuData(Icons.person_outline, 'Edit Profil'),
      _MenuData(Icons.location_on_outlined, 'Alamat Tersimpan'),
      _MenuData(Icons.notifications_outlined, 'Notifikasi'),
      _MenuData(Icons.payment_outlined, 'Pembayaran'),
      _MenuData(Icons.confirmation_number_outlined, 'Voucher Saya'),
      _MenuData(Icons.favorite_border, 'Favorit'),
      _MenuData(Icons.help_outline, 'Pusat Bantuan'),
      _MenuData(Icons.info_outline, 'Tentang Aplikasi'),
    ];

    return Column(
      children: [
        const SizedBox(height: 8),
        ...menuItems.map((item) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
          leading: Icon(item.icon, color: AppColors.textSecondary),
          title: Text(
            item.title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          onTap: () {
            // Navigate to respective page
          },
        )),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 24),
        // ── Logout Button ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _MenuData {
  final IconData icon;
  final String title;

  _MenuData(this.icon, this.title);
}
