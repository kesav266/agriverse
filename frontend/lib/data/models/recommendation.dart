class Recommendation {
  final String id;
  final String farmId;
  final String cropName;
  final String category;
  final String title;
  final String detailsEn;
  final String detailsTe;
  final double? confidenceScore;
  final String methodology;

  Recommendation({
    required this.id,
    required this.farmId,
    required this.cropName,
    required this.category,
    required this.title,
    required this.detailsEn,
    required this.detailsTe,
    this.confidenceScore,
    this.methodology = 'transparent_rules',
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: _requiredString(json, 'id'),
      farmId: json['farm_id'] as String? ?? '',
      cropName: _requiredString(json, 'crop_name'),
      category: _requiredString(json, 'category'),
      title: _requiredString(json, 'recommendation_title'),
      detailsEn: _requiredString(json, 'details_en'),
      detailsTe: _requiredString(json, 'details_te'),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      methodology: json['methodology'] as String? ?? 'transparent_rules',
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing required recommendation field: $key');
}
