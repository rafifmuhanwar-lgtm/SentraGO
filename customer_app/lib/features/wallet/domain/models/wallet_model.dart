class WalletModel {
  final String userId;
  final double balance;
  final double totalTopUp;
  final double totalSpent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletModel({
    required this.userId,
    this.balance = 0,
    this.totalTopUp = 0,
    this.totalSpent = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  WalletModel copyWith({
    String? userId,
    double? balance,
    double? totalTopUp,
    double? totalSpent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalTopUp: totalTopUp ?? this.totalTopUp,
      totalSpent: totalSpent ?? this.totalSpent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: json['userId'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      totalTopUp: (json['totalTopUp'] as num?)?.toDouble() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'userId': userId,
      'balance': balance,
    };
    // Only include these if non-zero to avoid Appwrite attribute errors
    if (totalTopUp > 0) map['totalTopUp'] = totalTopUp;
    if (totalSpent > 0) map['totalSpent'] = totalSpent;
    map['createdAt'] = createdAt.toIso8601String();
    map['updatedAt'] = updatedAt.toIso8601String();
    return map;
  }
}
