import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/kyc/presentation/screens/kyc_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/order/domain/models/order_model.dart';
import '../../features/order/presentation/screens/order_detail_screen.dart';
import '../../features/order/presentation/screens/receipt_screen.dart';
import '../../features/auth/presentation/screens/edit_profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isChecking = authState.status == AuthStatus.initial ||
                         authState.status == AuthStatus.loading;
      final isAuthenticated = authState.status == AuthStatus.authenticated;

      // Don't redirect while auth is still being checked
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

      // Splash: tunggu auth selesai dulu, baru redirect
      if (isSplash) {
        if (isChecking) return null;        // masih loading, tunggu
        // Auth udah selesai — redirect sesuai kondisi
        if (!isAuthenticated) return '/login';
        if (!hasVehicle || !hasArea) return '/onboarding';
        if (!kycVerified) return '/kyc';
        return '/home';
      }

      // If not authenticated, go to login
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // If authenticated, check onboarding (vehicle + area)
      if (isAuthenticated && (!hasVehicle || !hasArea) && !isOnboarding) {
        return '/onboarding';
      }

      // If authenticated + onboarded but KYC not done, go to KYC
      if (isAuthenticated && hasVehicle && hasArea && !kycVerified && !isKyc) {
        return '/kyc';
      }

      // If fully done, and trying to go to auth routes, go to home
      if (isAuthenticated && hasVehicle && hasArea && kycVerified && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/kyc',
        name: 'kyc',
        builder: (context, state) => const KycScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/order/detail',
        name: 'orderDetail',
        builder: (context, state) {
          final order = state.extra as OrderModel;
          return OrderDetailScreen(order: order);
        },
      ),
      GoRoute(
        path: '/order/receipt',
        name: 'receipt',
        builder: (context, state) {
          final order = state.extra as OrderModel;
          return ReceiptScreen(order: order);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
});
