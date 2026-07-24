import 'dart:math' as math;
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/geocode_detail.dart';

class DistanceResult {
  final double jarakKm;
  final int estimasiMenit;
  final List<({double lat, double lng})> routePoints;

  const DistanceResult({
    required this.jarakKm,
    required this.estimasiMenit,
    this.routePoints = const [],
  });
}

class GeocodeRecommendation {
  final String placeName;
  final String fullAddress;
  final double lat;
  final double lng;
  final double? distanceKm;

  const GeocodeRecommendation({
    required this.placeName,
    required this.fullAddress,
    required this.lat,
    required this.lng,
    this.distanceKm,
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
    if (AppConfig.mapboxAccessToken.isEmpty) {
      return await _osmHitungJarak(fromLat: fromLat, fromLng: fromLng, toLat: toLat, toLng: toLng);
    }
    try {
      // Format: lon,lat;lon,lat
      final coordinates = '$fromLng,$fromLat;$toLng,$toLat';

      final response = await _dio.get(
        '/directions/v5/mapbox/driving/$coordinates',
        queryParameters: {
          'access_token': AppConfig.mapboxAccessToken,
          'geometries': 'geojson',
          'overview': 'full',
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

          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>?;
          final points = <({double lat, double lng})>[];
          if (coords != null) {
            for (final pt in coords) {
              if (pt is List && pt.length >= 2) {
                points.add((lat: (pt[1] as num).toDouble(), lng: (pt[0] as num).toDouble()));
              }
            }
          }

          return DistanceResult(
            jarakKm: distanceMeters / 1000.0,
            estimasiMenit: (durationSeconds / 60).round(),
            routePoints: points,
          );
        }
      }
    } catch (_) {}
    return await _osmHitungJarak(fromLat: fromLat, fromLng: fromLng, toLat: toLat, toLng: toLng);
  }

  Future<List<({double lat, double lng})>> getRouteCoordinates({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final res = await hitungJarak(fromLat: fromLat, fromLng: fromLng, toLat: toLat, toLng: toLng);
    return res?.routePoints ?? [];
  }

  /// Cari alamat detail dari koordinat (reverse geocode).
  /// Returns [GeocodeDetail] dengan komponen alamat lengkap.
  Future<GeocodeDetail?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    if (AppConfig.mapboxAccessToken.isEmpty) {
      return await _osmReverseGeocode(lat: lat, lng: lng);
    }
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

              if (id.startsWith('neighborhood')) {
                neighborhood = text;
              } else if (id.startsWith('locality')) {
                locality = text;
              } else if (id.startsWith('place')) {
                city = text;
              } else if (id.startsWith('region')) {
                region = text;
              } else if (id.startsWith('postcode')) {
                postcode = text;
              } else if (id.startsWith('country')) {
                country = text;
              }
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
    } catch (_) {}
    return await _osmReverseGeocode(lat: lat, lng: lng);
  }

  /// Cari koordinat dari alamat (forward geocode).
  Future<({double lat, double lng})?> geocode(String query) async {
    if (AppConfig.mapboxAccessToken.isEmpty) {
      return await _osmGeocode(query);
    }
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
    } catch (_) {}
    return await _osmGeocode(query);
  }

  /// Cari rekomendasi tempat terdekat berdasarkan query dan lokasi GPS aktual
  Future<List<GeocodeRecommendation>> searchRecommendations({
    required String query,
    double? proximityLat,
    double? proximityLng,
  }) async {
    if (query.trim().isEmpty) return [];
    if (AppConfig.mapboxAccessToken.isEmpty) {
      return await _osmSearchRecommendations(
        query: query,
        proximityLat: proximityLat,
        proximityLng: proximityLng,
      );
    }
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final queryParams = <String, dynamic>{
        'access_token': AppConfig.mapboxAccessToken,
        'language': 'id',
        'limit': '6',
        'country': 'id',
      };

      if (proximityLat != null && proximityLng != null) {
        queryParams['proximity'] = '$proximityLng,$proximityLat';
      }

      final response = await _dio.get(
        '/geocoding/v5/mapbox.places/$encoded.json',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>?;

        if (features != null && features.isNotEmpty) {
          final results = <GeocodeRecommendation>[];
          for (final feature in features) {
            final map = feature as Map<String, dynamic>;
            final text = map['text'] as String? ?? '';
            final placeName = map['place_name'] as String? ?? text;
            final center = map['center'] as List<dynamic>?;

            if (center != null && center.length >= 2) {
              final lng = (center[0] as num).toDouble();
              final lat = (center[1] as num).toDouble();

              double? distKm;
              if (proximityLat != null && proximityLng != null) {
                distKm = _calculateDistanceKm(proximityLat, proximityLng, lat, lng);
              }

              results.add(GeocodeRecommendation(
                placeName: text.isNotEmpty ? text : placeName,
                fullAddress: placeName,
                lat: lat,
                lng: lng,
                distanceKm: distKm,
              ));
            }
          }

          // Urutkan dari yang terdekat
          if (proximityLat != null && proximityLng != null) {
            results.sort((a, b) => (a.distanceKm ?? 999999).compareTo(b.distanceKm ?? 999999));
          }

          return results;
        }
      }
    } catch (_) {}
    return await _osmSearchRecommendations(
      query: query,
      proximityLat: proximityLat,
      proximityLng: proximityLng,
    );
  }

  // ── OpenStreetMap Nominatim & OSRM Fallback Helpers ──

  Future<DistanceResult?> _osmHitungJarak({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final coordinates = '$fromLng,$fromLat;$toLng,$toLat';
      final response = await _dio.get(
        'https://router.project-osrm.org/route/v1/driving/$coordinates',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );
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
                points.add((lat: (pt[1] as num).toDouble(), lng: (pt[0] as num).toDouble()));
              }
            }
          }

          return DistanceResult(
            jarakKm: distanceMeters / 1000.0,
            estimasiMenit: (durationSeconds / 60).round(),
            routePoints: points,
          );
        }
      }
    } catch (_) {}
    // Fallback ke rumus Haversine jika OSRM gagal
    final distKm = _calculateDistanceKm(fromLat, fromLng, toLat, toLng);
    return DistanceResult(
      jarakKm: distKm,
      estimasiMenit: (distKm / 25.0 * 60).round() < 1 ? 1 : (distKm / 25.0 * 60).round(),
      routePoints: [
        (lat: fromLat, lng: fromLng),
        (lat: toLat, lng: toLng),
      ],
    );
  }

  Future<GeocodeDetail?> _osmReverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'zoom': 18,
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'com.sentra.customer_app'}),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final displayName = data['display_name'] as String? ?? '';
        final address = data['address'] as Map<String, dynamic>?;
        if (displayName.isNotEmpty && address != null) {
          final street = address['road'] as String? ?? address['suburb'] as String? ?? displayName.split(',').first;
          return GeocodeDetail(
            fullAddress: displayName,
            houseNumber: address['house_number'] as String?,
            street: street,
            neighborhood: address['neighbourhood'] as String? ?? address['suburb'] as String?,
            locality: address['village'] as String? ?? address['town'] as String?,
            city: address['city'] as String? ?? address['county'] as String?,
            region: address['state'] as String?,
            postcode: address['postcode'] as String?,
            country: address['country'] as String?,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  Future<({double lat, double lng})?> _osmGeocode(String query) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'format': 'json',
          'q': query,
          'countrycodes': 'id',
          'limit': 1,
        },
        options: Options(headers: {'User-Agent': 'com.sentra.customer_app'}),
      );
      if (response.statusCode == 200 && response.data is List && (response.data as List).isNotEmpty) {
        final first = (response.data as List).first as Map<String, dynamic>;
        final lat = double.tryParse(first['lat']?.toString() ?? '');
        final lon = double.tryParse(first['lon']?.toString() ?? '');
        if (lat != null && lon != null) {
          return (lat: lat, lng: lon);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<GeocodeRecommendation>> _osmSearchRecommendations({
    required String query,
    double? proximityLat,
    double? proximityLng,
  }) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'format': 'json',
          'q': query,
          'countrycodes': 'id',
          'limit': 8,
          'addressdetails': 1,
        },
        options: Options(headers: {'User-Agent': 'com.sentra.customer_app'}),
      );
      if (response.statusCode == 200 && response.data is List) {
        final results = <GeocodeRecommendation>[];
        for (final item in response.data as List) {
          final map = item as Map<String, dynamic>;
          final lat = double.tryParse(map['lat']?.toString() ?? '');
          final lon = double.tryParse(map['lon']?.toString() ?? '');
          final displayName = map['display_name'] as String? ?? '';
          final name = map['name'] as String? ?? displayName.split(',').first;
          if (lat != null && lon != null && displayName.isNotEmpty) {
            double? distKm;
            if (proximityLat != null && proximityLng != null) {
              distKm = _calculateDistanceKm(proximityLat, proximityLng, lat, lon);
            }
            results.add(GeocodeRecommendation(
              placeName: name.isNotEmpty ? name : displayName.split(',').first,
              fullAddress: displayName,
              lat: lat,
              lng: lon,
              distanceKm: distKm,
            ));
          }
        }
        if (proximityLat != null && proximityLng != null) {
          results.sort((a, b) => (a.distanceKm ?? 999999).compareTo(b.distanceKm ?? 999999));
        }
        return results;
      }
    } catch (_) {}
    return [];
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) * math.cos(lat2 * (math.pi / 180.0)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}
