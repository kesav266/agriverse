class FarmerProfile {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? village;
  final String district;
  final String state;
  final String preferredLanguage; // 'en' or 'te'
  final bool simpleModeEnabled;

  FarmerProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.village,
    required this.district,
    required this.state,
    this.preferredLanguage = 'en',
    this.simpleModeEnabled = false,
  });

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    return FarmerProfile(
      id: _requiredString(json, 'id'),
      fullName: _requiredString(json, 'full_name'),
      phoneNumber: _requiredString(json, 'phone_number'),
      village: json['village'] as String?,
      district: _requiredString(json, 'district'),
      state: _requiredString(json, 'state'),
      preferredLanguage: _requiredString(json, 'preferred_language'),
      simpleModeEnabled: json['simple_mode_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'phone_number': phoneNumber,
    'village': village,
    'district': district,
    'state': state,
    'preferred_language': preferredLanguage,
    'simple_mode_enabled': simpleModeEnabled,
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing required profile field: $key');
}
