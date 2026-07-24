import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/courier_model.dart';

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final CourierModel? courier;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.courier,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    CourierModel? courier,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      courier: courier ?? this.courier,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => checkAuthStatus());
    return const AuthState();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    final repository = ref.read(authRepositoryProvider);
    try {
      final courier = await repository.getCurrentCourier();
      debugPrint('AUTH DEBUG - Courier fetched: $courier');
      if (courier != null) {
        debugPrint('AUTH DEBUG - Courier authenticated: name=${courier.name}, vehicle=${courier.vehicleType}, area=${courier.selectedArea}, kyc=${courier.kycVerified}');
        // Do NOT call saveCourierToDatabase here — it would overwrite existing
        // profile data (vehicleType, selectedArea, kycVerified) with null values.
        // saveCourierToDatabase should only be called on first registration.
        state = state.copyWith(status: AuthStatus.authenticated, courier: courier);
      } else {
        debugPrint('AUTH DEBUG - Courier is null / no active session');
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e, stacktrace) {
      debugPrint('AUTH ERROR in checkAuthStatus: $e');
      debugPrint('AUTH STACKTRACE: $stacktrace');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();
      // After OAuth callback, session may need a brief moment to be valid.
      // Retry checkAuthStatus up to 3 times with a short delay.
      if (!kIsWeb) {
        bool authenticated = false;
        for (int i = 0; i < 3; i++) {
          await checkAuthStatus();
          if (state.status == AuthStatus.authenticated) {
            authenticated = true;
            break;
          }
          // Wait before retrying to allow session to propagate
          await Future.delayed(const Duration(milliseconds: 500));
        }
        if (!authenticated) {
          debugPrint('AUTH DEBUG - signInWithGoogle: session not ready after retries');
          state = state.copyWith(status: AuthStatus.unauthenticated);
        }
      }
    } catch (e) {
      debugPrint('AUTH ERROR in signInWithGoogle: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> handleOAuthRedirect() async {
    // Called after app is re-opened from OAuth redirect
    await checkAuthStatus();
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithEmail(email: email, password: password);
      await checkAuthStatus();
    } catch (e) {
      debugPrint('AUTH ERROR in signInWithEmail: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login Gagal: ${e.toString()}',
      );
    }
  }

  Future<void> signUpWithEmail(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signUpWithEmail(name: name, email: email, password: password);
      await checkAuthStatus();
    } catch (e) {
      debugPrint('AUTH ERROR in signUpWithEmail: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Register Gagal: ${e.toString()}',
      );
    }
  }

  void completeKyc() {
    final current = state.courier;
    if (current != null) {
      final updated = current.copyWith(kycVerified: true);
      state = state.copyWith(courier: updated);
    }
  }

  Future<void> toggleOnline() async {
    final current = state.courier;
    if (current == null) return;
    final updated = current.copyWith(isOnline: !current.isOnline);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.updateCourierProfile(updated);
      state = state.copyWith(courier: updated);
    } catch (_) {
      // Silently fail — UI stays offline if update fails
    }
  }

  Future<void> updateCourierProfile(CourierModel updated) async {
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.updateCourierProfile(updated);
      state = state.copyWith(courier: updated);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
