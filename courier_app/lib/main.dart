import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/constants/app_themes.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const ProviderScope(child: SentraCourierApp()));
}

class SentraCourierApp extends ConsumerWidget {
  const SentraCourierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SentraGo Driver',
      theme: AppThemes.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
