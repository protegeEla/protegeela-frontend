import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_providers.dart';
import '../../../shared/models/app_profile.dart';
import '../../authentication/data/demo_session_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
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
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<AppProfile?> currentProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final data =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return data == null ? null : AppProfile.fromJson(data);
  }

  Future<void> upsertProfile({
    required String fullName,
    required String phone,
    String privacyMode = 'standard',
  }) async {
    final userId = _requireUserId();
    await _client.from('profiles').upsert({
      'id': userId,
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'privacy_mode': privacyMode,
    });
  }

  Future<void> updatePrivacyMode(String privacyMode) async {
    final userId = _requireUserId();
    await _client
        .from('profiles')
        .update({'privacy_mode': privacyMode}).eq('id', userId);
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException(
        'Sessão expirada. Entre novamente.',
        code: 'authentication_required',
      );
    }
    return userId;
  }
}
