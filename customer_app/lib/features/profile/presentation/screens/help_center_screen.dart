import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class _FaqItem {
  final String id;
  final String category;
  final String question;
  final String answer;

  const _FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Jastip Belanja',
    'Suruh Kurir',
    'Pembayaran',
    'Akun',
  ];

  final List<_FaqItem> _allFaqs = const [
    _FaqItem(
      id: 'faq-1',
      category: 'Jastip Belanja',
      question: 'Bagaimana cara memesan layanan Jastip Belanja di SentraGO?',
      answer:
          '1. Buka menu "Jastip Belanja" dari Beranda.\n'
          '2. Masukkan nama toko, estimasi harga, dan rincian barang yang ingin dibeli.\n'
          '3. Tentukan lokasi penjemputan dan pengiriman barang.\n'
          '4. Pilih metode pembayaran lalu klik "Buat Pesanan". Kurir SentraGO terdekat akan segera mengambil pesanan Anda.',
    ),
    _FaqItem(
      id: 'faq-2',
      category: 'Jastip Belanja',
      question: 'Bagaimana jika harga asli barang di toko berbeda dengan estimasi?',
      answer:
          'Mitra Kurir kami akan mengunggah foto struk resmi pembelian. Jika terdapat selisih harga, sistem akan otomatis menyesuaikan total bayar pada tagihan akhir atau saldo SentraPay Wallet Anda secara transparan.',
    ),
    _FaqItem(
      id: 'faq-3',
      category: 'Suruh Kurir',
      question: 'Apa itu layanan Suruh Kurir dan kapan saya bisa menggunakannya?',
      answer:
          'Layanan Suruh Kurir siap membantu berbagai keperluan darurat dan harian Anda, mulai dari antar-jemput dokumen penting, membeli obat di apotek 24 jam, mengambil barang tertinggal, hingga mengantarkan kado/bingkisan dengan cepat.',
    ),
    _FaqItem(
      id: 'faq-4',
      category: 'Suruh Kurir',
      question: 'Berapa batas berat maksimal untuk pengiriman barang via Suruh Kurir?',
      answer:
          'Batas berat maksimal untuk pengiriman motor adalah 20 kg dengan dimensi maksimal 50 x 50 x 50 cm. Untuk barang yang lebih besar atau rentan pecah, sistem menyediakan opsi proteksi asuransi tambahan.',
    ),
    _FaqItem(
      id: 'faq-5',
      category: 'Pembayaran',
      question: 'Bagaimana cara melakukan Top Up saldo SentraPay Wallet?',
      answer:
          'Masuk ke menu "Akun" > "Pembayaran", lalu klik tombol "Top Up" pada kartu SentraPay Wallet. Anda dapat mengisi saldo menggunakan transfer Virtual Account Bank (BCA, Mandiri, BRI, BNI) atau E-Wallet lain tanpa biaya admin.',
    ),
    _FaqItem(
      id: 'faq-6',
      category: 'Pembayaran',
      question: 'Apakah SentraGO mendukung metode pembayaran Tunai (COD)?',
      answer:
          'Ya! Anda dapat memilih metode pembayaran Tunai (COD) untuk membayar ongkos kirim maupun harga barang belanjaan langsung kepada mitra kurir saat barang tiba di lokasi Anda.',
    ),
    _FaqItem(
      id: 'faq-7',
      category: 'Akun',
      question: 'Bagaimana cara memperbarui profil dan alamat utama saya?',
      answer:
          'Buka menu "Akun" di navigasi bawah, lalu pilih "Edit Profil" untuk memperbarui nama, email, dan nomor telepon. Untuk mengatur alamat rumah atau kantor, pilih menu "Alamat Tersimpan".',
    ),
    _FaqItem(
      id: 'faq-8',
      category: 'Akun',
      question: 'Bagaimana jika saya mengalami kendala saat pesanan berlangsung?',
      answer:
          'Tim Customer Service SentraGO beroperasi 24 jam setiap hari. Anda dapat langsung menekan tombol "Live Chat CS" di bagian atas halaman ini untuk terhubung seketika dengan agen kami tanpa antrean.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FaqItem> get _filteredFaqs {
    return _allFaqs.where((faq) {
      final matchesCategory =
          _selectedCategory == 'Semua' || faq.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _showContactModal(String title, String subtitle, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  ctx.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Menghubungkan ke $title...'),
                      backgroundColor: color,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mulai Sekarang',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pusat Bantuan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search Header Bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Cari kendala atau pertanyaan Anda...',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick Contact Support Channels ──
              const Text(
                'Hubungi Kami',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildContactCard(
                      context: context,
                      icon: Icons.support_agent_rounded,
                      title: 'Live Chat CS',
                      subtitle: 'Respons < 2 mnt',
                      color: AppColors.primary,
                      onTap: () => _showContactModal(
                        'Live Chat CS 24/7',
                        'Terhubung langsung dengan tim dukungan SentraGO untuk penyelesaian cepat kendala pesanan Anda.',
                        Icons.support_agent_rounded,
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildContactCard(
                      context: context,
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'WhatsApp',
                      subtitle: '+62 811-900-800',
                      color: const Color(0xFF25D366),
                      onTap: () => _showContactModal(
                        'WhatsApp Official CS',
                        'Kirimkan pesan dan tangkapan layar kendala Anda melalui saluran resmi WhatsApp SentraGO.',
                        Icons.chat_bubble_outline_rounded,
                        const Color(0xFF25D366),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildContactCard(
                      context: context,
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: 'Bantuan 24/7',
                      color: const Color(0xFF3B82F6),
                      onTap: () => _showContactModal(
                        'Email Support Resmi',
                        'Kirim pertanyaan atau klaim asuransi pesanan Anda ke alamat email resmi support@sentrago.id.',
                        Icons.email_outlined,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── FAQ Section Title & Categories ──
              const Text(
                'Pertanyaan Populer (FAQ)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        showCheckmark: false,
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // ── FAQ Accordion List ──
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.help_outline_rounded,
                          size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'Pertanyaan tidak ditemukan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coba kata kunci lain atau pilih kategori yang berbeda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map((faq) => _buildFaqCard(context, faq)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context, _FaqItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text(
              faq.question,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  faq.answer,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
