enum TopUpStatus { pending, success, failed }

class TopUpTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String paymentMethod; // 'qris', 'bni_va', 'bri_va', etc
  final String? pakasirOrderId; // order_id sent to Pakasir
  final TopUpStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;

  const TopUpTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    this.pakasirOrderId,
    this.status = TopUpStatus.pending,
    required this.createdAt,
    this.completedAt,
  });

  TopUpTransactionModel copyWith({
    String? id,
    String? userId,
    double? amount,
    String? paymentMethod,
    String? pakasirOrderId,
    TopUpStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return TopUpTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      pakasirOrderId: pakasirOrderId ?? this.pakasirOrderId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory TopUpTransactionModel.fromJson(Map<String, dynamic> json) {
    return TopUpTransactionModel(
      id: json['\$id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] ?? '',
      pakasirOrderId: json['pakasirOrderId'],
      status: TopUpStatus.values.firstWhere(
        (e) => e.toString() == 'TopUpStatus.${json['status']}',
        orElse: () => TopUpStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'pakasirOrderId': pakasirOrderId,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
