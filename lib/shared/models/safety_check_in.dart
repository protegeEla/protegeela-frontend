class SafetyCheckIn {
  const SafetyCheckIn({
    required this.id,
    required this.expectedAt,
    required this.expiresAt,
    required this.graceMinutes,
    required this.status,
    required this.createdAt,
    required this.shareLocation,
    this.alertId,
    this.completedAt,
    this.lastLocationAt,
    this.shareUrl,
  });

  final String id;
  final DateTime expectedAt;
  final DateTime expiresAt;
  final int graceMinutes;
  final String status;
  final DateTime createdAt;
  final bool shareLocation;
  final String? alertId;
  final DateTime? completedAt;
  final DateTime? lastLocationAt;
  final String? shareUrl;

  factory SafetyCheckIn.fromJson(Map<String, dynamic> json) => SafetyCheckIn(
        id: json['id'] as String,
        expectedAt: DateTime.parse(json['expected_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        graceMinutes: json['grace_minutes'] as int? ?? 5,
        status: json['status'] as String? ?? 'active',
        createdAt: DateTime.parse(json['created_at'] as String),
        shareLocation: json['share_location'] as bool? ?? false,
        alertId: json['alert_id'] as String?,
        completedAt: json['completed_at'] == null
            ? null
            : DateTime.parse(json['completed_at'] as String),
        lastLocationAt: json['last_location_at'] == null
            ? null
            : DateTime.parse(json['last_location_at'] as String),
        shareUrl: json['share_url'] as String?,
      );

  SafetyCheckIn withShareUrl(String? value) => SafetyCheckIn(
        id: id,
        expectedAt: expectedAt,
        expiresAt: expiresAt,
        graceMinutes: graceMinutes,
        status: status,
        createdAt: createdAt,
        shareLocation: shareLocation,
        alertId: alertId,
        completedAt: completedAt,
        lastLocationAt: lastLocationAt,
        shareUrl: value,
      );
}
