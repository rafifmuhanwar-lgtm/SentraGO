class PaymentMethodModel {
  final String id;
  final String name;
  final String type; // 'wallet', 'ewallet', 'bank', 'cash'
  final String? accountNumber;
  final double? balance;
  final bool isLinked;
  final bool isDefault;

  const PaymentMethodModel({
    required this.id,
    required this.name,
    required this.type,
    this.accountNumber,
    this.balance,
    this.isLinked = false,
    this.isDefault = false,
  });

  PaymentMethodModel copyWith({
    String? id,
    String? name,
    String? type,
    String? accountNumber,
    double? balance,
    bool? isLinked,
    bool? isDefault,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      accountNumber: accountNumber ?? this.accountNumber,
      balance: balance ?? this.balance,
      isLinked: isLinked ?? this.isLinked,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'cash',
      accountNumber: json['accountNumber'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      isLinked: json['isLinked'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'accountNumber': accountNumber,
      'balance': balance,
      'isLinked': isLinked,
      'isDefault': isDefault,
    };
  }
}
