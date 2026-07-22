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
      return docs
          .where((doc) => (doc['courierName'] ?? '').isEmpty)
          .map((doc) => OrderModel.fromJson(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<OrderModel>> getMyOrders(String courierId) async {
    try {
      final docs = await _databaseService.getOrdersByQuery([
        Query.equal('courierId', courierId),
      ]);
      return docs.map((doc) => OrderModel.fromJson(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> acceptOrder(String orderId, String courierId, String courierName) async {
    await _databaseService.updateOrderStatus(
      orderId,
      'ongoing',
      extraData: {
        'courierId': courierId,
        'courierName': courierName,
        'statusText': 'Courier assigned',
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
}
