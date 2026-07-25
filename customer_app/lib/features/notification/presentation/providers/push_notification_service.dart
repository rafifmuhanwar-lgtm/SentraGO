import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

class PushNotificationService {
  final Ref _ref;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _fcmTokenKey = 'fcm_token';

  PushNotificationService(this._ref);

  /// Initialize FCM: minta izin, dapatkan token, dan pasang listener.
  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Minta izin notifikasi
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: Izin notifikasi ditolak');
        return;
      }

      debugPrint('FCM: Izin notifikasi diberikan');

      // Dapatkan FCM token
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await registerToken(token);
      }

      // Simpan token lokal
      await _storage.write(key: _fcmTokenKey, value: token ?? '');

      // Refresh token ketika berubah
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        registerToken(newToken);
        _storage.write(key: _fcmTokenKey, value: newToken);
      });

      // Handle notifikasi ketika app di foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM onMessage: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // Handle ketika user menekan notifikasi (background -> foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM onMessageOpenedApp: ${message.notification?.title}');
      });

      // Handle ketika app dibuka dari notifikasi (terminated)
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM getInitialMessage: ${initialMessage.notification?.title}');
      }

      debugPrint('PushNotificationService: FCM initialized successfully');
    } catch (e) {
      debugPrint('PushNotificationService: FCM init error: $e');
    }
  }

  /// Tampilkan local notification saat app di foreground
  void _showLocalNotification(RemoteMessage message) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.show(
      message.messageId.hashCode,
      message.notification?.title ?? 'SentraGO',
      message.notification?.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'sentrago_channel',
          'SentraGO Notifikasi',
          channelDescription: 'Notifikasi pesanan dan promo SentraGO',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Register FCM token ke Appwrite user document.
  Future<void> registerToken(String token) async {
    await _storage.write(key: _fcmTokenKey, value: token);

    final userId = _ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    try {
      final dbService = _ref.read(databaseServiceProvider);
      await dbService.updateUser(
        userId: userId,
        data: {'fcmToken': token},
      );
      debugPrint('FCM: Token registered for user $userId');
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  /// Get the stored FCM token.
  Future<String?> getToken() async {
    return await _storage.read(key: _fcmTokenKey);
  }

  /// Delete FCM token on logout.
  Future<void> deleteToken() async {
    await _storage.delete(key: _fcmTokenKey);

    final userId = _ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    try {
      final dbService = _ref.read(databaseServiceProvider);
      await dbService.updateUser(
        userId: userId,
        data: {'fcmToken': ''},
      );
    } catch (e) {
      debugPrint('Failed to delete FCM token: $e');
    }
  }
}

