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
      print("AUTH DEBUG - User fetched: $user");
      if (user != null) {
        // Save/update user in database on session restore
        print("AUTH DEBUG - Saving user to database...");
        await repository.saveUserToDatabase(user);
        print("AUTH DEBUG - Saved user to database successfully.");
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        print("AUTH DEBUG - User is null");
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e, stacktrace) {
      print("AUTH ERROR in checkAuthStatus: $e");
      print("AUTH STACKTRACE: $stacktrace");
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final repository = ref.read(authRepositoryProvider);
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

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
