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
        debugPrint('AUTH DEBUG - Saving courier to database...');
        try {
          await repository.saveCourierToDatabase(courier);
          debugPrint('AUTH DEBUG - Save successful');
        } catch (e) {
          // Save may fail if collection schema doesn't have all courier fields yet
          // But session is still valid — proceed with authenticated state
          debugPrint('AUTH DEBUG - Save skipped (non-critical): $e');
        }
        state = state.copyWith(status: AuthStatus.authenticated, courier: courier);
      } else {
        debugPrint('AUTH DEBUG - Courier is null');
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
      // Hapus session sebelumnya biar gak bentrok
      try {
        await repository.logout();
      } catch (_) {}
      await repository.signInWithGoogle();
      // After OAuth redirect, the app will be re-opened
      // checkAuthStatus will be called to detect the new session
      await checkAuthStatus();
    } catch (e) {
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
