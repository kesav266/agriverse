import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/main_drawer.dart';

class WeatherIrrigationScreen extends StatefulWidget {
  const WeatherIrrigationScreen({super.key});

  @override
  State<WeatherIrrigationScreen> createState() =>
      _WeatherIrrigationScreenState();
}

class _WeatherIrrigationScreenState extends State<WeatherIrrigationScreen> {
  final _crop = TextEditingController();
  final _moisture = TextEditingController();
  DateTime? _lastIrrigation;
  Map<String, dynamic>? _assessment;
  String? _irrigationError;
  bool _busy = false;

  @override
  void dispose() {
    _crop.dispose();
    _moisture.dispose();
    super.dispose();
  }

  Future<void> _assessIrrigation() async {
    final cropName = _crop.text.trim();
    final moisture = double.tryParse(_moisture.text.trim());
    if (cropName.isEmpty ||
        moisture == null ||
        moisture < 0 ||
        moisture > 100 ||
        _lastIrrigation == null) {
      setState(
        () => _irrigationError =
            'Enter a crop, soil moisture from 0 to 100%, and the last irrigation date.',
      );
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _assessment = null;
      _irrigationError = null;
    });
    try {
      final result = await context
          .read<AppStateProvider>()
          .apiClient
          .scheduleIrrigation({
            'crop_name': cropName,
            'soil_moisture_percentage': moisture,
            'last_irrigation_date': _lastIrrigation!
                .toIso8601String()
                .substring(0, 10),
          });
      if (mounted) setState(() => _assessment = result);
    } catch (error) {
      if (mounted) {
        setState(
          () => _irrigationError = error.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmtDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final weather = state.weatherData;
    final forecast = weather?.forecast ?? const [];
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(state.tr('weather_summary')),
        actions: [
          IconButton(
            tooltip: state.tr('refresh_weather'),
            onPressed: state.loadDashboardData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: RefreshIndicator(
        onRefresh: state.loadDashboardData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (state.weatherState.isLoading)
              const AppCard(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (weather == null)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.tr('weather_unavailable')),
                    const SizedBox(height: 6),
                    Text(
                      state.weatherState.errorMessage ??
                          state.tr('weather_error_help'),
                    ),
                    TextButton(
                      onPressed: state.loadDashboardData,
                      child: Text(state.tr('retry')),
                    ),
                  ],
                ),
              )
            else ...[
              AppCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3B5C), Color(0xFF1E5E8A)],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.district,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${weather.temperatureCelsius.toStringAsFixed(1)} °C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      weather.forecastCondition,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${state.tr('humidity')}: ${weather.humidityPercentage?.toStringAsFixed(0) ?? state.tr('unavailable')}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '${state.tr('rainfall')}: ${weather.rainfallMm?.toStringAsFixed(1) ?? state.tr('unavailable')} mm',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '${state.tr('wind')}: ${weather.windSpeedKmh?.toStringAsFixed(1) ?? state.tr('unavailable')} km/h',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${state.tr('source_label')}: ${weather.dataSource} · ${state.tr('updated_label')} ${weather.recordedAt.toLocal()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.currentLanguage == 'te'
                      ? weather.advisoryTe
                      : weather.advisoryEn,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                state.tr('forecast_coverage_title'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (forecast.isEmpty)
                AppCard(
                  padding: EdgeInsets.all(14),
                  child: Text(state.tr('no_forecast_points')),
                )
              else
                ...forecast.map(
                  (point) => AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${point.timestamp.toLocal()}\n${point.condition}',
                          ),
                        ),
                        Text(
                          '${point.temperatureCelsius.toStringAsFixed(1)} °C\n${state.tr('rain_label')}: ${point.rainfallMm?.toStringAsFixed(1) ?? state.tr('unavailable')} mm',
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 18),
            Text(
              state.tr('irrigation_assessment'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(state.tr('irrigation_description')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _crop,
                    decoration: InputDecoration(
                      labelText: state.tr('crop_name'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _moisture,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: state.tr('soil_moisture'),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _lastIrrigation ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && mounted) {
                        setState(() => _lastIrrigation = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _lastIrrigation == null
                          ? state.tr('select_last_irrigation_date')
                          : '${state.tr('last_irrigation')}: ${_fmtDate(_lastIrrigation!)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _busy ? null : _assessIrrigation,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.water_drop_outlined),
                    label: Text(
                      state.tr(_busy ? 'assessing' : 'get_assessment'),
                    ),
                  ),
                ],
              ),
            ),
            if (_irrigationError != null) ...[
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _irrigationError!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
            if (_assessment != null) ...[
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.tr('assessment')}: ${_assessment!['recommendation'] ?? state.tr('unavailable')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      state.currentLanguage == 'te'
                          ? '${_assessment!['advisory_te'] ?? ''}'
                          : '${_assessment!['advisory_en'] ?? ''}',
                    ),
                    Text(
                      '${state.tr('next_assessment_date')}: ${_assessment!['next_assessment_date'] ?? state.tr('unavailable')}',
                    ),
                    if ((_assessment!['missing_information'] as List? ??
                            const [])
                        .isNotEmpty)
                      Text(
                        '${state.tr('missing_information')}: ${(_assessment!['missing_information'] as List).join(', ')}',
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
