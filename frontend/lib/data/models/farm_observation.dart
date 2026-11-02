class FarmObservation {
  final String id;
  final String cropCycleId;
  final String observationDate;
  final double? soilMoisturePercentage;
  final String? pestSymptoms;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const FarmObservation({
    required this.id,
    required this.cropCycleId,
    required this.observationDate,
    this.soilMoisturePercentage,
    this.pestSymptoms,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmObservation.fromJson(Map<String, dynamic> json) {
    return FarmObservation(
      id: _requiredString(json, 'id'),
      cropCycleId: _requiredString(json, 'crop_cycle_id'),
      observationDate: _requiredString(json, 'observation_date'),
      soilMoisturePercentage: (json['soil_moisture_percentage'] as num?)
          ?.toDouble(),
      pestSymptoms: json['pest_symptoms'] as String?,
      notes: json['notes'] as String?,
      createdAt: _requiredString(json, 'created_at'),
      updatedAt: _requiredString(json, 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'observation_date': observationDate,
    'soil_moisture_percentage': soilMoisturePercentage,
    'pest_symptoms': pestSymptoms,
    'notes': notes,
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing required observation field: $key');
}
