class AddressModel {
  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String fullAddress;
  final String? details;
  final bool isPrimary;

  const AddressModel({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.fullAddress,
    this.details,
    this.isPrimary = false,
  });

  AddressModel copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phone,
    String? fullAddress,
    String? details,
    bool? isPrimary,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      fullAddress: fullAddress ?? this.fullAddress,
      details: details ?? this.details,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Rumah',
      recipientName: json['recipientName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fullAddress: json['fullAddress'] as String? ?? '',
      details: json['details'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'recipientName': recipientName,
      'phone': phone,
      'fullAddress': fullAddress,
      'details': details,
      'isPrimary': isPrimary,
    };
  }
}
