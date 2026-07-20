import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class _NotificationItem {
  final String id;
  final String category; // 'Pesanan', 'Promo & Info', 'Sistem & Akun'
  final String title;
  final String body;
  final String time;
  bool isRead;
  final IconData icon;
  final Color color;
  final String? route;

  _NotificationItem({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    required this.icon,
    required this.color,
    this.route,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Pesanan',
    'Promo & Info',
    'Sistem & Akun',
  ];

  late List<_NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      _NotificationItem(
        id: 'notif-1',
        category: 'Pesanan',
        title: 'Kurir Sedang Membeli Barang Anda 🛒',
        body: 'Mitra Kurir (Budi Santoso) telah tiba di Indomaret Point dan sedang melakukan verifikasi struk belanjaan Anda.',
        time: '10 mnt lalu',
        isRead: false,
        icon: Icons.storefront_rounded,
        color: AppColors.primary,
        route: '/tracking',
      ),
      _NotificationItem(
        id: 'notif-2',
        category: 'Promo & Info',
        title: 'Gratis Ongkir Hingga Rp 10.000! 🎉',
        body: 'Gunakan kode voucher TITIPDB untuk menikmati potongan gratis ongkos kirim pada pesanan Jastip Belanja pertama Anda hari ini.',
        time: '1 jam lalu',
        isRead: false,
        icon: Icons.percent_rounded,
        color: const Color(0xFFE65100),
      ),
      _NotificationItem(
        id: 'notif-3',
        category: 'Sistem & Akun',
        title: 'Top Up SentraPay Berhasil 💳',
        body: 'Top up saldo sebesar Rp 150.000 melalui Virtual Account BCA telah berhasil ditambahkan ke dompet SentraPay Anda.',
        time: '3 jam lalu',
        isRead: true,
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF2E7D32),
      ),
      _NotificationItem(
        id: 'notif-4',
        category: 'Pesanan',
        title: 'Pesanan Suruh Kurir Selesai ✅',
        body: 'Dokumen penting Anda telah berhasil dikirim dan diterima oleh Ibu Rina di SCBD Tower. Terima kasih telah menggunakan SentraGO!',
        time: 'Kemarin, 16:45',
        isRead: true,
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF2E7D32),
      ),
      _NotificationItem(
        id: 'notif-5',
        category: 'Promo & Info',
        title: 'Layanan Darurat Obat 24 Jam Siap! 💊',
        body: 'Butuh resep atau vitamin malam hari? Kurir SentraGO siap membelikan di Apotek K-24 terdekat kapan pun Anda butuh.',
        time: '18 Jul, 20:15',
        isRead: true,
        icon: Icons.local_pharmacy_rounded,
        color: const Color(0xFF1565C0),
      ),
      _NotificationItem(
        id: 'notif-6',
        category: 'Sistem & Akun',
        title: 'Keamanan Akun Diperbarui 🛡️',
        body: 'Sistem telah melakukan pengecekan berkala. Akun Anda terlindungi dengan enkripsi SSL/TLS tingkat tinggi.',
        time: '16 Jul, 11:30',
        isRead: true,
        icon: Icons.security_rounded,
        color: const Color(0xFF1565C0),
      ),
    ];
  }

  void _markAllAsRead() {
    setState(() {
      for (var item in _notifications) {
        item.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Semua notifikasi telah ditandai sebagai dibaca.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showNotificationDetail(_NotificationItem item) {
    setState(() {
      item.isRead = true;
    });

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
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.body,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (item.route != null) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ctx.pop();
                    context.push(item.route!);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Lihat Status Pesanan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => ctx.pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notifications.where((n) {
      if (_selectedCategory == 'Semua') return true;
      return n.category == _selectedCategory;
    }).toList();

    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifikasi'),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                'Tandai Dibaca',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Categories Filter Header ──
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final isAll = cat == 'Semua';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                            if (isAll && unreadCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.background,
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
            ),
            const Divider(height: 1, color: AppColors.divider),

            // ── Notifications List ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                size: 48,
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum Ada Notifikasi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saat ini belum ada pembaruan pada kategori $_selectedCategory Anda.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildNotificationCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(_NotificationItem item) {
    return Material(
      color: item.isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showNotificationDetail(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
              width: item.isRead ? 0.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (!item.isRead) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 10,
                            color: item.isRead ? AppColors.textSecondary : AppColors.primary,
                            fontWeight: item.isRead ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'Detail',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
