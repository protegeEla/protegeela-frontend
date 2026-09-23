class EmergencyService {
  const EmergencyService({
    required this.id,
    required this.name,
    required this.phone,
    required this.description,
    required this.region,
    required this.isActive,
  });

  final String id;
  final String name;
  final String phone;
  final String description;
  final String region;
  final bool isActive;

  factory EmergencyService.fromJson(Map<String, dynamic> json) =>
      EmergencyService(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        description: json['description'] as String? ?? '',
        region: json['region'] as String? ?? 'BR',
        isActive: json['is_active'] as bool? ?? false,
      );
}
