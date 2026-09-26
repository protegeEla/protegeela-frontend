import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_providers.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
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
  const AdminRepository(this._client);

  final SupabaseClient _client;

  Future<AdminDashboardMetrics> metrics() async {
    final response = await _client.rpc('admin_dashboard_metrics');
    if (response is! List<dynamic> ||
        response.isEmpty ||
        response.first is! Map<String, dynamic>) {
      throw const AppException(
        'Resposta inválida ao carregar indicadores.',
        code: 'invalid_server_response',
      );
    }
    final row = response.first as Map<String, dynamic>;
    return AdminDashboardMetrics(
      totalAlerts: row['total_alerts'] as int? ?? 0,
      activeAlerts: row['active_alerts'] as int? ?? 0,
      closedAlerts: row['closed_alerts'] as int? ?? 0,
      verifiedSupportPoints: row['verified_support_points'] as int? ?? 0,
    );
  }
}
