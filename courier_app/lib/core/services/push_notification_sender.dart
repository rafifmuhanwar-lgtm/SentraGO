import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../config/app_config.dart';
import 'appwrite_client.dart';
import 'push_notification_service.dart';

/// Service untuk memanggil Appwrite Cloud Function
/// yang mengirim push notification ke user (pelanggan).
final pushNotificationSenderProvider = Provider<PushNotificationSender>((ref) {
  return PushNotificationSender(ref);
});

class PushNotificationSender {
  final Ref _ref;

  PushNotificationSender(this._ref);

  Functions? _functions;

  Functions get _fn {
    _functions ??= Functions(_ref.read(appwriteClientProvider));
    return _functions!;
  }

  /// Kirim push notification ke pelanggan tertentu
  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    String category = 'Pesanan',
    String? route,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final payload = {
        'userId': userId,
        'title': title,
        'body': body,
        'category': category,
        'route': route ?? '',
        'fcmToken': await _ref.read(pushNotificationServiceProvider).getToken() ?? '',
        'data': extraData ?? {},
      };

      await _fn.createExecution(
        functionId: '6a642e3a002e300a20dd',
        body: jsonEncode(payload),
      );

      debugPrint('Push notification sent to customer $userId: $title');
    } catch (e) {
      debugPrint('Push notification error: $e');
    }
  }

  /// Kirim notifikasi ke pelanggan saat status order berubah
  Future<void> sendOrderUpdate({
    required String userId,
    required String orderId,
    required String status,
    required String courierName,
  }) async {
    String title;
    String body;
    String route = '/tracking';

    switch (status) {
      case 'accepted':
        title = 'Kurir Sedang Menuju 📍';
        body = 'Kurir $courierName sedang menuju ke lokasi penjemputan.';
        break;
      case 'picked_up':
        title = 'Barang Sudah Dijemput 🛵';
        body = 'Kurir $courierName sudah mengambil barang dan sedang dalam perjalanan.';
        break;
      case 'completed':
        title = 'Pesanan Selesai ✅';
        body = 'Pesanan Anda telah selesai dikerjakan oleh $courierName. Terima kasih!';
        break;
      case 'cancelled':
        title = 'Pesanan Dibatalkan ❌';
        body = 'Pesanan Anda telah dibatalkan.';
        break;
      default:
        title = 'Status Pesanan Diperbarui 📋';
        body = 'Pesanan #$orderId: $status';
    }

    await sendToUser(
      userId: userId,
      title: title,
      body: body,
      category: 'Pesanan',
      route: route,
      extraData: {'orderId': orderId, 'status': status},
    );
  }
}
