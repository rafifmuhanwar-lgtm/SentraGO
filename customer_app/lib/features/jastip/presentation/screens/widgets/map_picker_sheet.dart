import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/config/app_config.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/services/distance_service.dart';
import '../../../../../core/models/geocode_detail.dart';
import '../../../../jastip/domain/models/pickup_location_data.dart';

class MapPickerSheet extends StatefulWidget {
  final String title;
  final double? initialLat;
  final double? initialLng;

  const MapPickerSheet({
    super.key,
    this.title = 'Pilih Lokasi',
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<MapPickerSheet> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  final _distanceService = DistanceService();

  bool _isGeocoding = false;
  bool _isLocating = true;
  LatLng _currentPosition = const LatLng(-6.200000, 106.816666);
  GeocodeDetail? _currentGeocode;
  String? _geocodeError;
  List<GeocodeRecommendation> _recommendations = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentPosition = LatLng(widget.initialLat!, widget.initialLng!);
      _isLocating = false;
      _reverseGeocode(_currentPosition);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        _fallbackToDefault('GPS belum aktif');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _fallbackToDefault('Izin lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _fallbackToDefault('Izin lokasi ditolak permanen');
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        // Gunakan lastKnownPosition jika getCurrentPosition timeout
      }

      if (!mounted) return;

      if (position != null) {
        final newPos = LatLng(position.latitude, position.longitude);
        _currentPosition = newPos;
        _mapController.move(newPos, 16.0);
        _reverseGeocode(newPos);
      } else {
        _fallbackToDefault('GPS tidak merespons (misal saat dijalankan di PC / Simulator tanpa sensor GPS)');
      }
    } catch (e) {
      if (!mounted) return;
      _fallbackToDefault('Gagal membaca koordinat GPS');
    }

    if (mounted) setState(() => _isLocating = false);
  }

  void _fallbackToDefault(String reason) {
    _isLocating = false;
    if (mounted && reason.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$reason. Silakan pilih titik di peta atau masukkan di pencarian.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    // Jika belum pernah ada koordinat awal dan posisi masih di default Monas, baru gunakan Monas
    if (_currentPosition.latitude == -6.200000 && _currentPosition.longitude == 106.816666 && widget.initialLat == null) {
      _currentPosition = const LatLng(-6.200000, 106.816666);
    }
    _reverseGeocode(_currentPosition);
  }

  Future<void> _reverseGeocode(LatLng position) async {
    setState(() {
      _isGeocoding = true;
      _geocodeError = null;
    });

    try {
      final address = await _distanceService.reverseGeocode(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentGeocode = address;
        _isGeocoding = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeocoding = false;
        _geocodeError = 'Gagal memuat alamat';
        _currentGeocode = GeocodeDetail(
          fullAddress: '${_currentPosition.latitude.toStringAsFixed(6)}, ${_currentPosition.longitude.toStringAsFixed(6)}',
        );
      });
    }
  }

  Future<void> _onSearchTextChanged(String query) async {
    if (query.trim().isEmpty) {
      if (_recommendations.isNotEmpty || _isLoadingRecommendations) {
        setState(() {
          _recommendations = [];
          _isLoadingRecommendations = false;
        });
      }
      return;
    }

    setState(() => _isLoadingRecommendations = true);

    final results = await _distanceService.searchRecommendations(
      query: query,
      proximityLat: _currentPosition.latitude,
      proximityLng: _currentPosition.longitude,
    );

    if (!mounted) return;
    setState(() {
      _recommendations = results;
      _isLoadingRecommendations = false;
    });
  }

  void _selectRecommendation(GeocodeRecommendation rec) {
    final newPos = LatLng(rec.lat, rec.lng);
    setState(() {
      _searchController.text = rec.placeName;
      _recommendations = [];
      _isLoadingRecommendations = false;
      _currentPosition = newPos;
      _isGeocoding = true;
      _geocodeError = null;
    });
    _mapController.move(newPos, 16.0);
    _reverseGeocode(newPos);
    FocusScope.of(context).unfocus();
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    if (_recommendations.isNotEmpty) {
      _selectRecommendation(_recommendations.first);
      return;
    }

    setState(() {
      _isGeocoding = true;
      _geocodeError = null;
      _isLoadingRecommendations = true;
    });

    try {
      final recs = await _distanceService.searchRecommendations(
        query: query,
        proximityLat: _currentPosition.latitude,
        proximityLng: _currentPosition.longitude,
      );

      if (!mounted) return;

      if (recs.isNotEmpty) {
        _selectRecommendation(recs.first);
      } else {
        final result = await _distanceService.geocode(query);
        if (!mounted) return;
        if (result != null) {
          final newPos = LatLng(result.lat, result.lng);
          setState(() {
            _currentPosition = newPos;
            _recommendations = [];
            _isLoadingRecommendations = false;
          });
          _mapController.move(newPos, 16.0);
          _reverseGeocode(newPos);
        } else {
          setState(() {
            _isGeocoding = false;
            _isLoadingRecommendations = false;
            _geocodeError = 'Lokasi tidak ditemukan';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeocoding = false;
        _isLoadingRecommendations = false;
        _geocodeError = 'Gagal mencari lokasi';
      });
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    if (_recommendations.isNotEmpty || _isLoadingRecommendations) {
      setState(() {
        _recommendations = [];
        _isLoadingRecommendations = false;
      });
    }
    _currentPosition = point;
    _mapController.move(point, _mapController.camera.zoom);
    _reverseGeocode(point);
  }

  void _onMapMoved() {
    final center = _mapController.camera.center;
    _currentPosition = center;
    _reverseGeocode(center);
  }

  Widget _buildAddressDetail(List<String> lines) {
    if (lines.isEmpty) {
      return Text(
        'Geser peta untuk memilih titik',
        style: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 15,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lines.first,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        if (lines.length > 1)
          ...lines.sublist(1).map(
                (line) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchTextChanged,
                decoration: InputDecoration(
                  hintText: 'Cari alamat atau nama tempat...',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty || _recommendations.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchTextChanged('');
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, size: 20),
                          onPressed: _searchLocation,
                        ),
                ),
                onSubmitted: (_) => _searchLocation(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Map Area
          Expanded(
            child: Stack(
              children: [
                if (_isLocating)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Mendeteksi lokasi kamu...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 16.0,
                      onTap: _onMapTapped,
                      onMapEvent: (event) {
                        if (event is MapEventMoveEnd) {
                          _onMapMoved();
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: AppConfig.mapboxAccessToken.isNotEmpty
                            ? 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        additionalOptions: AppConfig.mapboxAccessToken.isNotEmpty
                            ? const {
                                'accessToken': AppConfig.mapboxAccessToken,
                              }
                            : const {},
                        userAgentPackageName: 'com.sentra.customer_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, color: AppColors.primary, size: 40),
                                SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                // My Location Button
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    onPressed: _getCurrentLocation,
                    child: const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),

                // Overlay Rekomendasi Lokasi Terdekat dengan Jarak GPS
                if (_recommendations.isNotEmpty || _isLoadingRecommendations)
                  Positioned(
                    top: 12,
                    left: 24,
                    right: 24,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 280),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _isLoadingRecommendations && _recommendations.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Mencari rekomendasi terdekat...',
                                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _recommendations.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final rec = _recommendations[index];
                                  return InkWell(
                                    onTap: () => _selectRecommendation(rec),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  rec.placeName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  rec.fullAddress,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (rec.distanceKm != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                rec.distanceKm! < 1.0
                                                    ? '${(rec.distanceKm! * 1000).round()} m'
                                                    : '${rec.distanceKm!.toStringAsFixed(1)} km',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Selected Location + Confirm
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Lokasi terpilih:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      if (_isGeocoding)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      if (_geocodeError != null && !_isGeocoding)
                        Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error.withValues(alpha: 0.7)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentGeocode != null && !_isGeocoding) ...[
                            _buildAddressDetail(_currentGeocode!.displayLines),
                          ] else if (_isGeocoding) ...[
                            Text(
                              'Memuat alamat...',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Geser peta untuk memilih titik',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 15,
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (_geocodeError != null && !_isGeocoding) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Alamat tidak tersedia, koordinat akan digunakan.',
                      style: TextStyle(fontSize: 11, color: AppColors.error.withValues(alpha: 0.7)),
                    ),
                  ],

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isGeocoding
                          ? null
                          : () {
                              final data = PickupLocationData(
                                lat: _currentPosition.latitude,
                                lng: _currentPosition.longitude,
                                address: _currentGeocode?.fullAddress ??
                                    '${_currentPosition.latitude.toStringAsFixed(6)}, ${_currentPosition.longitude.toStringAsFixed(6)}',
                              );
                              Navigator.pop(context, data);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isGeocoding ? 'Memuat lokasi...' : 'Konfirmasi Lokasi',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
