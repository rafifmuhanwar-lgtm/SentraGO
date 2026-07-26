import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifPlugin = FlutterLocalNotificationsPlugin();
  bool _hapticSupported = true;
  bool _initialized = false;

  Future<void> init() async {
    // Init local notifications
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _notifPlugin.initialize(InitializationSettings(android: androidSettings));
      _initialized = true;
    } catch (e) {
      debugPrint('Notif init error: $e');
    }

    // Test haptic
    try {
      await HapticFeedback.mediumImpact();
      _hapticSupported = true;
    } catch (_) {
      _hapticSupported = false;
    }
  }

  /// Getar (HapticFeedback)
  Future<void> vibrate() async {
    if (!_hapticSupported) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      try { await HapticFeedback.mediumImpact(); } catch (_) {}
    }
  }

  /// Tampilkan local notification di tray
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'sentrago_courier_channel',
        'Notifikasi Kurir',
        channelDescription: 'Notifikasi pesanan dan info untuk kurir SentraGO',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _notifPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      debugPrint('Show notification error: $e');
    }
  }
}
