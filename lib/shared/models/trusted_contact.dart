class TrustedContact {
  const TrustedContact({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.invitationStatus,
    required this.canViewExactLocation,
    required this.isPrimary,
    this.contactUserId,
    this.email,
  });

  final String id;
  final String ownerUserId;
  final String? contactUserId;
  final String name;
  final String? email;
  final String phone;
  final String relationship;
  final String invitationStatus;
  final bool canViewExactLocation;
  final bool isPrimary;

  TrustedContact copyWith({
    String? name,
    String? phone,
    String? email,
    bool clearEmail = false,
    String? relationship,
    String? invitationStatus,
    bool? canViewExactLocation,
    bool? isPrimary,
  }) {
    return TrustedContact(
      id: id,
      ownerUserId: ownerUserId,
      contactUserId: contactUserId,
      name: name ?? this.name,
      email: clearEmail ? null : email ?? this.email,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      canViewExactLocation: canViewExactLocation ?? this.canViewExactLocation,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  factory TrustedContact.fromJson(Map<String, dynamic> json) => TrustedContact(
        id: json['id'] as String,
        ownerUserId: json['owner_user_id'] as String,
        contactUserId: json['contact_user_id'] as String?,
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String? ?? '',
        relationship: json['relationship'] as String? ?? 'outro',
        invitationStatus: json['invitation_status'] as String? ?? 'pending',
        canViewExactLocation: json['can_view_exact_location'] as bool? ?? false,
        isPrimary: json['is_primary'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_user_id': ownerUserId,
        'contact_user_id': contactUserId,
        'name': name,
        'email': email,
        'phone': phone,
        'relationship': relationship,
        'invitation_status': invitationStatus,
        'can_view_exact_location': canViewExactLocation,
        'is_primary': isPrimary,
      };
}
