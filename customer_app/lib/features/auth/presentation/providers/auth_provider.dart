import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? phoneNumber;

  AuthState({this.status = AuthStatus.initial, this.errorMessage, this.phoneNumber});

  AuthState copyWith({AuthStatus? status, String? errorMessage, String? phoneNumber}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    Future.microtask(() => checkAuthStatus());
    return AuthState();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    final isAuth = await _repository.isAuthenticated();
    if (isAuth) {
      state = state.copyWith(status: AuthStatus.authenticated);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> requestOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, phoneNumber: phone);
    try {
      final success = await _repository.sendOtp(phone);
      if (success) {
        state = state.copyWith(status: AuthStatus.unauthenticated); // Still unauth, but ready for OTP
        return true;
      }
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Failed to send OTP');
      return false;
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (state.phoneNumber == null) return false;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = await _repository.verifyOtp(state.phoneNumber!, otp);
      if (token != null) {
        state = state.copyWith(status: AuthStatus.authenticated);
        return true;
      } else {
        state = state.copyWith(status: AuthStatus.error, errorMessage: 'Invalid OTP Code');
        return false;
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}
