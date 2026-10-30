class SharedTripLocation {
  const SharedTripLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime capturedAt;

  factory SharedTripLocation.fromJson(Map<String, dynamic> json) =>
      SharedTripLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num).toDouble(),
        capturedAt: DateTime.parse(json['captured_at'] as String),
      );
}

class SharedTrip {
  const SharedTrip({
    required this.travelerName,
    required this.status,
    required this.expectedAt,
    required this.expiresAt,
    required this.createdAt,
    required this.shareLocation,
    required this.locations,
    this.completedAt,
    this.lastLocationAt,
  });

  final String travelerName;
  final String status;
  final DateTime expectedAt;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool shareLocation;
  final DateTime? completedAt;
  final DateTime? lastLocationAt;
  final List<SharedTripLocation> locations;

  factory SharedTrip.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>;
    final locations = json['locations'] as List<dynamic>? ?? const [];
    return SharedTrip(
      travelerName: trip['traveler_name'] as String? ?? 'Pessoa protegida',
      status: trip['status'] as String? ?? 'active',
      expectedAt: DateTime.parse(trip['expected_at'] as String),
      expiresAt: DateTime.parse(trip['expires_at'] as String),
      createdAt: DateTime.parse(trip['created_at'] as String),
      shareLocation: trip['share_location'] as bool? ?? false,
      completedAt: trip['completed_at'] == null
          ? null
          : DateTime.parse(trip['completed_at'] as String),
      lastLocationAt: trip['last_location_at'] == null
          ? null
          : DateTime.parse(trip['last_location_at'] as String),
      locations: locations
          .map((item) => SharedTripLocation.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  }
}
