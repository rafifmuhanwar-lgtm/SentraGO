enum OrderStatus { ongoing, completed, cancelled }

class OrderModel {
  final String id;
  final String userId;
  final String type; // 'jastip' atau 'suruh'
  final String title;
  final String description;
  final String pickupAddress;
  final String deliveryAddress;
  final OrderStatus status;
  final String courierName;
  final double danaBelanja;
  final double ongkir;
  final double biayaLayanan;
  final double totalAmount;
  final DateTime createdAt;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final double? courierLat;
  final double? courierLng;
  final String statusText;
  final DateTime? updatedAt;
  final String? strukImageUrl;
  final String? deliveryProofUrl;
  final double? totalBelanjaStruk;
  final double? refundCustomer;
  final String kebijakanLebih;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.status,
    required this.courierName,
    this.danaBelanja = 0,
    this.ongkir = 0,
    this.biayaLayanan = 0,
    this.totalAmount = 0,
    required this.createdAt,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.courierLat,
    this.courierLng,
    this.statusText = '',
    this.updatedAt,
    this.strukImageUrl,
    this.deliveryProofUrl,
    this.totalBelanjaStruk,
    this.refundCustomer,
    this.kebijakanLebih = 'jangan_lebih',
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['\$id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? json['orderType'] ?? 'jastip',
      title: json['title'] ?? json['item'] ?? '',
      description: json['description'] ?? json['notes'] ?? '',
      pickupAddress: json['pickupAddress'] ?? json['pickupLocation'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? json['dropoffLocation'] ?? '',
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
        orElse: () => OrderStatus.ongoing,
      ),
      courierName: json['courierName'] ?? json['courierId'] ?? '',
      danaBelanja: (json['danaBelanja'] ?? json['budget'] ?? 0).toDouble(),
      ongkir: (json['ongkir'] as num?)?.toDouble() ?? 0,
      biayaLayanan: (json['biayaLayanan'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] ?? json['totalPrice'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      pickupLat: (json['pickupLat'] as num?)?.toDouble(),
      pickupLng: (json['pickupLng'] as num?)?.toDouble(),
      dropoffLat: (json['dropoffLat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoffLng'] as num?)?.toDouble(),
      courierLat: (json['courierLat'] as num?)?.toDouble(),
      courierLng: (json['courierLng'] as num?)?.toDouble(),
      statusText: json['statusText'] ?? '',
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      strukImageUrl: json['strukImageUrl'],
      deliveryProofUrl: json['deliveryProofUrl'],
      totalBelanjaStruk: (json['totalBelanjaStruk'] as num?)?.toDouble(),
      refundCustomer: (json['refundCustomer'] as num?)?.toDouble(),
      kebijakanLebih: json['kebijakanLebih'] ?? 'jangan_lebih',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'status': status.toString().split('.').last,
      'courierName': courierName,
      'danaBelanja': danaBelanja,
      'ongkir': ongkir,
      'biayaLayanan': biayaLayanan,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'courierLat': courierLat,
      'courierLng': courierLng,
      'statusText': statusText,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (strukImageUrl != null) 'strukImageUrl': strukImageUrl,
      if (deliveryProofUrl != null) 'deliveryProofUrl': deliveryProofUrl,
      if (totalBelanjaStruk != null) 'totalBelanjaStruk': totalBelanjaStruk,
      if (refundCustomer != null) 'refundCustomer': refundCustomer,
      'kebijakanLebih': kebijakanLebih,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? description,
    String? pickupAddress,
    String? deliveryAddress,
    OrderStatus? status,
    String? courierName,
    double? danaBelanja,
    double? ongkir,
    double? biayaLayanan,
    double? totalAmount,
    DateTime? createdAt,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    double? courierLat,
    double? courierLng,
    String? statusText,
    DateTime? updatedAt,
    String? strukImageUrl,
    String? deliveryProofUrl,
    double? totalBelanjaStruk,
    double? refundCustomer,
    String? kebijakanLebih,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      courierName: courierName ?? this.courierName,
      danaBelanja: danaBelanja ?? this.danaBelanja,
      ongkir: ongkir ?? this.ongkir,
      biayaLayanan: biayaLayanan ?? this.biayaLayanan,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      courierLat: courierLat ?? this.courierLat,
      courierLng: courierLng ?? this.courierLng,
      statusText: statusText ?? this.statusText,
      updatedAt: updatedAt ?? this.updatedAt,
      strukImageUrl: strukImageUrl ?? this.strukImageUrl,
      deliveryProofUrl: deliveryProofUrl ?? this.deliveryProofUrl,
      totalBelanjaStruk: totalBelanjaStruk ?? this.totalBelanjaStruk,
      refundCustomer: refundCustomer ?? this.refundCustomer,
      kebijakanLebih: kebijakanLebih ?? this.kebijakanLebih,
    );
  }
}
