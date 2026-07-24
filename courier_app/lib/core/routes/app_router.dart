import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/help_center_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/kyc/presentation/screens/kyc_screen.dart';
import '../../features/main/presentation/screens/main_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/order/presentation/screens/orders_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/chat/domain/models/chat_room_model.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/order/domain/models/order_model.dart';
import '../../features/order/presentation/screens/order_detail_screen.dart';
import '../../features/order/presentation/screens/receipt_screen.dart';
import '../../features/profile/presentation/screens/withdrawal_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeNav');
final GlobalKey<NavigatorState> _ordersNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'ordersNav');
final GlobalKey<NavigatorState> _chatNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'chatNav');
final GlobalKey<NavigatorState> _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profileNav');

final routerProvider = Provider<GoRouter>((ref) {
  // Create a listenable to trigger router refreshes on auth state change
  final authStateNotifier = ValueNotifier<AuthStatus>(AuthStatus.initial);
  
  ref.listen(authStateProvider.select((s) => s.status), (previous, next) {
    authStateNotifier.value = next;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isChecking = authState.status == AuthStatus.initial ||
                         authState.status == AuthStatus.loading;
      final isAuthenticated = authState.status == AuthStatus.authenticated;

      if (isChecking) return null;

      final courier = authState.courier;
      final kycVerified = courier?.kycVerified ?? false;
      final hasVehicle = courier?.vehicleType != null && (courier!.vehicleType?.isNotEmpty ?? false);
      final hasArea = courier?.selectedArea != null && (courier!.selectedArea?.isNotEmpty ?? false);
      final location = state.matchedLocation;

      final isSplash = location == '/splash';
      final isLogin = location == '/login';
      final isOnboarding = location == '/onboarding';
      final isKyc = location == '/kyc';
      final isAuthRoute = isSplash || isLogin || isOnboarding || isKyc;

      if (isSplash) {
        if (isChecking) return null;
        if (!isAuthenticated) return '/login';
        if (!hasVehicle || !hasArea) return '/onboarding';
        if (!kycVerified) return '/kyc';
        return '/home';
      }

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && (!hasVehicle || !hasArea) && !isOnboarding) {
        return '/onboarding';
      }

      if (isAuthenticated && hasVehicle && hasArea && !kycVerified && !isKyc) {
        return '/kyc';
      }

      if (isAuthenticated && hasVehicle && hasArea && kycVerified && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/kyc',
        builder: (context, state) => const KycScreen(),
      ),

      // Main Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch Home
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch Orders
          StatefulShellBranch(
            navigatorKey: _ordersNavigatorKey,
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) {
                  final tabStr = state.uri.queryParameters['tab'];
                  final initialTab = int.tryParse(tabStr ?? '0') ?? 0;
                  return OrdersScreen(initialTab: initialTab);
                },
              ),
            ],
          ),
          // Branch Chat
          StatefulShellBranch(
            navigatorKey: _chatNavigatorKey,
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          // Branch Profile
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  // Edit profile is a sub-route of profile
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'help',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const HelpCenterScreen(),
                  ),
                  GoRoute(
                    path: 'withdrawal',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const WithdrawalScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // Route untuk detail order (bisa dibuka dari mana saja)
      GoRoute(
        path: '/order/detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final order = state.extra as OrderModel;
          return OrderDetailScreen(order: order);
        },
      ),
      // Route untuk upload struk (pembelian jastip)
      GoRoute(
        path: '/order/receipt',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final order = state.extra as OrderModel;
          return ReceiptScreen(order: order);
        },
      ),
      // Route chat room — full screen overlay
      GoRoute(
        path: '/chat/room',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final room = state.extra as ChatRoomModel;
          return ChatRoomScreen(room: room);
        },
      ),
    ],
  );
});
