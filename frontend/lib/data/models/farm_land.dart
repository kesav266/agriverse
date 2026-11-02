class FarmLand {
  final String id;
  final String farmerId;
  final String farmName;
  final double landAreaAcres;
  final String soilType; // Black Cotton, Red Sandy, Alluvial, Clay
  final String irrigationSource; // Borewell, Canal, Rainfed, Drip
  final double? latitude;
  final double? longitude;
  final String? surveyNumber;

  FarmLand({
    required this.id,
    required this.farmerId,
    required this.farmName,
    required this.landAreaAcres,
    required this.soilType,
    required this.irrigationSource,
    this.latitude,
    this.longitude,
    this.surveyNumber,
  });

  factory FarmLand.fromJson(Map<String, dynamic> json) {
    return FarmLand(
      id: _requiredString(json, 'id'),
      farmerId: _requiredString(json, 'farmer_id'),
      farmName: _requiredString(json, 'farm_name'),
      landAreaAcres: _requiredNumber(json, 'land_area_acres'),
      soilType: _requiredString(json, 'soil_type'),
      irrigationSource: _requiredString(json, 'irrigation_source'),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      surveyNumber: json['survey_number'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmer_id': farmerId,
    'farm_name': farmName,
    'land_area_acres': landAreaAcres,
    'soil_type': soilType,
    'irrigation_source': irrigationSource,
    'latitude': latitude,
    'longitude': longitude,
    'survey_number': surveyNumber,
  };

  Map<String, dynamic> toCreateJson() => {
    'farm_name': farmName,
    'land_area_acres': landAreaAcres,
    'soil_type': soilType,
    'irrigation_source': irrigationSource,
    'latitude': latitude,
    'longitude': longitude,
    'survey_number': surveyNumber,
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing required farm field: $key');
}

double _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  throw FormatException('Missing required farm field: $key');
}
