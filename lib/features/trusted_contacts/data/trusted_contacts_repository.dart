import '../../../core/services/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/utils/phone_number_formatter.dart';
import '../../../shared/models/trusted_contact.dart';
import '../../authentication/data/demo_session_repository.dart';

final trustedContactsRepositoryProvider =
    Provider<TrustedContactsRepository>((ref) {
  return TrustedContactsRepository(ref.watch(apiClientProvider));
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
  const TrustedContactsRepository(this._api);
  final ApiClient _api;

  Future<List<TrustedContact>> listMine() async =>
      (await _api.list('/contacts')).map(TrustedContact.fromJson).toList();

  Future<void> addContact(
      {required String name,
      required String phone,
      String? email,
      required String relationship,
      required String preferredChannel,
      required bool canViewExactLocation}) async {
    await _api.request('POST', '/contacts', body: {
      'name': name.trim(),
      'phone': PhoneNumberFormatter.digitsOnly(phone),
      'email': _email(email),
      'relationship': relationship,
      'preferred_channel': preferredChannel,
      'can_view_exact_location': canViewExactLocation,
    });
  }

  Future<void> remove(String id) async {
    await _api.request('DELETE', '/contacts/$id');
  }

  Future<void> updateContact(
      {required String id,
      required String name,
      required String phone,
      String? email,
      required String relationship,
      required String preferredChannel}) async {
    await _api.request('PUT', '/contacts/$id', body: {
      'name': name.trim(),
      'phone': PhoneNumberFormatter.digitsOnly(phone),
      'email': _email(email),
      'relationship': relationship,
      'preferred_channel': preferredChannel,
    });
  }

  Future<void> updateLocationPermission(
      {required String id, required bool canViewExactLocation}) async {
    await _api.request('PATCH', '/contacts/$id/location-permission',
        body: {'can_view_exact_location': canViewExactLocation});
  }

  Future<ContactInvitationShare> createInvitation(String id) async {
    final data = await _api.request('POST', '/contacts/$id/invitation');
    return ContactInvitationShare(
      url: data['invite_url'] as String,
      expiresAt: DateTime.parse(data['expires_at'] as String),
    );
  }

  String? _email(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}

class ContactInvitationShare {
  const ContactInvitationShare({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}
