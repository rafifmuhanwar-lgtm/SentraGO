enum OrderStatus { ongoing, completed, cancelled }

class OrderModel {
  final String id;
  final String serviceName;
  final String title;
  final String description;
  final OrderStatus status;
  final String statusText;
  final DateTime createdAt;
  final double totalAmount;
  final String courierName;
  final String courierPhone;
  final String courierAvatar;
  final String pickupAddress;
  final String deliveryAddress;
  final String? chatRoomId;

  const OrderModel({
    required this.id,
    required this.serviceName,
    required this.title,
    required this.description,
    required this.status,
    required this.statusText,
    required this.createdAt,
    required this.totalAmount,
    required this.courierName,
    required this.courierPhone,
    required this.courierAvatar,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.chatRoomId,
  });

  OrderModel copyWith({
    String? id,
    String? serviceName,
    String? title,
    String? description,
    OrderStatus? status,
    String? statusText,
    DateTime? createdAt,
    double? totalAmount,
    String? courierName,
    String? courierPhone,
    String? courierAvatar,
    String? pickupAddress,
    String? deliveryAddress,
    String? chatRoomId,
  }) {
    return OrderModel(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      statusText: statusText ?? this.statusText,
      createdAt: createdAt ?? this.createdAt,
      totalAmount: totalAmount ?? this.totalAmount,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      courierAvatar: courierAvatar ?? this.courierAvatar,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      chatRoomId: chatRoomId ?? this.chatRoomId,
    );
  }
}
