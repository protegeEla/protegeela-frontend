import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/supabase_providers.dart';
import '../../../shared/models/alert_location.dart';
import '../../../shared/models/emergency_alert.dart';
import '../../authentication/data/demo_session_repository.dart';

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(ref.watch(supabaseClientProvider));
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
  const EmergencyRepository(this._client);

  final SupabaseClient _client;

  Future<EmergencyAlert?> activeAlert() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final data = await _client
        .from('emergency_alerts')
        .select()
        .eq('user_id', userId)
        .inFilter('status', ['active', 'acknowledged'])
        .order('started_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data == null ? null : EmergencyAlert.fromJson(data);
  }

  Future<EmergencyAlert> createAlert({
    required String clientRequestId,
    required String alertType,
    required bool isSilent,
    LocationCapture? location,
    required String locationStatus,
  }) async {
    final response = await _client.functions.invoke(
      'create-emergency-alert',
      body: {
        'client_request_id': clientRequestId,
        'alert_type': alertType,
        'is_silent': isSilent,
        'location_status': locationStatus,
        'location': location?.toJson(),
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic> ||
        data['alert'] is! Map<String, dynamic>) {
      throw const AppException(
        'Resposta inválida ao criar alerta.',
        code: 'invalid_server_response',
      );
    }
    return EmergencyAlert.fromJson(data['alert'] as Map<String, dynamic>);
  }

  Future<void> updateLocation({
    required String alertId,
    required LocationCapture location,
  }) async {
    await _client.functions.invoke(
      'update-alert-location',
      body: {'alert_id': alertId, 'location': location.toJson()},
    );
  }

  Future<void> closeAlert(
      {required String alertId, required String reason, String? pin}) async {
    await _client.functions.invoke(
      'close-emergency-alert',
      body: {'alert_id': alertId, 'reason': reason, 'pin': pin},
    );
  }

  Stream<EmergencyAlert> watchAlert(String alertId) {
    return _client
        .from('emergency_alerts')
        .stream(primaryKey: ['id'])
        .eq('id', alertId)
        .map((rows) => EmergencyAlert.fromJson(rows.first));
  }

  Future<AlertLocation?> latestLocation(String alertId) async {
    final data = await _client
        .from('alert_locations')
        .select()
        .eq('alert_id', alertId)
        .order('captured_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data == null ? null : AlertLocation.fromJson(data);
  }
}
