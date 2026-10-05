import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

class AdminDashboardMetrics {
  const AdminDashboardMetrics({
    required this.totalAlerts,
    required this.activeAlerts,
    required this.closedAlerts,
    required this.verifiedSupportPoints,
  });

  final int totalAlerts;
  final int activeAlerts;
  final int closedAlerts;
  final int verifiedSupportPoints;
}

class AdminRepository {
  const AdminRepository(this._api);
  final ApiClient _api;

  Future<AdminDashboardMetrics> metrics() async {
    final data = await _api.request('GET', '/admin/metrics');
    return AdminDashboardMetrics(
        totalAlerts: (data['total_alerts'] as num).toInt(),
        activeAlerts: (data['active_alerts'] as num).toInt(),
        closedAlerts: (data['closed_alerts'] as num).toInt(),
        verifiedSupportPoints:
            (data['verified_support_points'] as num).toInt());
  }
}
