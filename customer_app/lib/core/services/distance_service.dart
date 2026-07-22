import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/geocode_detail.dart';

class DistanceResult {
  final double jarakKm;
  final int estimasiMenit;

  const DistanceResult({
    required this.jarakKm,
    required this.estimasiMenit,
  });
}

/// Service untuk menghitung jarak dan estimasi waktu menggunakan Mapbox API.
class DistanceService {
  final Dio _dio;

  DistanceService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.mapbox.com',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  /// Hitung jarak dari [fromLat], [fromLng] ke [toLat], [toLng].
  ///
  /// Menggunakan Mapbox Directions API.
  /// Returns [DistanceResult] berisi jarak KM dan estimasi menit.
  /// Returns null jika gagal.
  Future<DistanceResult?> hitungJarak({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      // Format: lon,lat;lon,lat
      final coordinates = '$fromLng,$fromLat;$toLng,$toLat';

      final response = await _dio.get(
        '/directions/v5/mapbox/driving/$coordinates',
        queryParameters: {
          'access_token': AppConfig.mapboxAccessToken,
          'geometries': 'geojson',
          'overview': 'false',
          'alternatives': 'false',
          'steps': 'false',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
          final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;

          return DistanceResult(
            jarakKm: distanceMeters / 1000.0,
            estimasiMenit: (durationSeconds / 60).round(),
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cari alamat detail dari koordinat (reverse geocode).
  /// Returns [GeocodeDetail] dengan komponen alamat lengkap.
  Future<GeocodeDetail?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.get(
        '/geocoding/v5/mapbox.places/$lng,$lat.json',
        queryParameters: {
          'access_token': AppConfig.mapboxAccessToken,
          'language': 'id',
          'types': 'address,poi,neighborhood,locality,place,region,country',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;

        if (features != null && features.isNotEmpty) {
          final first = features.first as Map<String, dynamic>;
          final placeName = first['place_name'] as String? ?? '';
          final context = first['context'] as List<dynamic>?;
          final address = first['address'] as String?;

          String? street, neighborhood, locality, city, region, postcode, country;

          // Parse context array untuk ambil komponen
          if (context != null) {
            for (final c in context) {
              final entry = c as Map<String, dynamic>;
              final id = entry['id'] as String? ?? '';
              final text = entry['text'] as String?;

              if (text == null) continue;

              if (id.startsWith('neighborhood')) neighborhood = text;
              else if (id.startsWith('locality')) locality = text;
              else if (id.startsWith('place')) city = text;
              else if (id.startsWith('region')) region = text;
              else if (id.startsWith('postcode')) postcode = text;
              else if (id.startsWith('country')) country = text;
            }
          }

          // Nama jalan dari place_name atau dari properti
          final placeType = first['place_type'] as List?;
          if (placeType != null && placeType.contains('address')) {
            final props = first['properties'] as Map<String, dynamic>?;
            street = props?['address'] as String? ?? first['text'] as String?;
          } else {
            street = first['text'] as String?;
          }

          return GeocodeDetail(
            fullAddress: placeName,
            houseNumber: address,
            street: street,
            neighborhood: neighborhood,
            locality: locality,
            city: city,
            region: region,
            postcode: postcode,
            country: country,
          );
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cari koordinat dari alamat (forward geocode).
  Future<({double lat, double lng})?> geocode(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final response = await _dio.get(
        '/geocoding/v5/mapbox.places/$encoded.json',
        queryParameters: {
          'access_token': AppConfig.mapboxAccessToken,
          'language': 'id',
          'limit': '1',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;

        if (features != null && features.isNotEmpty) {
          final first = features.first as Map<String, dynamic>;
          final center = first['center'] as List<dynamic>;
          if (center.length >= 2) {
            return (
              lng: (center[0] as num).toDouble(),
              lat: (center[1] as num).toDouble(),
            );
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
