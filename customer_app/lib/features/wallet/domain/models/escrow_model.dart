enum EscrowStatus { held, released, refunded }

class EscrowModel {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final EscrowStatus status;
  final String serviceType; // 'jastip' or 'suruh'
  final DateTime createdAt;
  final DateTime? releasedAt;

  // ── Pricing Breakdown ──
  final double danaBelanja;  // budget untuk belanja
  final double ongkir;       // biaya ongkir
  final double biayaLayanan; // fee platform

  const EscrowModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.serviceType,
    required this.createdAt,
    this.releasedAt,
    this.danaBelanja = 0,
    this.ongkir = 0,
    this.biayaLayanan = 0,
  });

  EscrowModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? amount,
    EscrowStatus? status,
    String? serviceType,
    DateTime? createdAt,
    DateTime? releasedAt,
    double? danaBelanja,
    double? ongkir,
    double? biayaLayanan,
  }) {
    return EscrowModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      createdAt: createdAt ?? this.createdAt,
      releasedAt: releasedAt ?? this.releasedAt,
      danaBelanja: danaBelanja ?? this.danaBelanja,
      ongkir: ongkir ?? this.ongkir,
      biayaLayanan: biayaLayanan ?? this.biayaLayanan,
    );
  }

  factory EscrowModel.fromJson(Map<String, dynamic> json) {
    return EscrowModel(
      id: json['\$id'] ?? '',
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: EscrowStatus.values.firstWhere(
        (e) => e.toString() == 'EscrowStatus.${json['status']}',
        orElse: () => EscrowStatus.held,
      ),
      serviceType: json['serviceType'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      releasedAt: json['releasedAt'] != null
          ? DateTime.parse(json['releasedAt'])
          : null,
      danaBelanja: (json['danaBelanja'] as num?)?.toDouble() ?? 0,
      ongkir: (json['ongkir'] as num?)?.toDouble() ?? 0,
      biayaLayanan: (json['biayaLayanan'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'status': status.toString().split('.').last,
      'serviceType': serviceType,
      'createdAt': createdAt.toIso8601String(),
      'releasedAt': releasedAt?.toIso8601String(),
      'danaBelanja': danaBelanja,
      'ongkir': ongkir,
      'biayaLayanan': biayaLayanan,
    };
  }
}
