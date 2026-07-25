import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/appwrite_client.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/notification_model.dart';

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});

class NotificationsNotifier extends Notifier<List<NotificationModel>> {
  DatabaseService get _dbService => ref.read(databaseServiceProvider);
  Realtime? _realtime;
  RealtimeSubscription? _subscription;

  @override
  List<NotificationModel> build() {
    final userId = ref.read(authStateProvider).user?.id;
    if (userId != null) {
      Future.microtask(() => loadNotifications(userId));
      _setupRealtime(userId);
    }

    ref.onDispose(() {
      _subscription?.close();
    });

    // Listen to auth changes
    ref.listen(authStateProvider, (previous, next) {
      final uid = next.user?.id;
      if (uid != null && previous?.user?.id != uid) {
        _subscription?.close();
        Future.microtask(() => loadNotifications(uid));
        _setupRealtime(uid);
      }
    });

    return [];
  }

  void _setupRealtime(String userId) {
    try {
      _realtime = ref.read(realtimeProvider);
      _subscription = _realtime?.subscribe([
        'databases.${AppConfig.appwriteDatabaseId}.collections.${AppConfig.notificationsCollection}.documents',
      ]);

      _subscription?.stream.listen((response) {
        if (response.events
            .contains('databases.*.collections.*.documents.*.create')) {
          final data = response.payload;
          if (data['userId'] == userId) {
            // Reload notifications when a new one arrives
            loadNotifications(userId);
          }
        }

        if (response.events
            .contains('databases.*.collections.*.documents.*.update')) {
          final data = response.payload;
          if (data['userId'] == userId) {
            loadNotifications(userId);
          }
        }
      });
    } catch (e) {
      print('Realtime notifications setup error: $e');
    }
  }

  Future<void> loadNotifications(String userId) async {
    final notifications = await _dbService.getUserNotifications(userId);
    state = notifications;
  }

  Future<void> markAsRead(String notificationId) async {
    await _dbService.markNotificationAsRead(notificationId);
    state = state
        .map((n) =>
            n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
  }

  Future<void> markAllAsRead() async {
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    await _dbService.markAllNotificationsAsRead(userId);
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  /// Called from outside (e.g., after order status change, top-up success, etc.)
  /// to create a notification in Appwrite and trigger realtime update.
  Future<void> createNotification({
    required String userId,
    required String category,
    required String title,
    required String body,
    String? routeName,
    Map<String, dynamic>? routeExtra,
  }) async {
    final notification = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      category: category,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      routeName: routeName,
      routeExtra: routeExtra,
    );

    try {
      await _dbService.createNotification(notification);
      // Notification will appear via realtime subscription
    } catch (e) {
      print('createNotification error: $e');
    }
  }
}