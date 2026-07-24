import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/distance_service.dart';

enum CurrentLocationStatus {
  initial,
  loading,
  ready,
  permissionDenied,
  serviceDisabled,
  error,
}

class CurrentLocationState {
  final CurrentLocationStatus status;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? errorMessage;

  const CurrentLocationState({
    this.status = CurrentLocationStatus.initial,
    this.latitude,
    this.longitude,
    this.address,
    this.errorMessage,
  });

  CurrentLocationState copyWith({
    CurrentLocationStatus? status,
    double? latitude,
    double? longitude,
    String? address,
    String? errorMessage,
  }) {
    return CurrentLocationState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final currentLocationProvider =
    NotifierProvider<CurrentLocationNotifier, CurrentLocationState>(() {
  return CurrentLocationNotifier();
});

class CurrentLocationNotifier extends Notifier<CurrentLocationState> {
  @override
  CurrentLocationState build() {
    Future.microtask(() => detectLocation());
    return const CurrentLocationState(status: CurrentLocationStatus.initial);
  }

  Future<void> detectLocation() async {
    state = state.copyWith(status: CurrentLocationStatus.loading);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          status: CurrentLocationStatus.serviceDisabled,
          errorMessage: 'GPS belum aktif. Aktifkan lokasi perangkat Anda.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            status: CurrentLocationStatus.permissionDenied,
            errorMessage: 'Izin akses lokasi ditolak.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          status: CurrentLocationStatus.permissionDenied,
          errorMessage: 'Izin lokasi ditolak permanen. Buka pengaturan.',
        );
        return;
      }

      // 1. Coba ambil last known position terlebih dahulu
      Position? position = await Geolocator.getLastKnownPosition();

      // 2. Jika tidak ada, coba getCurrentPosition dengan timeout sedang
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (e) {
        // Jika getCurrentPosition timeout/gagal (misal di PC/Emulator tanpa GPS), gunakan lastKnown atau fallback
        position ??= Position(
          longitude: 106.816666,
          latitude: -6.200000,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      String displayAddress =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';

      try {
        final distanceService = DistanceService();
        final geocode = await distanceService.reverseGeocode(
          lat: position.latitude,
          lng: position.longitude,
        );
        if (geocode != null) {
          if (geocode.shortAddress.isNotEmpty) {
            displayAddress = geocode.shortAddress;
          } else if (geocode.fullAddress.isNotEmpty) {
            displayAddress = geocode.fullAddress;
          }
        } else if (position.latitude == -6.200000 && position.longitude == 106.816666) {
          displayAddress = 'Jakarta (Titik Default - Klik atur)';
        }
      } catch (e) {
        if (position.latitude == -6.200000 && position.longitude == 106.816666) {
          displayAddress = 'Jakarta (Titik Default - Klik atur)';
        }
      }

      state = CurrentLocationState(
        status: CurrentLocationStatus.ready,
        latitude: position.latitude,
        longitude: position.longitude,
        address: displayAddress,
      );
    } catch (e) {
      state = state.copyWith(
        status: CurrentLocationStatus.error,
        errorMessage: 'Gagal mendeteksi (${e.toString().split("\n").first})',
      );
    }
  }

  Future<void> openSettings() async {
    if (state.status == CurrentLocationStatus.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else if (state.status == CurrentLocationStatus.permissionDenied) {
      await Geolocator.openAppSettings();
    }
    await Future.delayed(const Duration(seconds: 1));
    await detectLocation();
  }

  void updateLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) {
    state = CurrentLocationState(
      status: CurrentLocationStatus.ready,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }
}

