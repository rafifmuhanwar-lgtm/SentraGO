import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/order_model.dart';
import 'package:uuid/uuid.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final authState = ref.watch(authStateProvider);
  return OrderRepository(databaseService, authState.user?.id);
});

class OrderRepository {
  final DatabaseService _databaseService;
  final String? _userId;

  OrderRepository(this._databaseService, this._userId);

  Future<List<OrderModel>> getOrders() async {
    if (_userId == null) return [];

    try {
      final docs = await _databaseService.getUserOrders(_userId);
      return docs.map((doc) => OrderModel.fromJson(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<OrderModel?> getOrderById(String id) async {
    // Appwrite SDK query by id usually requires getDocument. 
    // For now we fetch all and find, or just rely on state.
    // If needed we can implement getOrder in DatabaseService.
    final orders = await getOrders();
    try {
      return orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<OrderModel> addOrder(OrderModel newOrder) async {
    if (_userId == null) return newOrder;

    try {
      final idToUse = newOrder.id.isEmpty ? const Uuid().v4() : newOrder.id;
      final orderToSave = newOrder.copyWith(id: idToUse, userId: _userId);

      final json = orderToSave.toJson();
      json.remove('\$id');

      await _databaseService.createOrder(
        orderId: idToUse,
        data: json,
      );

      return orderToSave;
    } catch (e) {
      rethrow;
    }
  }
}
