class AlertLocation {
  const AlertLocation({
    required this.id,
    required this.alertId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.source,
    required this.capturedAt,
    this.altitude,
  });

  final String id;
  final String alertId;
  final String userId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final String source;
  final DateTime capturedAt;

  factory AlertLocation.fromJson(Map<String, dynamic> json) => AlertLocation(
    id: json['id'] as String,
    alertId: json['alert_id'] as String,
    userId: json['user_id'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
    altitude: (json['altitude'] as num?)?.toDouble(),
    source: json['source'] as String? ?? 'unknown',
    capturedAt: DateTime.parse(json['captured_at'] as String),
  );
}
