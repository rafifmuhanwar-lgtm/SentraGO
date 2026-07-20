import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  void _showInfoModal(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => ctx.pop(),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.divider),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => ctx.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const termsText =
        '1. Ketentuan Umum\n'
        'Selamat datang di aplikasi SentraGO. Dengan mengunduh, memasang, atau menggunakan aplikasi ini, Anda setuju untuk terikat dengan Syarat & Ketentuan Layanan yang berlaku.\n\n'
        '2. Layanan Jastip Belanja & Suruh Kurir\n'
        'SentraGO menyediakan platform teknologi yang menghubungkan Pengguna dengan Mitra Kurir independen. SentraGO bertanggung jawab atas keamanan sistem transaksi, sedangkan Mitra Kurir bertanggung jawab atas penanganan fisik dan ketepatan pengantaran barang.\n\n'
        '3. Biaya & Pembayaran\n'
        'Seluruh rincian tarif pengantaran, estimasi harga barang belanjaan, serta biaya layanan ditampilkan secara transparan sebelum konfirmasi pesanan. Pembayaran dapat dilakukan via SentraPay Wallet, Transfer Bank, atau Tunai (COD).\n\n'
        '4. Batasan Tanggung Jawab\n'
        'SentraGO tidak bertanggung jawab atas isi atau kualitas barang belanjaan yang dibeli oleh Mitra Kurir dari toko pihak ketiga, kecuali barang mengalami kerusakan fisik akibat kelalaian kurir selama proses perjalanan.\n\n'
        '5. Pembaruan Ketentuan\n'
        'Kami berhak mengubah atau memperbarui Syarat & Ketentuan ini sewaktu-waktu. Pengguna disarankan memeriksa halaman ini secara berkala.';

    const privacyText =
        '1. Pengumpulan Data Informasi\n'
        'Kami mengumpulkan informasi pribadi yang Anda berikan saat pendaftaran akun, seperti Nama Lengkap, Alamat Email, Nomor Telepon, serta data lokasi perangkat saat Anda memesan layanan atau menggunakan fitur pelacakan.\n\n'
        '2. Penggunaan Informasi\n'
        'Data yang dikumpulkan digunakan semata-mata untuk memproses pesanan Jastip dan Suruh Kurir, memfasilitasi komunikasi antara Anda dan Mitra Kurir, meningkatkan keamanan akun, serta mengoptimalkan pengalaman pengguna.\n\n'
        '3. Perlindungan & Keamanan Data\n'
        'SentraGO menerapkan standar enkripsi SSL/TLS tingkat tinggi untuk melindungi seluruh data transaksi keuangan dan informasi pribadi Anda dari akses pihak yang tidak berwenang.\n\n'
        '4. Pembagian Data kepada Pihak Ketiga\n'
        'Kami tidak akan memperjualbelikan data pribadi Anda kepada pihak mana pun. Informasi lokasi dan kontak hanya dibagikan kepada Mitra Kurir yang bertugas menangani pesanan aktif Anda.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Tentang Aplikasi'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // ── App Hero Badge & Version ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SentraGO',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Asisten Jastip Belanja & Suruh Kurir Cepat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Versi 1.0.0 (Build 102)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── App Mission & Description Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Misi SentraGO',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SentraGO hadir sebagai platform digital modern yang menghubungkan kebutuhan harian masyarakat dengan armada kurir terpercaya. Kami berkomitmen memberikan kenyamanan, keamanan transaksi, dan transparansi penuh dalam setiap pesanan Jastip maupun pengantaran instan Anda.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Key Features Highlights ──
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Fitur Unggulan Kami',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureRow(
                icon: Icons.shopping_bag_outlined,
                title: 'Jastip Belanja Transparan',
                description: 'Beli barang dari toko mana pun dengan bukti foto struk asli dan harga jujur.',
              ),
              _buildFeatureRow(
                icon: Icons.delivery_dining_outlined,
                title: 'Suruh Kurir Multi-Keperluan',
                description: 'Antar jemput dokumen rahasia, obat 24 jam, hingga kado dengan cepat & aman.',
              ),
              _buildFeatureRow(
                icon: Icons.account_balance_wallet_outlined,
                title: 'SentraPay Terintegrasi',
                description: 'Sistem pembayaran digital praktis, bebas biaya admin, & aman terenkripsi.',
              ),
              const SizedBox(height: 24),

              // ── Legal & Information Links ──
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Informasi & Hukum',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
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
                child: Column(
                  children: [
                    _buildMenuTile(
                      context: context,
                      icon: Icons.description_outlined,
                      title: 'Syarat & Ketentuan Layanan',
                      onTap: () => _showInfoModal(
                        context,
                        'Syarat & Ketentuan',
                        termsText,
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _buildMenuTile(
                      context: context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Kebijakan Privasi',
                      onTap: () => _showInfoModal(
                        context,
                        'Kebijakan Privasi',
                        privacyText,
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _buildMenuTile(
                      context: context,
                      icon: Icons.code_rounded,
                      title: 'Lisensi Open Source',
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: 'SentraGO Customer App',
                        applicationVersion: '1.0.0',
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 40),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    _buildMenuTile(
                      context: context,
                      icon: Icons.star_outline_rounded,
                      title: 'Beri Rating Aplikasi',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Terima kasih! Mengarahkan ke toko aplikasi...'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // ── Footer Copyright ──
              const Text(
                '© 2026 PT Sentra Digital Nusantara\nAll rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }
}
