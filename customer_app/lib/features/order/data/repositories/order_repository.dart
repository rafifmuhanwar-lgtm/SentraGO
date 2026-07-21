import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/order_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

class OrderRepository {
  final List<OrderModel> _mockOrders = [
    OrderModel(
      id: 'Jastip #1024',
      serviceName: 'Jastip SentraGO',
      title: 'Sate Ayam H. Mamat',
      description: '10 tusuk sate ayam + lontong + kerupuk. Catatan: bumbu kacang dipisah & jangan pedas.',
      status: OrderStatus.ongoing,
      statusText: 'Sedang Dibelikan Kurir',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      totalAmount: 35000,
      courierName: 'Budi',
      courierPhone: '081234567890',
      courierAvatar: 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=150',
      pickupAddress: 'Restoran Sate H. Mamat, Blok A No. 12',
      deliveryAddress: 'Jl. Sudirman No. 45, Apartemen Sentra Tower Lt. 12',
      chatRoomId: 'room_1',
    ),
    OrderModel(
      id: 'Sentra Ride #0842',
      serviceName: 'Sentra Ride',
      title: 'Antar ke Mall Sentra City',
      description: 'Ojek dari Stasiun MRT Sentra menuju Lobi Utama Mall Sentra City.',
      status: OrderStatus.ongoing,
      statusText: 'Kurir Menuju Lokasi Jemput',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      totalAmount: 18000,
      courierName: 'Siti',
      courierPhone: '081987654321',
      courierAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      pickupAddress: 'Stasiun MRT Sentra Pintu B',
      deliveryAddress: 'Lobi Utama Mall Sentra City',
      chatRoomId: 'room_2',
    ),
    OrderModel(
      id: 'Sentra Food #0719',
      serviceName: 'Sentra Food',
      title: 'Ayam Geprek Sambal Matah',
      description: '2x Paket Ayam Geprek + Nasi + Es Teh Manis.',
      status: OrderStatus.completed,
      statusText: 'Selesai Diantar',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      totalAmount: 54000,
      courierName: 'Rizky',
      courierPhone: '081345678912',
      courierAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      pickupAddress: 'Warung Geprek Nusantara',
      deliveryAddress: 'Jl. Sudirman No. 45, Apartemen Sentra Tower Lt. 12',
      chatRoomId: 'room_3',
    ),
    OrderModel(
      id: 'Jastip #0550',
      serviceName: 'Jastip SentraGO',
      title: 'Obat Apotek & Kebutuhan Darurat',
      description: 'Paracetamol 500mg (2 strip) & Madu Murni 250ml.',
      status: OrderStatus.completed,
      statusText: 'Selesai Diantar',
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      totalAmount: 62000,
      courierName: 'Budi',
      courierPhone: '081234567890',
      courierAvatar: 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=150',
      pickupAddress: 'Apotek Kimia Sehat Sentra',
      deliveryAddress: 'Jl. Sudirman No. 45, Apartemen Sentra Tower Lt. 12',
      chatRoomId: 'room_1',
    ),
    OrderModel(
      id: 'Sentra Ride #0412',
      serviceName: 'Sentra Ride',
      title: 'Antar ke Kantor Pusat',
      description: 'Ojek ke Gedung Menara Sentra.',
      status: OrderStatus.cancelled,
      statusText: 'Dibatalkan Pengguna',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      totalAmount: 22000,
      courierName: 'Siti',
      courierPhone: '081987654321',
      courierAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      pickupAddress: 'Jl. Sudirman No. 45',
      deliveryAddress: 'Gedung Menara Sentra Lt. 8',
      chatRoomId: 'room_2',
    ),
  ];

  Future<List<OrderModel>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockOrders;
  }

  Future<OrderModel?> getOrderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockOrders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<OrderModel> addOrder(OrderModel newOrder) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockOrders.insert(0, newOrder);
    return newOrder;
  }
}
