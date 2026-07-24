import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../domain/models/order_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return OrderRepository(databaseService);
});

class OrderRepository {
  final DatabaseService _databaseService;

  OrderRepository(this._databaseService);

  Future<List<OrderModel>> getAvailableOrders() async {
    try {
      final docs = await _databaseService.getOrdersByQuery([
        Query.equal('status', 'ongoing'),
      ]);
      // Hanya tampilkan pesanan yang belum diambil kurir manapun
      return docs
          .where((doc) =>
              doc['status'] == 'ongoing' &&
              (doc['courierId'] == null || (doc['courierId'] as String).isEmpty))
          .map((doc) => OrderModel.fromJson(doc))
          .toList();
    } catch (e) {
      print('getAvailableOrders error: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getMyOrders(String courierId) async {
    try {
      final docs = await _databaseService.getOrdersByQuery([
        Query.equal('courierId', courierId),
      ]);
      return docs
          .where((doc) => doc['courierId'] == courierId)
          .map((doc) => OrderModel.fromJson(doc))
          .toList();
    } catch (e) {
      print('getMyOrders error: $e');
      return [];
    }
  }

  Future<void> acceptOrder(String orderId, String courierId, String courierName) async {
    await _databaseService.updateOrderStatus(
      orderId,
      'ongoing',
      extraData: {
        'courierId': courierId,
        'statusText': 'Kurir menuju lokasi jemput',
      },
    );
  }

  Future<void> updateOrderStatus(String orderId, String status, {String? statusText}) async {
    final extraData = <String, dynamic>{};
    if (statusText != null) {
      extraData['statusText'] = statusText;
    }
    await _databaseService.updateOrderStatus(
      orderId,
      status,
      extraData: extraData.isNotEmpty ? extraData : null,
    );
  }

  Future<void> updateCourierLocation(String orderId, double lat, double lng) async {
    await _databaseService.updateCourierLocation(orderId, lat, lng);
  }
}
