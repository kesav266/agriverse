class CropCycle {
  final String id;
  final String farmId;
  final String cropName;
  final String variety;
  final String sowingDate;
  final String? expectedHarvestDate;
  final String stage; // Sowing, Vegetative, Flowering, Harvesting, Completed
  final String status;
  final String createdAt;

  CropCycle({
    required this.id,
    required this.farmId,
    required this.cropName,
    required this.variety,
    required this.sowingDate,
    this.expectedHarvestDate,
    required this.stage,
    this.status = 'Active',
    required this.createdAt,
  });

  factory CropCycle.fromJson(Map<String, dynamic> json) {
    return CropCycle(
      id: _requiredString(json, 'id'),
      farmId: _requiredString(json, 'farm_id'),
      cropName: _requiredString(json, 'crop_name'),
      variety: json['variety'] as String? ?? '',
      sowingDate: _requiredString(json, 'sowing_date'),
      expectedHarvestDate: json['expected_harvest_date'] as String?,
      stage: _requiredString(json, 'stage'),
      status: _requiredString(json, 'status'),
      createdAt: _requiredString(json, 'created_at'),
    );
  }

  Map<String, dynamic> toCreateJson({required String farmId}) => {
    'farm_id': farmId,
    'crop_name': cropName,
    'variety': variety,
    'sowing_date': sowingDate,
    'expected_harvest_date': expectedHarvestDate,
    'stage': stage,
  };

  Map<String, dynamic> toUpdateJson() => {
    'crop_name': cropName,
    'variety': variety,
    'sowing_date': sowingDate,
    'stage': stage,
    'status': status,
    'expected_harvest_date': expectedHarvestDate,
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing required crop-cycle field: $key');
}
