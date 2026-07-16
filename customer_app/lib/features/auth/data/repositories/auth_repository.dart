import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(const FlutterSecureStorage());
});

class AuthRepository {
  final FlutterSecureStorage _storage;
  
  AuthRepository(this._storage);

  static const String _tokenKey = 'jwt_token';

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  // Demo Login: Mock sending OTP
  Future<bool> sendOtp(String phoneNumber) async {
    // In production, call NestJS Backend: /auth/send-otp
    await Future.delayed(const Duration(seconds: 1));
    return true; // Assume success
  }

  // Demo Verify: Mock verifying OTP
  Future<String?> verifyOtp(String phoneNumber, String otp) async {
    // In production, call NestJS Backend: /auth/verify-otp
    await Future.delayed(const Duration(seconds: 1));
    if (otp == '8246') {
      // Return a dummy JWT token
      const dummyToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_payload';
      await saveToken(dummyToken);
      return dummyToken;
    }
    return null;
  }
}
