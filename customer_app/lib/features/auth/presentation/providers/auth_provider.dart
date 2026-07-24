import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final UserModel? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    UserModel? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      user: user ?? this.user,
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
      final user = await repository.getCurrentUser();
      if (user != null) {
        // Do NOT call saveUserToDatabase here — it may overwrite existing profile data
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e, stacktrace) {
      print('AUTH ERROR in checkAuthStatus: $e');
      print('AUTH STACKTRACE: $stacktrace');
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.signInWithGoogle();
      // Retry checkAuthStatus after OAuth — session may need a moment to propagate
      bool authenticated = false;
      for (int i = 0; i < 3; i++) {
        await checkAuthStatus();
        if (state.status == AuthStatus.authenticated) {
          authenticated = true;
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (!authenticated) {
        print('AUTH DEBUG - signInWithGoogle: session not ready after retries');
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      print('AUTH ERROR in signInWithGoogle: $e');
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
      print('AUTH ERROR in signInWithEmail: $e');
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
      print('AUTH ERROR in signUpWithEmail: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Register Gagal: ${e.toString()}',
      );
    }
  }


  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> updateProfile({
    required String name,
    String? phone,
    String? selectedArea,
    String? photoUrl,
  }) async {
    if (state.user == null) return;
    try {
      final updatedUser = state.user!.copyWith(
        name: name,
        phone: phone,
        selectedArea: selectedArea,
        photoUrl: photoUrl ?? state.user!.photoUrl,
      );
      final repository = ref.read(authRepositoryProvider);
      final savedUser = await repository.updateUserProfile(updatedUser);
      state = state.copyWith(user: savedUser);
    } catch (e) {
      rethrow;
    }
  }
}
