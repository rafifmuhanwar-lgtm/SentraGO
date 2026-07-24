import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../order/domain/models/order_model.dart';
import '../../domain/models/withdrawal_model.dart';
import 'package:appwrite/appwrite.dart';

class CourierEarnings {
  final double hariIni;
  final double bulanIni;
  final double total;
  final double saldo;

  const CourierEarnings({
    this.hariIni = 0,
    this.bulanIni = 0,
    this.total = 0,
    this.saldo = 0,
  });
}

final courierEarningsProvider = FutureProvider.autoDispose<CourierEarnings>((ref) async {
  final courier = ref.watch(authStateProvider).courier;
  if (courier == null) return const CourierEarnings();

  final dbService = ref.read(databaseServiceProvider);
  final now = DateTime.now();

  try {
    // 1. Ambil order yang sudah selesai (completed) untuk kurir ini
    final queries = [
      Query.equal('courierId', courier.id),
    ];
    
    final ordersData = await dbService.getOrdersByQuery(queries);
    final allOrders = ordersData.map((e) => OrderModel.fromJson(e)).toList();
    
    // Filter manual di Dart untuk menghindari error index Appwrite
    final orders = allOrders.where((o) => o.statusText == 'Pesanan Selesai' || o.status.name == 'completed' || o.status.toString().contains('completed')).toList();

    double hariIni = 0;
    double bulanIni = 0;
    double total = 0;
    double saldo = 0;

    for (final order in orders) {
      // Pendapatan kurir adalah Ongkir
      final pendapatanOrder = order.ongkir; 
      
      // Jika Jastip, ada pengembalian totalBelanjaStruk juga ke Saldo
      // Tapi karena uang itu sebelumnya uang kurir sendiri, maka untuk "Pendapatan Bersih", 
      // yang dihitung hanya ongkir (dan biayaLayanan jika itu untuk platform).
      // Saldo di dompet virtual kurir bertambah sebesar: ongkir + totalBelanjaStruk
      
      double penambahanSaldo = pendapatanOrder;
      if (order.type == 'jastip' && order.totalBelanjaStruk != null) {
        penambahanSaldo += order.totalBelanjaStruk!;
      }

      total += pendapatanOrder;
      saldo += penambahanSaldo;

      // Filter hari ini
      if (order.createdAt.year == now.year &&
          order.createdAt.month == now.month &&
          order.createdAt.day == now.day) {
        hariIni += pendapatanOrder;
      }

      // Filter bulan ini
      if (order.createdAt.year == now.year &&
          order.createdAt.month == now.month) {
        bulanIni += pendapatanOrder;
      }
    }

    // 2. Ambil penarikan saldo (withdrawals) untuk kurir ini
    final withdrawalsData = await dbService.getWithdrawals(courier.id);
    final withdrawals = withdrawalsData.map((e) => WithdrawalModel.fromJson(e)).toList();

    double totalWithdrawn = 0;
    for (final w in withdrawals) {
      if (w.status == 'pending' || w.status == 'approved') {
        totalWithdrawn += w.amount;
      }
    }

    return CourierEarnings(
      hariIni: hariIni,
      bulanIni: bulanIni,
      total: total,
      saldo: saldo - totalWithdrawn, // Saldo bersih setelah ditarik
    );
  } catch (e) {
    return const CourierEarnings();
  }
});
