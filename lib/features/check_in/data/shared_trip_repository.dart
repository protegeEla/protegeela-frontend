import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../shared/models/shared_trip.dart';

final sharedTripRepositoryProvider = Provider<SharedTripRepository>((ref) {
  return SharedTripRepository(ref.watch(apiClientProvider));
});

class SharedTripRepository {
  const SharedTripRepository(this._api);

  final ApiClient _api;

  Future<SharedTrip> get(String token) async {
    final data = await _api.request(
      'GET',
      '/safety-checkins/shared/$token',
      authenticated: false,
    );
    return SharedTrip.fromJson(data);
  }
}
