import '../../../core/services/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationCenterRepositoryProvider =
    Provider<NotificationCenterRepository>((ref) {
  return NotificationCenterRepository(ref.watch(apiClientProvider));
});

final alertNotificationSummaryProvider = FutureProvider.autoDispose
    .family<AlertNotificationSummary, String>((ref, alertId) {
  return ref.watch(notificationCenterRepositoryProvider).status(alertId);
});

class AlertNotificationSummary {
  const AlertNotificationSummary({required this.status, required this.sent});

  final String status;
  final bool sent;

  bool get isConfigured => status != 'not_configured';
}

class NotificationCenterRepository {
  const NotificationCenterRepository(this._api);
  final ApiClient _api;

  Future<AlertNotificationSummary> status(String alertId) async {
    final data = await _api.request('GET', '/alerts/$alertId/notifications');
    return AlertNotificationSummary(
      status: data['status'] as String? ?? 'unknown',
      sent: data['sent'] == true,
    );
  }

  Future<bool> wasAlertNotificationSent(String alertId) async {
    return (await status(alertId)).sent;
  }
}
