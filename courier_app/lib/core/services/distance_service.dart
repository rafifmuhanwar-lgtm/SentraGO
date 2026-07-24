import 'dart:math' as math;
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/geocode_detail.dart';

class HitungJarakResult {
  final double distanceKm;
  final int durationMinutes;
  final List<({double lat, double lng})> routePoints;

  HitungJarakResult({
    required this.distanceKm,
    required this.durationMinutes,
    this.routePoints = const [],
  });
}

/// Mapping tipe kendaraan ke profil Mapbox Directions API dan exclude params.
class _VehicleProfile {
  final String profile;
  final String? exclude;

  const _VehicleProfile({required this.profile, this.exclude});
}

_VehicleProfile _getVehicleProfile(String? vehicleType) {
  final type = vehicleType?.toLowerCase().trim() ?? '';
  if (type == 'motor' || type == 'motorcycle' || type == 'sepeda motor') {
    // Motor: hindari tol dan jalan bebas hambatan
    return const _VehicleProfile(profile: 'driving', exclude: 'toll,motorway');
  } else if (type == 'sepeda' || type == 'bicycle' || type == 'bike') {
    return const _VehicleProfile(profile: 'cycling');
  } else if (type == 'jalan kaki' || type == 'walking' || type == 'pedestrian') {
    return const _VehicleProfile(profile: 'walking');
  }
  // Default: mobil / truck / van — rute normal
  return const _VehicleProfile(profile: 'driving');
}

class DistanceService {
  final Dio _dio;

  DistanceService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  /// Hitung jarak antara dua titik koordinat menggunakan Mapbox Directions API.
  ///
  /// [vehicleType] — tipe kendaraan kurir ('motor', 'mobil', 'sepeda', 'jalan kaki').
  /// Jika null/kosong, default ke rute mobil.
  Future<HitungJarakResult> hitungJarak({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? vehicleType,
  }) async {
    final vp = _getVehicleProfile(vehicleType);
    final coordinates = '$pickupLng,$pickupLat;$dropoffLng,$dropoffLat';
    final url =
        'https://api.mapbox.com/directions/v5/mapbox/${vp.profile}/$coordinates';

    try {
      final queryParams = <String, dynamic>{
        'access_token': AppConfig.mapboxAccessToken,
        'overview': 'full',
        'geometries': 'geojson',
        'alternatives': 'false',
        'steps': 'false',
      };
      if (vp.exclude != null) {
        queryParams['exclude'] = vp.exclude;
      }

      final response = await _dio.get(url, queryParameters: queryParams);

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
          final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0;

          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>?;
          final points = <({double lat, double lng})>[];
          if (coords != null) {
            for (final pt in coords) {
              if (pt is List && pt.length >= 2) {
                points.add((
                  lat: (pt[1] as num).toDouble(),
                  lng: (pt[0] as num).toDouble(),
                ));
              }
            }
          }

          return HitungJarakResult(
            distanceKm: distanceMeters / 1000,
            durationMinutes: (durationSeconds / 60).round(),
            routePoints: points,
          );
        }
      }
    } catch (_) {}

    // Fallback ke Haversine jika API gagal
    return _fallbackResult(pickupLat, pickupLng, dropoffLat, dropoffLng);
  }

  /// Ambil polyline koordinat rute sesuai kendaraan.
  Future<List<({double lat, double lng})>> getRouteCoordinates({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String? vehicleType,
  }) async {
    final result = await hitungJarak(
      pickupLat: fromLat,
      pickupLng: fromLng,
      dropoffLat: toLat,
      dropoffLng: toLng,
      vehicleType: vehicleType,
    );
    return result.routePoints;
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

    return GeocodeDetail.fromMapbox(features.first as Map<String, dynamic>);
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

    return GeocodeDetail.fromMapbox(features.first as Map<String, dynamic>);
  }

  HitungJarakResult _fallbackResult(
      double fromLat, double fromLng, double toLat, double toLng) {
    final distKm = _calculateDistanceKm(fromLat, fromLng, toLat, toLng);
    return HitungJarakResult(
      distanceKm: distKm,
      durationMinutes: (distKm / 25.0 * 60).round().clamp(1, 999),
      routePoints: [
        (lat: fromLat, lng: fromLng),
        (lat: toLat, lng: toLng),
      ],
    );
  }

  double _calculateDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}
