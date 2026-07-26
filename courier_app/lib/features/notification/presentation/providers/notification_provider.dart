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
  String? _currentUserId;

  @override
  List<NotificationModel> build() {
    final courier = ref.read(authStateProvider).courier;
    if (courier != null) {
      _currentUserId = courier.id;
      Future.microtask(() => loadNotifications(courier.id));
      _setupRealtime(courier.id);
    }

    ref.onDispose(() {
      _subscription?.close();
    });

    // Listen to auth changes
    ref.listen(authStateProvider, (previous, next) {
      final uid = next.courier?.id;
      if (uid != null && previous?.courier?.id != uid) {
        _currentUserId = uid;
        _subscription?.close();
        Future.microtask(() => loadNotifications(uid));
        _setupRealtime(uid);
      }
    });

    return [];
  }

  void _setupRealtime(String courierId) {
    try {
      _realtime = ref.read(realtimeProvider);
      _subscription = _realtime?.subscribe([
        'databases.${AppConfig.appwriteDatabaseId}.collections.${AppConfig.notificationsCollection}.documents',
      ]);

      _subscription?.stream.listen((response) {
        if (response.events
            .contains('databases.*.collections.*.documents.*.create')) {
          final data = response.payload;
          if (data['userId'] == (_currentUserId ?? courierId)) {
            loadNotifications(_currentUserId ?? courierId);
          }
        }

        if (response.events
            .contains('databases.*.collections.*.documents.*.update')) {
          final data = response.payload;
          if (data['userId'] == (_currentUserId ?? courierId)) {
            loadNotifications(_currentUserId ?? courierId);
          }
        }
      });
    } catch (e) {
      print('Realtime notifications setup error: $e');
    }
  }

  Future<void> loadNotifications(String userId) async {
    try {
      final docs = await _dbService.getUserNotifications(userId);
      state = docs
          .map((doc) => NotificationModel.fromMap(doc, doc['\$id'] ?? ''))
          .toList();
    } catch (e) {
      state = [];
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _dbService.markNotificationAsRead(notificationId);
      state = state.map((n) {
        return n.id == notificationId ? n.copyWith(isRead: true) : n;
      }).toList();
    } catch (e) {
      // silent
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _dbService.markAllNotificationsAsRead(userId);
      state = state.map((n) => n.copyWith(isRead: true)).toList();
    } catch (e) {
      // silent
    }
  }
}
