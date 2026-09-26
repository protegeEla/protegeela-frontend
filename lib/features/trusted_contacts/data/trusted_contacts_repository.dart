import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_providers.dart';
import '../../../shared/models/trusted_contact.dart';
import '../../authentication/data/demo_session_repository.dart';

final trustedContactsRepositoryProvider =
    Provider<TrustedContactsRepository>((ref) {
  return TrustedContactsRepository(ref.watch(supabaseClientProvider));
});

final demoTrustedContactsProvider =
    StateProvider.autoDispose<List<TrustedContact>>(
  (ref) => const [
    TrustedContact(
      id: 'demo-contact',
      ownerUserId: 'demo-user',
      name: 'Contato demonstrativo',
      phone: '(00) 00000-0000',
      relationship: 'demo',
      invitationStatus: 'accepted',
      canViewExactLocation: true,
      isPrimary: true,
    ),
  ],
);

final trustedContactsProvider =
    FutureProvider<List<TrustedContact>>((ref) async {
  ref.watch(currentUserProvider.select((user) => user?.id));
  final demoActive = await ref.watch(demoSessionProvider.future);
  if (demoActive) {
    return ref.watch(demoTrustedContactsProvider);
  }
  return ref.watch(trustedContactsRepositoryProvider).listMine();
});

class TrustedContactsRepository {
  const TrustedContactsRepository(this._client);

  final SupabaseClient _client;

  Future<List<TrustedContact>> listMine() async {
    final rows = await _client
        .from('trusted_contacts')
        .select()
        .order('is_primary', ascending: false)
        .order('created_at', ascending: false);
    return [for (final row in rows) TrustedContact.fromJson(row)];
  }

  Future<void> addContact({
    required String name,
    required String phone,
    String? email,
    required String relationship,
    required bool canViewExactLocation,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException(
        'Sessão expirada. Entre novamente.',
        code: 'authentication_required',
      );
    }
    final normalizedEmail = email?.trim();
    await _client.from('trusted_contacts').insert({
      'owner_user_id': userId,
      'name': name.trim(),
      'phone': phone.trim(),
      'email': normalizedEmail == null || normalizedEmail.isEmpty
          ? null
          : normalizedEmail,
      'relationship': relationship,
      'can_view_exact_location': canViewExactLocation,
    });
  }

  Future<void> remove(String id) async {
    await _client.from('trusted_contacts').delete().eq('id', id);
  }

  Future<void> updateContact({
    required String id,
    required String name,
    required String phone,
    String? email,
    required String relationship,
  }) async {
    final normalizedEmail = email?.trim();
    await _client.from('trusted_contacts').update({
      'name': name.trim(),
      'phone': phone.trim(),
      'email': normalizedEmail == null || normalizedEmail.isEmpty
          ? null
          : normalizedEmail,
      'relationship': relationship,
    }).eq('id', id);
  }

  Future<void> updateLocationPermission({
    required String id,
    required bool canViewExactLocation,
  }) async {
    await _client.from('trusted_contacts').update({
      'can_view_exact_location': canViewExactLocation,
    }).eq('id', id);
  }
}
