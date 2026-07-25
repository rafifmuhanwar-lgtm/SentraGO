import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/appwrite_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../presentation/providers/push_notification_service.dart';

/// Service untuk memanggil Appwrite Cloud Function
/// yang mengirim push notification ke device user.
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

  /// Kirim push notification ke user tertentu
  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    String category = 'Sistem & Akun',
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

      debugPrint('Push notification sent to user $userId: $title');
    } catch (e) {
      debugPrint('Push notification error: $e');
    }
  }

  /// Kirim push notification ke semua user yang terlibat dalam order
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
      case 'ongoing':
        title = 'Pesanan Sedang Diproses 📦';
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

  /// Kirim notifikasi setelah top up berhasil
  Future<void> sendTopUpSuccess({
    required String userId,
    required double amount,
  }) async {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

    await sendToUser(
      userId: userId,
      title: 'Top Up SentraPay Berhasil 💳',
      body: 'Saldo SentraPay Wallet Anda bertambah sebesar Rp $formatted.',
      category: 'Sistem & Akun',
      route: '/profile/payment',
    );
  }

  /// Kirim notifikasi promo
  Future<void> sendPromo({
    required String userId,
    required String promoTitle,
    required String promoDescription,
  }) async {
    await sendToUser(
      userId: userId,
      title: promoTitle,
      body: promoDescription,
      category: 'Promo & Info',
    );
  }
}