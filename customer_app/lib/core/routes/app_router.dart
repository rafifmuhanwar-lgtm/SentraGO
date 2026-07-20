import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/location/presentation/screens/location_selection_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/screens/main_screen.dart';
import '../../features/jastip/presentation/screens/jastip_form_screen.dart';
import '../../features/jastip/presentation/screens/jastip_summary_screen.dart';
import '../../features/jastip/presentation/screens/jastip_success_screen.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/chat/domain/models/chat_room_model.dart';
import '../../features/order/presentation/screens/order_detail_screen.dart';
import '../../features/order/domain/models/order_model.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';
import '../../features/suruh/presentation/screens/suruh_form_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/saved_addresses_screen.dart';
import '../../features/profile/presentation/screens/payment_methods_screen.dart';
import '../../features/profile/presentation/screens/help_center_screen.dart';
import '../../features/profile/presentation/screens/about_app_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isSplash = state.matchedLocation == '/';
      final isLocation = state.matchedLocation == '/location';
      final isLogin = state.matchedLocation == '/login';
      final isAuthRoute = isSplash || isLocation || isLogin;

      // Allow splash screen to handle its own flow
      if (isSplash) return null;

      // Allow location selection before login
      if (isLocation) return null;

      // If authenticated and on login, go to main
      if (authState.status == AuthStatus.authenticated && isLogin) {
        return '/main';
      }

      // If unauthenticated and not on an auth route, redirect to login
      if (authState.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/login';
      }

      return null;
    },
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
      GoRoute(
        path: '/chat/room',
        builder: (context, state) {
          final room = state.extra as ChatRoomModel;
          return ChatRoomScreen(room: room);
        },
      ),
      GoRoute(
        path: '/order/detail',
        builder: (context, state) {
          final order = state.extra as OrderModel;
          return OrderDetailScreen(order: order);
        },
      ),
      GoRoute(
        path: '/tracking',
        builder: (context, state) => const TrackingScreen(),
      ),
      GoRoute(
        path: '/suruh',
        builder: (context, state) => const SuruhFormScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) => const SavedAddressesScreen(),
      ),
      GoRoute(
        path: '/profile/payment',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/profile/about',
        builder: (context, state) => const AboutAppScreen(),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
