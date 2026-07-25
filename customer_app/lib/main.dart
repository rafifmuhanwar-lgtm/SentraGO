import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'features/notification/presentation/providers/notification_provider.dart';
import 'features/notification/presentation/providers/push_notification_service.dart';

/// Global local notifications plugin instance
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// Handle notification when app is in background (terminated)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  try {
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: androidSettings),
    );

    await flutterLocalNotificationsPlugin.show(
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
  } catch (e) {
    debugPrint('Background notification error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();

  // Inisialisasi Firebase
  try {
    await Firebase.initializeApp();

    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Setup local notification channel
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    debugPrint('Firebase berhasil diinisialisasi');
  } catch (e) {
    debugPrint('Firebase init error (skip): $e');
  }

  runApp(const ProviderScope(child: SentraApp()));
}

class SentraApp extends ConsumerStatefulWidget {
  const SentraApp({super.key});

  @override
  ConsumerState<SentraApp> createState() => _SentraAppState();
}

class _SentraAppState extends ConsumerState<SentraApp> {
  @override
  void initState() {
    super.initState();
    // Init FCM setelah widget terpasang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'SentraGO',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
