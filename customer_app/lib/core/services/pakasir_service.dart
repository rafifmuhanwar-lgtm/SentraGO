import 'package:dio/dio.dart';
import '../config/app_config.dart';

class PakasirService {
  final Dio _dio;

  PakasirService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.pakasirBaseUrl,
          headers: {
            'Content-Type': 'application/json',
          },
        ));

  /// Create a new transaction on Pakasir.
  /// [method] is one of: 'qris', 'bni_va', 'bri_va', 'cimb_niaga_va', etc.
  /// Returns the payment response body on success, or throws on error.
  Future<Map<String, dynamic>> createTransaction({
    required String method,
    required String orderId,
    required int amount,
  }) async {
    final response = await _dio.post(
      '/api/transactioncreate/$method',
      data: {
        'project': AppConfig.pakasirProjectSlug,
        'order_id': orderId,
        'amount': amount,
        'api_key': AppConfig.pakasirApiKey,
      },
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    throw Exception('Pakasir createTransaction failed: ${response.statusCode}');
  }

  /// Get transaction detail / status from Pakasir.
  Future<Map<String, dynamic>> getTransactionDetail({
    required String orderId,
    required int amount,
  }) async {
    final response = await _dio.get(
      '/api/transactiondetail',
      queryParameters: {
        'project': AppConfig.pakasirProjectSlug,
        'order_id': orderId,
        'amount': amount,
        'api_key': AppConfig.pakasirApiKey,
      },
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    throw Exception(
        'Pakasir getTransactionDetail failed: ${response.statusCode}');
  }

  /// Cancel a pending transaction on Pakasir.
  Future<void> cancelTransaction({
    required String orderId,
    required int amount,
  }) async {
    final response = await _dio.post(
      '/api/transactioncancel',
      data: {
        'project': AppConfig.pakasirProjectSlug,
        'order_id': orderId,
        'amount': amount,
        'api_key': AppConfig.pakasirApiKey,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Pakasir cancelTransaction failed: ${response.statusCode}');
    }
  }

  /// Simulate a successful payment (only works in sandbox mode).
  Future<void> simulatePayment({
    required String orderId,
    required int amount,
  }) async {
    final response = await _dio.post(
      '/api/paymentsimulation',
      data: {
        'project': AppConfig.pakasirProjectSlug,
        'order_id': orderId,
        'amount': amount,
        'api_key': AppConfig.pakasirApiKey,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Pakasir simulatePayment failed: ${response.statusCode}');
    }
  }

  /// List of available payment methods for UI.
  static const List<Map<String, dynamic>> availableMethods = [
    {
      'id': 'qris',
      'name': 'QRIS',
      'icon': 'qr_code',
      'subtitle': 'Semua E-Wallet & Mobile Banking',
    },
    {
      'id': 'bni_va',
      'name': 'BNI Virtual Account',
      'icon': 'account_balance',
      'subtitle': 'Transfer BNI',
    },
    {
      'id': 'bri_va',
      'name': 'BRI Virtual Account',
      'icon': 'account_balance',
      'subtitle': 'Transfer BRI',
    },
    {
      'id': 'cimb_niaga_va',
      'name': 'CIMB Niaga Virtual Account',
      'icon': 'account_balance',
      'subtitle': 'Transfer CIMB Niaga',
    },
    {
      'id': 'mandiri_va',
      'name': 'Mandiri Virtual Account',
      'icon': 'account_balance',
      'subtitle': 'Transfer Mandiri',
    },
    {
      'id': 'maybank_va',
      'name': 'Maybank Virtual Account',
      'icon': 'account_balance',
      'subtitle': 'Transfer Maybank',
    },
    {
      'id': 'permata_va',
      'name': 'Permata Virtual Account',
      'icon': 'account_balance',
      'subtitle': 'Transfer Permata',
    },
    {
      'id': 'atm_bersama_va',
      'name': 'ATM Bersama Virtual Account',
      'icon': 'account_balance',
      'subtitle': 'Transfer via ATM Bersama',
    },
  ];
}
