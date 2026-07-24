class CourierModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? vehicleType;
  final String? vehiclePlate;
  final String? selectedArea;
  final bool isOnline;
  final bool isActive;
  final bool kycVerified;
  final DateTime createdAt;

  CourierModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.vehicleType,
    this.vehiclePlate,
    this.selectedArea,
    this.isOnline = false,
    this.isActive = true,
    this.kycVerified = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CourierModel.fromJson(Map<String, dynamic> json, [String? id]) {
    final effectiveId = id ?? json['\$id'] ?? json['id'] as String? ?? '';
    return CourierModel(
      id: effectiveId,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      photoUrl: json['photoUrl'] as String?,
      vehicleType: json['vehicleType'] as String?,
      vehiclePlate: json['vehiclePlate'] as String?,
      selectedArea: json['selectedArea'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      kycVerified: json['kycVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone ?? '',
      'photoUrl': photoUrl,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'selectedArea': selectedArea,
      'isOnline': isOnline,
      'isActive': isActive,
      'kycVerified': kycVerified,
      // 'createdAt': createdAt.toIso8601String(), // Appwrite otomatis menggunakan $createdAt
      'role': 'courier',
    };
  }

  /// Hanya field dasar yang pasti ada di collection 'users'
  Map<String, dynamic> toJsonBasic() {
    return {
      'name': name,
      'email': email,
      'phone': phone ?? '',
      'photoUrl': photoUrl,
    };
  }

  /// Hanya field yang tidak null — digunakan saat update dokumen existing
  /// agar tidak menimpa data profil yang sudah ada (vehicleType, selectedArea, kycVerified)
  Map<String, dynamic> toJsonNonNull() {
    final map = <String, dynamic>{
      'name': name,
      'role': 'courier',
    };
    if (email != null) map['email'] = email;
    if (phone != null && phone!.isNotEmpty) map['phone'] = phone;
    if (photoUrl != null) map['photoUrl'] = photoUrl;
    if (vehicleType != null) map['vehicleType'] = vehicleType;
    if (vehiclePlate != null) map['vehiclePlate'] = vehiclePlate;
    if (selectedArea != null) map['selectedArea'] = selectedArea;
    map['isOnline'] = isOnline;
    map['isActive'] = isActive;
    map['kycVerified'] = kycVerified;
    return map;
  }

  CourierModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? vehicleType,
    String? vehiclePlate,
    String? selectedArea,
    bool? isOnline,
    bool? isActive,
    bool? kycVerified,
    DateTime? createdAt,
  }) {
    return CourierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      selectedArea: selectedArea ?? this.selectedArea,
      isOnline: isOnline ?? this.isOnline,
      isActive: isActive ?? this.isActive,
      kycVerified: kycVerified ?? this.kycVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
