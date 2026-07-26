import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:courier_app/features/settings/settings_provider.dart';
import 'package:courier_app/core/services/notification_service.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/models/order_model.dart';

/// Notifier untuk daftar pesanan yang tersedia (belum diambil kurir)
class AvailableOrdersNotifier extends Notifier<List<OrderModel>> {
  List<OrderModel> _previousOrders = [];

  @override
  List<OrderModel> build() {
    refresh();
    return [];
  }

  Future<void> refresh() async {
    final repo = ref.read(orderRepositoryProvider);
    final orders = await repo.getAvailableOrders();
    final settings = ref.read(settingsProvider);

    // Deteksi pesanan BARU (yang belum ada di state sebelumnya)
    if (_previousOrders.isNotEmpty && orders.length > _previousOrders.length) {
      final existingIds = _previousOrders.map((o) => o.id).toSet();
      final newOrders = orders.where((o) => !existingIds.contains(o.id)).toList();

      if (newOrders.isNotEmpty) {
        if (settings.vibrateOnOrder) {
          final notifService = ref.read(notificationServiceProvider);
          await notifService.vibrate();
        }

        if (settings.notifyNewOrder) {
          final notifService = ref.read(notificationServiceProvider);
          for (final order in newOrders) {
            await notifService.showNotification(
              id: order.id.hashCode,
              title: 'Pesanan Baru!',
              body: '${order.title} — ${order.type == 'jastip' ? 'Jastip' : 'Suruh'} • Rp${order.totalAmount.toInt()}',
            );
          }
        }
      }
    }

    _previousOrders = List.from(orders);
    state = orders;
  }
}

/// Notifier untuk pesanan milik kurir ini
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
