import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/geocode_detail.dart';

class HitungJarakResult {
  final double distanceKm;
  final int durationMinutes;

  HitungJarakResult({
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class DistanceService {
  final Dio _dio;

  DistanceService() : _dio = Dio();

  /// Hitung jarak antara dua titik koordinat menggunakan Mapbox Directions API
  Future<HitungJarakResult> hitungJarak({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/$pickupLng,$pickupLat;$dropoffLng,$dropoffLat';

    final response = await _dio.get(url, queryParameters: {
      'access_token': AppConfig.mapboxAccessToken,
      'overview': 'false',
      'alternatives': 'false',
      'steps': 'false',
    });

    final data = response.data;
    final route = data['routes'][0];
    final distanceMeters = (route['distance'] as num).toDouble();
    final durationSeconds = (route['duration'] as num).toDouble();

    return HitungJarakResult(
      distanceKm: distanceMeters / 1000,
      durationMinutes: (durationSeconds / 60).round(),
    );
  }

  /// Reverse geocode: koordinat → alamat
  Future<GeocodeDetail> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json';

    final response = await _dio.get(url, queryParameters: {
      'access_token': AppConfig.mapboxAccessToken,
      'types': 'address,place,locality,neighborhood',
      'language': 'id',
    });

    final data = response.data;
    final features = data['features'] as List<dynamic>;
    if (features.isEmpty) {
      return GeocodeDetail(fullAddress: '$lat, $lng');
    }

    return GeocodeDetail.fromMapbox(
        features.first as Map<String, dynamic>);
  }

  /// Forward geocode: alamat → koordinat
  Future<GeocodeDetail> geocode(String query) async {
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json';

    final response = await _dio.get(url, queryParameters: {
      'access_token': AppConfig.mapboxAccessToken,
      'limit': 1,
      'language': 'id',
    });

    final data = response.data;
    final features = data['features'] as List<dynamic>;
    if (features.isEmpty) {
      return GeocodeDetail(fullAddress: query);
    }

    return GeocodeDetail.fromMapbox(
        features.first as Map<String, dynamic>);
  }
}
