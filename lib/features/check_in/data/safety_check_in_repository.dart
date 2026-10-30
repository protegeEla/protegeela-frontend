import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/models/safety_check_in.dart';
import '../../authentication/data/demo_session_repository.dart';

final safetyCheckInRepositoryProvider =
    Provider<SafetyCheckInRepository>((ref) {
  return SafetyCheckInRepository(ref.watch(apiClientProvider));
});

final currentSafetyCheckInProvider =
    FutureProvider<SafetyCheckIn?>((ref) async {
  if (await ref.watch(demoSessionProvider.future)) return null;
  return ref.watch(safetyCheckInRepositoryProvider).current();
});

class SafetyCheckInRepository {
  SafetyCheckInRepository(this._api);

  final ApiClient _api;
  final Map<String, String> _shareUrls = {};

  Future<SafetyCheckIn?> current() async {
    final data = await _api.request('GET', '/safety-checkins/current');
    final item = data['check_in'];
    if (item is! Map<String, dynamic>) return null;
    final checkIn = SafetyCheckIn.fromJson(item);
    return checkIn.withShareUrl(_shareUrls[checkIn.id]);
  }

  Future<SafetyCheckIn> start({
    required int durationMinutes,
    int graceMinutes = 5,
    bool shareLocation = false,
    LocationCapture? location,
  }) async {
    final data = await _api.request('POST', '/safety-checkins', body: {
      'duration_minutes': durationMinutes,
      'grace_minutes': graceMinutes,
      'share_location': shareLocation,
      if (location != null) 'location': location.toJson(),
    });
    final checkIn = SafetyCheckIn.fromJson(
      data['check_in'] as Map<String, dynamic>,
    );
    if (checkIn.shareUrl != null) _shareUrls[checkIn.id] = checkIn.shareUrl!;
    return checkIn;
  }

  Future<String> createShareLink(String checkInId) async {
    final data = await _api.request('POST', '/safety-checkins/current/share');
    final url = data['share_url'] as String;
    _shareUrls[checkInId] = url;
    return url;
  }

  Future<void> updateLocation(LocationCapture location) async {
    await _api.request(
      'PUT',
      '/safety-checkins/current/location',
      body: {'location': location.toJson()},
    );
  }

  Future<void> complete() async {
    await _api.request('POST', '/safety-checkins/complete');
    _shareUrls.clear();
  }

  Future<void> cancel() async {
    await _api.request('POST', '/safety-checkins/cancel');
    _shareUrls.clear();
  }
}
