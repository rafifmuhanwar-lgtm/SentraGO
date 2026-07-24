class WithdrawalModel {
  final String id;
  final String courierId;
  final double amount;
  final String bankName;
  final String accountNumber;
  final String status; // pending, approved, rejected
  final DateTime createdAt;

  WithdrawalModel({
    required this.id,
    required this.courierId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WithdrawalModel.fromJson(Map<String, dynamic> json, [String? id]) {
    final effectiveId = id ?? json['\$id'] ?? json['id'] as String? ?? '';
    return WithdrawalModel(
      id: effectiveId,
      courierId: json['courierId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      bankName: json['bankName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['\$createdAt'] != null
          ? DateTime.parse(json['\$createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courierId': courierId,
      'amount': amount,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'status': status,
    };
  }
}
