class SafetyContent {
  const SafetyContent({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.category,
    required this.isPublished,
    this.sourceName,
    this.sourceUrl,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final String category;
  final bool isPublished;
  final String? sourceName;
  final String? sourceUrl;
  final DateTime? updatedAt;

  factory SafetyContent.fromJson(Map<String, dynamic> json) => SafetyContent(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        content: json['content'] as String? ?? '',
        category: json['category'] as String? ?? 'general',
        isPublished: json['is_published'] as bool? ?? false,
        sourceName: json['source_name'] as String?,
        sourceUrl: json['source_url'] as String?,
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.tryParse(json['updated_at'] as String),
      );
}
