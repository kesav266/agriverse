class WeatherForecastPoint {
  final DateTime timestamp;
  final double temperatureCelsius;
  final double? rainfallMm;
  final String condition;

  const WeatherForecastPoint({
    required this.timestamp,
    required this.temperatureCelsius,
    required this.condition,
    this.rainfallMm,
  });

  factory WeatherForecastPoint.fromJson(Map<String, dynamic> json) =>
      WeatherForecastPoint(
        timestamp: DateTime.parse(_requiredString(json, 'timestamp')),
        temperatureCelsius: _requiredNumber(json, 'temperature_celsius'),
        rainfallMm: (json['rainfall_mm'] as num?)?.toDouble(),
        condition: _requiredString(json, 'forecast_condition'),
      );
}

class WeatherData {
  final String district;
  final double temperatureCelsius;
  final double? humidityPercentage;
  final double? rainfallMm;
  final double? windSpeedKmh;
  final String forecastCondition;
  final String advisoryEn;
  final String advisoryTe;
  final String dataSource;
  final DateTime recordedAt;
  final List<WeatherForecastPoint> forecast;

  const WeatherData({
    required this.district,
    required this.temperatureCelsius,
    required this.forecastCondition,
    required this.advisoryEn,
    required this.advisoryTe,
    required this.dataSource,
    required this.recordedAt,
    this.humidityPercentage,
    this.rainfallMm,
    this.windSpeedKmh,
    this.forecast = const [],
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
    district: _requiredString(json, 'district'),
    temperatureCelsius: _requiredNumber(json, 'temperature_celsius'),
    humidityPercentage: (json['humidity_percentage'] as num?)?.toDouble(),
    rainfallMm: (json['rainfall_mm'] as num?)?.toDouble(),
    windSpeedKmh: (json['wind_speed_kmh'] as num?)?.toDouble(),
    forecastCondition: _requiredString(json, 'forecast_condition'),
    advisoryEn: _requiredString(json, 'advisory_en'),
    advisoryTe: _requiredString(json, 'advisory_te'),
    dataSource: _requiredString(json, 'data_source'),
    recordedAt: DateTime.parse(_requiredString(json, 'recorded_at')),
    forecast: ((json['forecast'] as List?) ?? const [])
        .map(
          (row) => WeatherForecastPoint.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(),
  );
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Missing required weather field: $key');
}

double _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) return value.toDouble();
  throw FormatException('Missing required weather field: $key');
}
