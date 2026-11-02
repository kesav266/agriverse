class HealthDiagnosis {
  final String id;
  final String cropName;
  final String detectedDisease;
  final String severity; // Low, Moderate, High
  final String treatmentEn;
  final String treatmentTe;
  final double? confidenceScore;
  final bool needsExpertReview;

  HealthDiagnosis({
    required this.id,
    required this.cropName,
    required this.detectedDisease,
    required this.severity,
    required this.treatmentEn,
    required this.treatmentTe,
    this.confidenceScore,
    this.needsExpertReview = true,
  });

  factory HealthDiagnosis.fromJson(Map<String, dynamic> json) {
    return HealthDiagnosis(
      id: _requiredString(json, 'id'),
      cropName: _requiredString(json, 'crop_name'),
      detectedDisease: _requiredString(json, 'detected_disease'),
      severity: _requiredString(json, 'severity'),
      treatmentEn: _requiredString(json, 'recommended_treatment_en'),
      treatmentTe: _requiredString(json, 'recommended_treatment_te'),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      needsExpertReview: json['needs_expert_review'] as bool? ?? true,
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing required diagnosis field: $key');
}
