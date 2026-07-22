class PickupLocationData {
  final double lat;
  final double lng;
  final String address;

  const PickupLocationData({
    required this.lat,
    required this.lng,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }

  factory PickupLocationData.fromJson(Map<String, dynamic> json) {
    return PickupLocationData(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
    );
  }
}
