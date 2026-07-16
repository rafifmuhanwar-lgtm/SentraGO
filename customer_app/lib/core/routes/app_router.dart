import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/location/presentation/screens/location_selection_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/jastip/presentation/screens/jastip_form_screen.dart';
import '../../features/jastip/presentation/screens/jastip_summary_screen.dart';
import '../../features/jastip/presentation/screens/jastip_success_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/location',
        builder: (context, state) => const LocationSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/jastip',
        builder: (context, state) => const JastipFormScreen(),
      ),
      GoRoute(
        path: '/jastip/summary',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return JastipSummaryScreen(data: data);
        },
      ),
      GoRoute(
        path: '/jastip/success',
        builder: (context, state) => const JastipSuccessScreen(),
      ),
    ],
  );
}
