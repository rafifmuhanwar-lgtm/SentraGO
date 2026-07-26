import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/withdrawal_model.dart';
import '../../../order/domain/models/order_model.dart';
import '../../../order/data/repositories/order_repository.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  bool _isLoading = true;
  final List<WithdrawalModel> _withdrawals = [];
  final List<OrderModel> _completedOrders = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final courier = ref.read(authStateProvider).courier;
      if (courier == null) return;

      final dbService = ref.read(databaseServiceProvider);
      final orderRepo = ref.read(orderRepositoryProvider);

      // Ambil withdrawals
      final withdrawalsData = await dbService.getWithdrawals(courier.id);
      final withdrawals = withdrawalsData
          .map((e) => WithdrawalModel.fromJson(e))
          .toList();

      // Ambil completed orders
      final orders = await orderRepo.getMyOrders(courier.id);
      final completed = orders
          .where((o) => o.status == OrderStatus.completed)
          .toList();

      if (mounted) {
        setState(() {
          _withdrawals.clear();
          _withdrawals.addAll(withdrawals);
          _completedOrders.clear();
          _completedOrders.addAll(completed);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String formatCurrency(double amount) {
    final integer = amount.round();
    final formatted = integer.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );
    return 'Rp$formatted';
  }

  String formatDate(DateTime dt) {
    return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // — Penarikan Saldo Section —
                  _buildSectionHeader('Penarikan Saldo', Icons.account_balance_outlined),
                  const SizedBox(height: 8),
                  if (_withdrawals.isEmpty)
                    _buildEmptyState('Belum ada penarikan saldo')
                  else
                    ..._withdrawals.map((w) => _buildWithdrawalCard(w)),

                  const SizedBox(height: 28),

                  // — Pesanan Selesai Section —
                  _buildSectionHeader('Pesanan Selesai', Icons.check_circle_outline),
                  const SizedBox(height: 8),
                  if (_completedOrders.isEmpty)
                    _buildEmptyState('Belum ada pesanan selesai')
                  else
                    ..._completedOrders.map((o) => _buildOrderCard(o)),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }

  Widget _buildWithdrawalCard(WithdrawalModel w) {
    final statusColor = w.status == 'approved'
        ? AppColors.success
        : w.status == 'rejected'
            ? AppColors.error
            : AppColors.warning;
    final statusLabel = w.status == 'approved'
        ? 'Disetujui'
        : w.status == 'rejected'
            ? 'Ditolak'
            : 'Menunggu';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCurrency(w.amount),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${w.bankName} • ${w.accountNumber}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel o) {
    final pendapatan = o.ongkir;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.title.isNotEmpty ? o.title : 'Pesanan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${o.type == 'jastip' ? 'Jastip' : 'Suruh'} • ${formatDate(o.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(pendapatan),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
