class GeocodeDetail {
  final String fullAddress;
  final String? street;
  final String? houseNumber;
  final String? neighborhood;
  final String? locality;
  final String? city;
  final String? region;
  final String? postcode;
  final String? country;

  GeocodeDetail({
    required this.fullAddress,
    this.street,
    this.houseNumber,
    this.neighborhood,
    this.locality,
    this.city,
    this.region,
    this.postcode,
    this.country,
  });

  factory GeocodeDetail.fromMapbox(Map<String, dynamic> json) {
    final context = json['context'] as List<dynamic>? ?? [];
    String? street, houseNumber, neighborhood, locality, city, region, postcode, country;

    for (final entry in context) {
      final map = entry as Map<String, dynamic>;
      final id = map['id'] as String? ?? '';
      final text = map['text'] as String? ?? '';
      if (id.startsWith('street')) street = text;
      if (id.startsWith('address')) houseNumber = text;
      if (id.startsWith('neighborhood')) neighborhood = text;
      if (id.startsWith('locality')) locality = text;
      if (id.startsWith('place')) city = text;
      if (id.startsWith('region')) region = text;
      if (id.startsWith('postcode')) postcode = text;
      if (id.startsWith('country')) country = text;
    }

    return GeocodeDetail(
      fullAddress: json['place_name'] as String? ?? '',
      street: street,
      houseNumber: houseNumber,
      neighborhood: neighborhood,
      locality: locality,
      city: city,
      region: region,
      postcode: postcode,
      country: country,
    );
  }

  List<String> get displayLines {
    final lines = <String>[];
    if (street != null && houseNumber != null) {
      lines.add('$street No. $houseNumber');
    } else if (street != null) {
      lines.add(street!);
    }
    if (neighborhood != null) lines.add(neighborhood!);
    if (city != null) lines.add(city!);
    return lines;
  }

  String get shortAddress {
    final parts = [street, neighborhood, city].where((e) => e != null).toList();
    return parts.isNotEmpty ? parts.join(', ') : fullAddress;
  }
}
