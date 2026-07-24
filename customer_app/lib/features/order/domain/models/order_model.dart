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
  final String courierId;   // ← ID kurir untuk lookup ke koleksi couriers
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
  final double? courierLat;
  final double? courierLng;

  // ── Distance ──
  final double? jarakKm;
  final String? estimasiWaktu;

  // ── Escrow ──
  final String? escrowId;

  final double? totalBelanjaStruk;
  final String? strukImageUrl;
  final String? deliveryProofUrl;
  final double? refundCustomer;

  // ── Kebijakan ──
  final String kebijakanLebih; // 'jangan_lebih' atau 'boleh_lebih'

  // ── Voucher ──
  final String? voucherCode;
  final double? voucherDiscount;

  // ── Appwrite Required ──
  final String orderType; // 'jastip' atau 'suruh'
  final DateTime? updatedAt;

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
    this.courierId = '',
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
    this.deliveryProofUrl,
    this.refundCustomer,
    this.kebijakanLebih = 'jangan_lebih',
    this.voucherCode,
    this.voucherDiscount,
    this.orderType = 'jastip',
    this.updatedAt,
    this.courierLat,
    this.courierLng,
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
    String? courierId,
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
    String? deliveryProofUrl,
    double? refundCustomer,
    String? kebijakanLebih,
    String? voucherCode,
    double? voucherDiscount,
    String? orderType,
    DateTime? updatedAt,
    double? courierLat,
    double? courierLng,
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
      courierId: courierId ?? this.courierId,
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
      deliveryProofUrl: deliveryProofUrl ?? this.deliveryProofUrl,
      refundCustomer: refundCustomer ?? this.refundCustomer,
      kebijakanLebih: kebijakanLebih ?? this.kebijakanLebih,
      voucherCode: voucherCode ?? this.voucherCode,
      voucherDiscount: voucherDiscount ?? this.voucherDiscount,
      orderType: orderType ?? this.orderType,
      updatedAt: updatedAt ?? this.updatedAt,
      courierLat: courierLat ?? this.courierLat,
      courierLng: courierLng ?? this.courierLng,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    double? _parseDouble(dynamic value) => (value as num?)?.toDouble();

    return OrderModel(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      serviceName: json['serviceName'] ?? (json['type'] == 'suruh' ? 'Sentra Suruh' : 'Jastip SentraGO'),
      title: json['title'] ?? json['item'] ?? '',
      description: json['description'] ?? json['notes'] ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
        orElse: () => OrderStatus.ongoing,
      ),
      statusText: json['statusText'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      totalAmount: (json['totalAmount'] ?? json['totalPrice'] ?? 0).toDouble(),
      courierId: json['courierId'] ?? '',
      courierName: json['courierName'] ?? '',
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
      deliveryProofUrl: json['deliveryProofUrl'],
      refundCustomer: (json['refundCustomer'] as num?)?.toDouble(),
      kebijakanLebih: json['kebijakanLebih'] ?? 'jangan_lebih',
      voucherCode: json['voucherCode'] as String?,
      voucherDiscount: (json['voucherDiscount'] as num?)?.toDouble(),
      orderType: json['orderType'] ?? json['type'] ?? 'jastip',
      updatedAt: json['\$updatedAt'] != null ? DateTime.parse(json['\$updatedAt']) : null,
      courierLat: _parseDouble(json['courierLat']),
      courierLng: _parseDouble(json['courierLng']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': orderType,
      'title': title,
      'item': title, // legacy support
      'pickupLocation': pickupAddress,
      'dropoffLocation': deliveryAddress,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'budget': danaBelanja,
      'danaBelanja': danaBelanja,
      'notes': description,
      'description': description,
      'status': status.toString().split('.').last,
      'statusText': statusText,
      'courierId': courierId,
      'courierName': courierName,
      'courierPhone': courierPhone,
      'courierAvatar': courierAvatar,
      'totalPrice': totalAmount, // legacy support
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'serviceName': serviceName,
      'ongkir': ongkir,
      'biayaLayanan': biayaLayanan,
      if (voucherCode != null) 'voucherCode': voucherCode,
      if (voucherDiscount != null) 'voucherDiscount': voucherDiscount,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'jarakKm': jarakKm,
      'estimasiWaktu': estimasiWaktu,
      'chatRoomId': chatRoomId,
      'escrowId': escrowId,
      'totalBelanjaStruk': totalBelanjaStruk,
      'strukImageUrl': strukImageUrl,
      'deliveryProofUrl': deliveryProofUrl,
      'refundCustomer': refundCustomer,
      'kebijakanLebih': kebijakanLebih,
      'courierLat': courierLat,
      'courierLng': courierLng,
    };
  }
}
