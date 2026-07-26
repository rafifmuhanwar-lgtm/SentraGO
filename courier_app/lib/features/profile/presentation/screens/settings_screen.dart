import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/settings/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // — Notifikasi —
          _buildSectionHeader('Notifikasi'),
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Pesanan Baru',
            subtitle: 'Dapatkan notifikasi saat ada pesanan baru',
            value: settings.notifyNewOrder,
            onChanged: (v) => ref.read(settingsProvider.notifier).setNotifyNewOrder(v),
          ),
          _buildSwitchTile(
            icon: Icons.chat_outlined,
            title: 'Pesan Chat',
            subtitle: 'Notifikasi saat pelanggan mengirim pesan',
            value: settings.notifyChat,
            onChanged: (v) => ref.read(settingsProvider.notifier).setNotifyChat(v),
          ),
          _buildSwitchTile(
            icon: Icons.discount_outlined,
            title: 'Promo & Info',
            subtitle: 'Info terbaru tentang promo dan bonus',
            value: settings.notifyPromo,
            onChanged: (v) => ref.read(settingsProvider.notifier).setNotifyPromo(v),
          ),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: 'Getar Saat Pesanan',
            subtitle: 'Vibrasi saat ada pesanan masuk',
            value: settings.vibrateOnOrder,
            onChanged: (v) => ref.read(settingsProvider.notifier).setVibrateOnOrder(v),
          ),

          const SizedBox(height: 16),
          // — Privasi —
          _buildSectionHeader('Privasi & Keamanan'),
          _buildSwitchTile(
            icon: Icons.visibility_outlined,
            title: 'Tampilkan Status Online',
            subtitle: 'Pelanggan dapat melihat status Anda',
            value: settings.showOnlineStatus,
            onChanged: (v) => ref.read(settingsProvider.notifier).setShowOnlineStatus(v),
          ),
          _buildMenuTile(
            icon: Icons.lock_outline,
            title: 'Ubah Kata Sandi',
            subtitle: 'Perbarui password akun Anda',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Silakan hubungi CS untuk mengubah kata sandi')),
              );
            },
          ),

          const SizedBox(height: 16),
          // — Lainnya —
          _buildSectionHeader('Lainnya'),
          _buildSwitchTile(
            icon: Icons.battery_std_outlined,
            title: 'Mode Hemat Baterai',
            subtitle: settings.saveBatteryMode
                ? 'Update lokasi dikurangi. Buka Settings > Lokasi untuk efek optimal'
                : 'Kurangi frekuensi update lokasi untuk hemat baterai',
            value: settings.saveBatteryMode,
            onChanged: (v) => ref.read(settingsProvider.notifier).setSaveBatteryMode(v),
          ),
          _buildMenuTile(
            icon: Icons.info_outline,
            title: 'Versi Aplikasi',
            subtitle: 'v1.0.0',
            onTap: () {},
            showArrow: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: showArrow
            ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
