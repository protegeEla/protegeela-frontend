import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../errors/app_exception.dart';

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final locationReadinessProvider = FutureProvider.autoDispose<LocationReadiness>(
  (ref) => ref.watch(locationServiceProvider).readiness(),
);

enum LocationReadiness {
  ready,
  permissionRequired,
  serviceDisabled,
  blocked,
}

class LocationCapture {
  const LocationCapture({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    required this.capturedAt,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final DateTime capturedAt;
  final String source;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'captured_at': capturedAt.toIso8601String(),
        'source': source,
      };
}

class LocationService {
  Future<LocationReadiness> readiness() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationReadiness.serviceDisabled;
    }
    return _readinessFromPermission(await Geolocator.checkPermission());
  }

  Future<LocationReadiness> requestAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationReadiness.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return _readinessFromPermission(permission);
  }

  LocationReadiness _readinessFromPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationReadiness.ready,
      LocationPermission.deniedForever => LocationReadiness.blocked,
      _ => LocationReadiness.permissionRequired,
    };
  }

  Future<LocationCapture> captureCurrent() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const AppException(
        'Localização indisponível neste dispositivo.',
        code: 'location_unavailable',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const AppException(
        'Permissão de localização negada.',
        code: 'location_denied',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 12),
    );

    return LocationCapture(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      capturedAt: DateTime.now().toUtc(),
      source: 'browser_geolocation',
    );
  }
}
