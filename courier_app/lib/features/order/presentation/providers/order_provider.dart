import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/models/order_model.dart';

class AvailableOrdersNotifier extends Notifier<List<OrderModel>> {
  @override
  List<OrderModel> build() {
    refresh();
    return [];
  }

  Future<void> refresh() async {
    final repo = ref.read(orderRepositoryProvider);
    state = await repo.getAvailableOrders();
  }
}

class MyOrdersNotifier extends Notifier<List<OrderModel>> {
  @override
  List<OrderModel> build() {
    final courier = ref.watch(authStateProvider).courier;
    if (courier != null) {
      refresh(courier.id);
    }
    return [];
  }

  Future<void> refresh(String courierId) async {
    final repo = ref.read(orderRepositoryProvider);
    state = await repo.getMyOrders(courierId);
  }
}

final availableOrdersProvider =
    NotifierProvider<AvailableOrdersNotifier, List<OrderModel>>(
  AvailableOrdersNotifier.new,
);

final myOrdersProvider =
    NotifierProvider<MyOrdersNotifier, List<OrderModel>>(
  MyOrdersNotifier.new,
);
