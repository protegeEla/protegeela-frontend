import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_providers.dart';

final notificationCenterRepositoryProvider =
    Provider<NotificationCenterRepository>((ref) {
  return NotificationCenterRepository(ref.watch(supabaseClientProvider));
});

class NotificationCenterRepository {
  const NotificationCenterRepository(this._client);

  final SupabaseClient _client;

  Future<void> markAlertNotificationsSent(String alertId) async {
    await _client.functions
        .invoke('send-alert-notifications', body: {'alert_id': alertId});
  }
}
