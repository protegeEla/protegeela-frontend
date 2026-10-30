class SupportPoint {
  const SupportPoint({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.isVerified,
    this.description,
    this.phone,
    this.openingHours,
    this.website,
    this.accessibilityInfo,
  });

  final String id;
  final String name;
  final String category;
  final String? description;
  final String address;
  final String city;
  final String state;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? openingHours;
  final String? website;
  final String? accessibilityInfo;
  final bool isVerified;

  factory SupportPoint.fromJson(Map<String, dynamic> json) => SupportPoint(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? 'other',
    description: json['description'] as String?,
    address: json['address'] as String? ?? '',
    city: json['city'] as String? ?? '',
    state: json['state'] as String? ?? '',
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    phone: json['phone'] as String?,
    openingHours: json['opening_hours'] as String?,
    website: json['website'] as String?,
    accessibilityInfo: json['accessibility_info'] as String?,
    isVerified: json['is_verified'] as bool? ?? false,
  );
}
