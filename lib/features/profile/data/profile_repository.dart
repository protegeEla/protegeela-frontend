import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/auth_providers.dart';
import '../../../core/utils/phone_number_formatter.dart';
import '../../../shared/models/app_profile.dart';
import '../../authentication/data/demo_session_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

final demoProfileProvider = StateProvider.autoDispose<AppProfile>(
  (ref) => const AppProfile(
    id: 'demo-user',
    fullName: 'Usuária Temporária',
    phone: '(00) 00000-0000',
    role: 'user',
    privacyMode: 'discreet',
  ),
);

final currentProfileProvider = FutureProvider<AppProfile?>((ref) async {
  ref.watch(currentUserProvider.select((user) => user?.id));
  final demoActive = await ref.watch(demoSessionProvider.future);
  if (demoActive) {
    return ref.watch(demoProfileProvider);
  }
  return ref.watch(profileRepositoryProvider).currentProfile();
});

class ProfileRepository {
  const ProfileRepository(this._api);
  final ApiClient _api;

  Future<AppProfile?> currentProfile() async {
    if (!_api.isAuthenticated) return null;
    return AppProfile.fromJson(await _api.request('GET', '/profile'));
  }

  Future<void> upsertProfile({
    required String fullName,
    required String phone,
    String privacyMode = 'standard',
  }) async {
    await _api.request('PUT', '/profile', body: {
      'full_name': fullName.trim(),
      'phone': PhoneNumberFormatter.digitsOnly(phone),
      'privacy_mode': privacyMode,
    });
  }

  Future<void> updatePrivacyMode(String privacyMode) async {
    await _api.request('PATCH', '/profile/privacy',
        body: {'privacy_mode': privacyMode});
  }
}
