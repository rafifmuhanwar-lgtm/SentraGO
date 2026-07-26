import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/routes/app_router.dart';
import 'core/constants/app_themes.dart';
import 'core/config/app_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'features/settings/settings_provider.dart';

/// Handle notification when app is in background (terminated)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();

  // Init SharedPreferences + settings
  final settingsService = SettingsService();
  await settingsService.init();

  // Init NotificationService (vibrate only — local notif via FCM)
  final notifService = NotificationService();
  await notifService.init();

  // Init Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('Firebase Courier berhasil diinisialisasi');
  } catch (e) {
    debugPrint('Firebase Courier init error (skip): $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        settingsServiceProvider.overrideWithValue(settingsService),
        notificationServiceProvider.overrideWithValue(notifService),
      ],
      child: SentraCourierApp(),
    ),
  );
}

class SentraCourierApp extends ConsumerStatefulWidget {
  const SentraCourierApp({super.key});

  @override
  ConsumerState<SentraCourierApp> createState() => _SentraCourierAppState();
}

class _SentraCourierAppState extends ConsumerState<SentraCourierApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SentraGo Driver',
      theme: AppThemes.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
