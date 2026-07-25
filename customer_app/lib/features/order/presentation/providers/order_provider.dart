import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../../domain/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../notification/domain/services/push_notification_sender.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/appwrite_client.dart';

enum OrderStatusFilter { all, ongoing, completed }

final ordersProvider = NotifierProvider<OrdersNotifier, List<OrderModel>>(OrdersNotifier.new);

class OrdersNotifier extends Notifier<List<OrderModel>> {
  OrderRepository get _repository => ref.read(orderRepositoryProvider);
  RealtimeSubscription? _subscription;

  @override
  List<OrderModel> build() {
    ref.listen(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && next.user != null) {
        _subscription?.close();
        Future.microtask(() => loadOrders());
        _setupRealtime(next.user!.id);
      }
    });

    final authStatus = ref.read(authStateProvider).status;
    final userId = ref.read(authStateProvider).user?.id;
    if (authStatus == AuthStatus.authenticated && userId != null) {
      Future.microtask(() => loadOrders());
      _setupRealtime(userId);
    }

    ref.onDispose(() {
      _subscription?.close();
    });

    return [];
  }

  void _setupRealtime(String userId) {
    try {
      final realtime = ref.read(realtimeProvider);
      _subscription = realtime.subscribe([
        'databases.${AppConfig.appwriteDatabaseId}.collections.${AppConfig.ordersCollection}.documents',
      ]);

      _subscription!.stream.listen((response) async {
        if (response.events
            .contains('databases.*.collections.*.documents.*.update')) {
          final data = response.payload;
          if (data['userId'] == userId) {
            final newStatus = data['status'] as String?;
            final statusText = data['statusText'] as String? ?? '';

            loadOrders();

            String? title;
            String? body;

            if (newStatus == 'completed' || statusText == 'Pesanan Selesai') {
              title = 'Pesanan Selesai ✅';
              body = 'Pesanan Anda telah selesai. Terima kasih telah menggunakan SentraGO!';
            } else if (newStatus == 'cancelled') {
              title = 'Pesanan Dibatalkan ❌';
              body = 'Pesanan Anda telah dibatalkan.';
            } else if (statusText.contains('sampai di lokasi') || statusText.contains('Sampai di Lokasi')) {
              title = 'Kurir Sampai di Lokasi 📍';
              body = 'Kurir sudah sampai di lokasi penjemputan.';
            } else if (statusText.contains('Barang Dibeli') || statusText.contains('tugas selesai')) {
              title = 'Barang Berhasil Dibeli 🛒';
              body = 'Kurir berhasil membeli barang pesanan Anda.';
            } else if (statusText.contains('Dalam Perjalanan') || statusText.contains('dalam perjalanan')) {
              title = 'Pesanan Dalam Perjalanan 🛵';
              body = 'Kurir sedang dalam perjalanan menuju lokasi Anda.';
            }

            if (title != null && body != null) {
              ref.read(notificationsProvider.notifier).createNotification(
                userId: userId,
                title: title,
                body: body,
                category: 'Pesanan',
                routeName: '/tracking',
              );

              ref.read(pushNotificationSenderProvider).sendToUser(
                userId: userId,
                title: title,
                body: body,
                category: 'Pesanan',
                route: '/tracking',
              );
            }
          }
        }
      });
    } catch (e) {
      print('Order realtime error: $e');
    }
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
    if (filter == OrderStatusFilter.ongoing) {
      if (order.status != OrderStatus.ongoing) return false;
    } else if (filter == OrderStatusFilter.completed) {
      if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled) return false;
    }

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
