import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../authentication/data/demo_session_repository.dart';

final alertsMapRepositoryProvider = Provider<AlertsMapRepository>((ref) {
  return AlertsMapRepository(ref.watch(apiClientProvider));
});

final publicAlertMarkersProvider =
    FutureProvider<List<PublicAlertMarker>>((ref) async {
  final demoActive = await ref.watch(demoSessionProvider.future);
  if (demoActive) {
    return [
      PublicAlertMarker(
        id: 'demo-alert-public',
        alertType: 'immediate_danger',
        status: 'active',
        latitude: -3.119,
        longitude: -60.022,
        radiusMeters: 500,
        startedAt: DateTime.now().toUtc(),
      ),
    ];
  }
  return const [];
});

class PublicAlertMarker {
  const PublicAlertMarker({
    required this.id,
    required this.alertType,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.startedAt,
  });

  final String id;
  final String alertType;
  final String status;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final DateTime startedAt;

  factory PublicAlertMarker.fromJson(Map<String, dynamic> json) =>
      PublicAlertMarker(
        id: json['id'] as String,
        alertType: json['alert_type'] as String,
        status: json['status'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radius_meters'] as num?)?.toInt() ?? 500,
        startedAt: DateTime.parse(json['started_at'] as String),
      );
}

class AlertsMapRepository {
  const AlertsMapRepository(this._api);
  final ApiClient _api;

  Future<List<PublicAlertMarker>> publicAlertsInBounds(
      {required double south,
      required double west,
      required double north,
      required double east}) async {
    final query = Uri(queryParameters: {
      'south': south.toString(),
      'west': west.toString(),
      'north': north.toString(),
      'east': east.toString(),
    }).query;
    return (await _api.list('/alerts/map?$query'))
        .map(PublicAlertMarker.fromJson)
        .toList();
  }
}
