import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

enum OrderStatusFilter { all, ongoing, completed }

final ordersProvider = NotifierProvider<OrdersNotifier, List<OrderModel>>(OrdersNotifier.new);

class OrdersNotifier extends Notifier<List<OrderModel>> {
  OrderRepository get _repository => ref.read(orderRepositoryProvider);

  @override
  List<OrderModel> build() {
    // Listen to auth state changes - reload orders when user becomes authenticated
    ref.listen(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && next.user != null) {
        Future.microtask(() => loadOrders());
      }
    });

    // Juga load sekarang jika sudah authenticated (misal hot restart)
    final authStatus = ref.read(authStateProvider).status;
    if (authStatus == AuthStatus.authenticated) {
      Future.microtask(() => loadOrders());
    }

    return [];
  }

  Future<void> loadOrders() async {
    final orders = await _repository.getOrders();
    state = orders;
  }

  Future<void> addOrder(OrderModel order) async {
    final added = await _repository.addOrder(order);
    state = [added, ...state];
  }
}


final orderFilterProvider = NotifierProvider<OrderFilterNotifier, OrderStatusFilter>(OrderFilterNotifier.new);

class OrderFilterNotifier extends Notifier<OrderStatusFilter> {
  @override
  OrderStatusFilter build() => OrderStatusFilter.all;

  void setFilter(OrderStatusFilter filter) {
    state = filter;
  }
}

final orderSearchQueryProvider = NotifierProvider<OrderSearchQueryNotifier, String>(OrderSearchQueryNotifier.new);

class OrderSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setSearchQuery(String query) {
    state = query;
  }
}

final filteredOrdersProvider = Provider<List<OrderModel>>((ref) {
  final orders = ref.watch(ordersProvider);
  final filter = ref.watch(orderFilterProvider);
  final query = ref.watch(orderSearchQueryProvider).trim().toLowerCase();

  return orders.where((order) {
    // 1. Check filter status
    if (filter == OrderStatusFilter.ongoing) {
      if (order.status != OrderStatus.ongoing) return false;
    } else if (filter == OrderStatusFilter.completed) {
      if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) return false;
    }

    // 2. Check search query
    if (query.isNotEmpty) {
      final matchesId = order.id.toLowerCase().contains(query);
      final matchesTitle = order.title.toLowerCase().contains(query);
      final matchesService = order.serviceName.toLowerCase().contains(query);
      final matchesCourier = order.courierName.toLowerCase().contains(query);
      final matchesDesc = order.description.toLowerCase().contains(query);
      if (!matchesId && !matchesTitle && !matchesService && !matchesCourier && !matchesDesc) {
        return false;
      }
    }

    return true;
  }).toList();
});
