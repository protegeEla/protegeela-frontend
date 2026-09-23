class AppProfile {
  const AppProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.privacyMode,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String phone;
  final String role;
  final String privacyMode;
  final String? avatarUrl;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;
  bool get isAdmin => role == 'admin';

  AppProfile copyWith({
    String? fullName,
    String? phone,
    String? role,
    String? privacyMode,
    String? avatarUrl,
  }) {
    return AppProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      privacyMode: privacyMode ?? this.privacyMode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory AppProfile.fromJson(Map<String, dynamic> json) => AppProfile(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        role: json['role'] as String? ?? 'user',
        privacyMode: json['privacy_mode'] as String? ?? 'standard',
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone': phone,
        'role': role,
        'privacy_mode': privacyMode,
        'avatar_url': avatarUrl,
      };
}
