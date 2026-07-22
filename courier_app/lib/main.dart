import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_router.dart';
import 'core/constants/app_themes.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SentraCourierApp()));
}

class SentraCourierApp extends ConsumerWidget {
  const SentraCourierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SentraGO Courier',
      theme: AppThemes.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
