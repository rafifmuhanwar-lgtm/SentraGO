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

  const GeocodeDetail({
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

  /// Untuk ditampilkan di UI — tiap baris komponen alamat.
  List<String> get displayLines {
    final lines = <String>[];

    // Baris 1: nomor + nama jalan
    final jalan = <String>[];
    if (houseNumber != null && houseNumber!.isNotEmpty) jalan.add(houseNumber!);
    if (street != null && street!.isNotEmpty) jalan.add(street!);
    if (jalan.isNotEmpty) lines.add(jalan.join(' '));

    // Baris 2: kelurahan (kalau beda sama jalan)
    if (neighborhood != null &&
        neighborhood!.isNotEmpty &&
        neighborhood != street) {
      lines.add(neighborhood!);
    }

    // Baris 3: kecamatan
    if (locality != null && locality!.isNotEmpty) {
      lines.add(locality!);
    }

    // Baris 4: kota, provinsi
    final kotaProv = <String>[];
    if (city != null && city!.isNotEmpty) kotaProv.add(city!);
    if (region != null && region!.isNotEmpty) kotaProv.add(region!);
    if (kotaProv.isNotEmpty) lines.add(kotaProv.join(', '));

    // Baris 5: kode pos
    if (postcode != null && postcode!.isNotEmpty) lines.add(postcode!);

    return lines;
  }

  /// Satu baris pendek buat preview di form/lokasi tile.
  String get shortAddress {
    final parts = [street, locality ?? city].where((s) => s != null && s.isNotEmpty);
    return parts.isNotEmpty ? parts.join(', ') : fullAddress;
  }
}
