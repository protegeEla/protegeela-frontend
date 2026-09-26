import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_providers.dart';
import '../../../shared/models/emergency_service.dart';

final emergencyServicesRepositoryProvider =
    Provider<EmergencyServicesRepository>((ref) {
  return EmergencyServicesRepository(ref.watch(supabaseClientProvider));
});

class EmergencyServicesRepository {
  const EmergencyServicesRepository(this._client);

  final SupabaseClient _client;

  Future<EmergencyService?> firstActive() async {
    final data = await _client
        .from('emergency_services')
        .select()
        .eq('is_active', true)
        .order('region')
        .limit(1)
        .maybeSingle();
    return data == null ? null : EmergencyService.fromJson(data);
  }
}
