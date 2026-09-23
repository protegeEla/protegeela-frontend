class EmergencyAlert {
  const EmergencyAlert({
    required this.id,
    required this.userId,
    required this.alertType,
    required this.status,
    required this.isSilent,
    required this.locationStatus,
    required this.startedAt,
    required this.publicVisibility,
    this.endedAt,
    this.endReason,
    this.publicLatitude,
    this.publicLongitude,
  });

  final String id;
  final String userId;
  final String alertType;
  final String status;
  final bool isSilent;
  final String locationStatus;
  final DateTime startedAt;
  final bool publicVisibility;
  final DateTime? endedAt;
  final String? endReason;
  final double? publicLatitude;
  final double? publicLongitude;

  bool get isActive => status == 'active' || status == 'acknowledged';

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) => EmergencyAlert(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        alertType: json['alert_type'] as String? ?? 'immediate_danger',
        status: json['status'] as String? ?? 'active',
        isSilent: json['is_silent'] as bool? ?? false,
        locationStatus:
            json['location_status'] as String? ?? 'location_unavailable',
        startedAt: DateTime.parse(json['started_at'] as String),
        publicVisibility: json['public_visibility'] as bool? ?? true,
        endedAt: json['ended_at'] == null
            ? null
            : DateTime.parse(json['ended_at'] as String),
        endReason: json['end_reason'] as String?,
        publicLatitude: (json['public_latitude'] as num?)?.toDouble(),
        publicLongitude: (json['public_longitude'] as num?)?.toDouble(),
      );
}
