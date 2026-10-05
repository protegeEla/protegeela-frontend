import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';

final contactInvitationRepositoryProvider =
    Provider<ContactInvitationRepository>((ref) {
  return ContactInvitationRepository(ref.watch(apiClientProvider));
});

final contactInvitationProvider =
    FutureProvider.autoDispose.family<ContactInvitation, String>((ref, token) {
  return ref.watch(contactInvitationRepositoryProvider).get(token);
});

class ContactInvitation {
  const ContactInvitation({
    required this.contactName,
    required this.ownerName,
    required this.status,
    required this.expiresAt,
  });

  final String contactName;
  final String ownerName;
  final String status;
  final DateTime expiresAt;

  factory ContactInvitation.fromJson(Map<String, dynamic> json) =>
      ContactInvitation(
        contactName: json['contact_name'] as String? ?? '',
        ownerName: json['owner_name'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}

class ContactInvitationRepository {
  const ContactInvitationRepository(this._api);

  final ApiClient _api;

  Future<ContactInvitation> get(String token) async {
    final data = await _api.request(
      'GET',
      '/contact-invitations/$token',
      authenticated: false,
    );
    return ContactInvitation.fromJson(
      data['invitation'] as Map<String, dynamic>,
    );
  }

  Future<String> respond(String token, String response) async {
    final data = await _api.request(
      'POST',
      '/contact-invitations/$token/respond',
      authenticated: false,
      body: {'response': response},
    );
    return data['status'] as String;
  }
}
