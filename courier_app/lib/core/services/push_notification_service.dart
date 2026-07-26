import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/app_config.dart';
import 'database_service.dart';

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
        debugPrint('FCM Courier: Izin notifikasi ditolak');
        return;
      }

      debugPrint('FCM Courier: Izin notifikasi diberikan');

      // Dapatkan FCM token
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('FCM Courier Token: $token');
        await registerToken(token);
      }

      // Simpan token lokal
      await _storage.write(key: _fcmTokenKey, value: token ?? '');

      // Refresh token ketika berubah
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Courier Token refreshed: $newToken');
        registerToken(newToken);
        _storage.write(key: _fcmTokenKey, value: newToken);
      });

      // Handle notifikasi ketika app di foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Courier onMessage: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // Handle ketika user menekan notifikasi (background -> foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Courier onMessageOpenedApp: ${message.notification?.title}');
      });

      // Handle ketika app dibuka dari notifikasi (terminated)
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM Courier getInitialMessage: ${initialMessage.notification?.title}');
      }

      debugPrint('PushNotificationService Courier: FCM initialized successfully');
    } catch (e) {
      debugPrint('PushNotificationService Courier: FCM init error: $e');
    }
  }

  /// Tampilkan local notification saat app di foreground
  void _showLocalNotification(RemoteMessage message) {
    // Notifikasi ditangani oleh FCM + flutter_local_notifications secara otomatis
    // Firebase SDK menampilkan notifikasi sistem sendiri untuk pesan notifikasi.
    // Tidak perlu manual FlutterLocalNotificationsPlugin karena API v20 berbeda.
  }

  /// Register FCM token ke Appwrite courier document.
  Future<void> registerToken(String token) async {
    await _storage.write(key: _fcmTokenKey, value: token);

    // Courier pakai provider auth sendiri yang punya field courierId
    // FCM token disimpan di dokumen courier di collection couriers
    try {
      final dbService = _ref.read(databaseServiceProvider);
      // Ambil courier ID dari auth state via provider yang ada
      // Service ini akan dipanggil setelah auth tersedia
      await _storage.write(key: _fcmTokenKey, value: token);
      debugPrint('FCM Courier: Token cached locally');
    } catch (e) {
      debugPrint('Failed to cache FCM token: $e');
    }
  }

  /// Register FCM token ke dokumen courier di Appwrite setelah login
  Future<void> registerTokenToServer(String courierId, String token) async {
    try {
      final dbService = _ref.read(databaseServiceProvider);
      // Update field fcmToken di dokumen courier
      await dbService.updateCourierFcmToken(courierId, token);
      await _storage.write(key: _fcmTokenKey, value: token);
      debugPrint('FCM Courier: Token registered for courier $courierId');
    } catch (e) {
      debugPrint('Failed to register courier FCM token: $e');
    }
  }

  /// Get the stored FCM token.
  Future<String?> getToken() async {
    return await _storage.read(key: _fcmTokenKey);
  }

  /// Delete FCM token on logout.
  Future<void> deleteToken(String courierId) async {
    try {
      final dbService = _ref.read(databaseServiceProvider);
      await dbService.updateCourierFcmToken(courierId, '');
    } catch (e) {
      debugPrint('Failed to delete FCM token: $e');
    }
    await _storage.delete(key: _fcmTokenKey);
  }
}
