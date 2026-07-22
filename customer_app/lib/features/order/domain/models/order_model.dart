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
  final String userId;

  // ── Pricing Breakdown ──
  final double danaBelanja;        // budget belanja (dari customer)
  final double ongkir;             // ongkir hasil perhitungan jarak
  final double biayaLayanan;       // fee platform

  // ── Coordinates ──
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  // ── Distance ──
  final double? jarakKm;
  final String? estimasiWaktu;

  // ── Escrow ──
  final String? escrowId;

  // ── Receipt / Completion ──
  final double? totalBelanjaStruk;
  final String? strukImageUrl;
  final double? refundCustomer;

  // ── Kebijakan ──
  final String kebijakanLebih; // 'jangan_lebih' atau 'boleh_lebih'

  // ── Appwrite Required ──
  final String orderType; // 'jastip' atau 'suruh'

  const OrderModel({
    required this.id,
    required this.userId,
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
    this.danaBelanja = 0,
    this.ongkir = 0,
    this.biayaLayanan = 0,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.jarakKm,
    this.estimasiWaktu,
    this.escrowId,
    this.totalBelanjaStruk,
    this.strukImageUrl,
    this.refundCustomer,
    this.kebijakanLebih = 'jangan_lebih',
    this.orderType = 'jastip',
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
    String? userId,
    double? danaBelanja,
    double? ongkir,
    double? biayaLayanan,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    double? jarakKm,
    String? estimasiWaktu,
    String? escrowId,
    double? totalBelanjaStruk,
    String? strukImageUrl,
    double? refundCustomer,
    String? kebijakanLebih,
    String? orderType,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      danaBelanja: danaBelanja ?? this.danaBelanja,
      ongkir: ongkir ?? this.ongkir,
      biayaLayanan: biayaLayanan ?? this.biayaLayanan,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      jarakKm: jarakKm ?? this.jarakKm,
      estimasiWaktu: estimasiWaktu ?? this.estimasiWaktu,
      escrowId: escrowId ?? this.escrowId,
      totalBelanjaStruk: totalBelanjaStruk ?? this.totalBelanjaStruk,
      strukImageUrl: strukImageUrl ?? this.strukImageUrl,
      refundCustomer: refundCustomer ?? this.refundCustomer,
      kebijakanLebih: kebijakanLebih ?? this.kebijakanLebih,
      orderType: orderType ?? this.orderType,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      serviceName: json['serviceName'] ?? json['type'] == 'suruh' ? 'Sentra Suruh' : 'Jastip SentraGO',
      title: json['title'] ?? json['item'] ?? '',
      description: json['description'] ?? json['notes'] ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
        orElse: () => OrderStatus.ongoing,
      ),
      statusText: json['statusText'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      totalAmount: (json['totalAmount'] ?? json['totalPrice'] ?? 0).toDouble(),
      courierName: json['courierName'] ?? json['courierId'] ?? '',
      courierPhone: json['courierPhone'] ?? '',
      courierAvatar: json['courierAvatar'] ?? '',
      pickupAddress: json['pickupAddress'] ?? json['pickupLocation'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? json['dropoffLocation'] ?? '',
      chatRoomId: json['chatRoomId'],
      danaBelanja: (json['danaBelanja'] ?? json['budget'] ?? 0).toDouble(),
      ongkir: (json['ongkir'] as num?)?.toDouble() ?? 0,
      biayaLayanan: (json['biayaLayanan'] as num?)?.toDouble() ?? 0,
      pickupLat: (json['pickupLat'] as num?)?.toDouble(),
      pickupLng: (json['pickupLng'] as num?)?.toDouble(),
      dropoffLat: (json['dropoffLat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoffLng'] as num?)?.toDouble(),
      jarakKm: (json['jarakKm'] as num?)?.toDouble(),
      estimasiWaktu: json['estimasiWaktu'],
      escrowId: json['escrowId'],
      totalBelanjaStruk: (json['totalBelanjaStruk'] as num?)?.toDouble(),
      strukImageUrl: json['strukImageUrl'],
      refundCustomer: (json['refundCustomer'] as num?)?.toDouble(),
      kebijakanLebih: json['kebijakanLebih'] ?? 'jangan_lebih',
      orderType: json['orderType'] ?? json['type'] ?? 'jastip',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': orderType,
      'title': title,
      'item': title,
      'pickupLocation': pickupAddress,
      'dropoffLocation': deliveryAddress,
      'budget': danaBelanja,
      'notes': description,
      'status': status.toString().split('.').last,
      'courierId': courierName,
      'totalPrice': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'serviceName': serviceName,
      'totalAmount': totalAmount,
      'ongkir': ongkir,
      'biayaLayanan': biayaLayanan,
    };
  }
}
