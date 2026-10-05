import '../../../core/services/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/emergency_service.dart';

final emergencyServicesRepositoryProvider =
    Provider<EmergencyServicesRepository>((ref) {
  return EmergencyServicesRepository(ref.watch(apiClientProvider));
});

class EmergencyServicesRepository {
  const EmergencyServicesRepository(this._api);
  final ApiClient _api;

  Future<EmergencyService?> firstActive() async {
    final data = await _api.request('GET', '/emergency-services/active');
    return data['service'] == null
        ? null
        : EmergencyService.fromJson(data['service'] as Map<String, dynamic>);
  }
}
