import '../../../core/services/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/models/alert_location.dart';
import '../../../shared/models/emergency_alert.dart';
import '../../authentication/data/demo_session_repository.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(ref.watch(apiClientProvider));
});

// Keep the request out of widget build(): rebuilding the page must not fetch
// the same position again. Auto-dispose also clears coordinates on leaving it.
final latestAlertLocationProvider = FutureProvider.autoDispose
    .family<AlertLocation?, String>((ref, alertId) async {
  ref.watch(currentUserProvider.select((user) => user?.id));
  final demoActive = await ref.watch(demoSessionProvider.future);
  if (demoActive) return null;
  return ref.watch(emergencyRepositoryProvider).latestLocation(alertId);
});

class EmergencyRepository {
  const EmergencyRepository(this._api);
  final ApiClient _api;

  Future<EmergencyAlert?> activeAlert() async {
    final data = await _api.request('GET', '/alerts/active');
    return data['alert'] == null
        ? null
        : EmergencyAlert.fromJson(data['alert'] as Map<String, dynamic>);
  }

  Future<EmergencyAlert> createAlert(
      {required String clientRequestId,
      required String alertType,
      required bool isSilent,
      bool publicVisibility = false,
      LocationCapture? location,
      required String locationStatus}) async {
    final data = await _api.request('POST', '/alerts', body: {
      'client_request_id': clientRequestId,
      'alert_type': alertType,
      'is_silent': isSilent,
      'location_status': locationStatus,
      'location': location?.toJson(),
      'public_visibility': publicVisibility && !isSilent,
    });
    return EmergencyAlert.fromJson(data['alert'] as Map<String, dynamic>);
  }

  Future<void> updateLocation(
      {required String alertId, required LocationCapture location}) async {
    await _api.request('PUT', '/alerts/$alertId/location',
        body: {'location': location.toJson()});
  }

  Future<void> closeAlert(
      {required String alertId, required String reason, String? pin}) async {
    await _api
        .request('POST', '/alerts/$alertId/close', body: {'reason': reason});
  }

  Stream<EmergencyAlert> watchAlert(String alertId) async* {
    while (_api.isAuthenticated) {
      final data = await _api.request('GET', '/alerts/$alertId');
      final alert =
          EmergencyAlert.fromJson(data['alert'] as Map<String, dynamic>);
      yield alert;
      if (!alert.isActive) return;
      await Future<void>.delayed(const Duration(seconds: 10));
    }
  }

  Future<AlertLocation?> latestLocation(String alertId) async {
    final data = await _api.request('GET', '/alerts/$alertId/location');
    return data['location'] == null
        ? null
        : AlertLocation.fromJson(data['location'] as Map<String, dynamic>);
  }
}
