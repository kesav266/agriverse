import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_components.dart';
import '../../widgets/main_drawer.dart';

/// Screen 7: Premium Modern Agricultural Weather Intelligence & Smart Irrigation Screen.
/// Inspired by modern micro-climate farming dashboards (matching reference Image Screen 3).
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

  String _formattedTodayDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${now.day.toString().padLeft(2, '0')} ${months[(now.month - 1) % 12]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weather = state.weatherData;
    final forecast = weather?.forecast ?? const [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightCanopy : const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: Text(state.tr('weather_summary')),
        actions: [
          IconButton(
            tooltip: state.tr('refresh_weather'),
            onPressed: state.loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: RefreshIndicator(
        color: AppColors.forestPine,
        onRefresh: state.loadDashboardData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (state.weatherState.isLoading)
              const AppCard(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (weather == null)
              AppCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.tr('weather_unavailable'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.weatherState.errorMessage ??
                          state.tr('weather_error_help'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: state.tr('retry'),
                      icon: Icons.refresh_rounded,
                      height: 42,
                      width: 140,
                      onPressed: state.loadDashboardData,
                    ),
                  ],
                ),
              )
            else ...[
              // ===============================================================
              // 1. HERO WEATHER CARD (matching Image Screen 3)
              // ===============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F3B25), Color(0xFF14532D), Color(0xFF1B6A3B)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x220A2E1B),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location & Date
                    Text(
                      '${weather.district}, ${_formattedTodayDate()}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Big Temperature & Weather Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${weather.temperatureCelsius.toStringAsFixed(0)}°C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -2,
                              ),
                            ),
                            Text(
                              '${state.tr('humidity')}: ${weather.humidityPercentage?.toStringAsFixed(0) ?? state.tr('unavailable')}%',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.wb_sunny_rounded,
                                size: 44,
                                color: Colors.amberAccent,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              weather.forecastCondition,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Advisory Banner inside Hero Card (matching reference image)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.eco_rounded,
                            color: AppColors.limeAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.currentLanguage == 'te'
                                  ? weather.advisoryTe
                                  : weather.advisoryEn,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Atmospheric Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _heroWeatherSub(
                          state.tr('rainfall'),
                          '${weather.rainfallMm?.toStringAsFixed(1) ?? '0.0'} mm',
                          Icons.grain_rounded,
                        ),
                        _heroWeatherSub(
                          state.tr('wind'),
                          '${weather.windSpeedKmh?.toStringAsFixed(0) ?? '0'} km/h',
                          Icons.air_rounded,
                        ),
                        _heroWeatherSub(
                          'Source',
                          weather.dataSource,
                          Icons.sensors_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ===============================================================
              // 2. FORECAST TIMELINE CARDS
              // ===============================================================
              SectionHeader(
                title: state.tr('forecast_coverage_title'),
                subtitle: 'Upcoming regional micro-climate observations',
              ),
              const SizedBox(height: 4),
              if (forecast.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 18,
                  child: Text(
                    state.tr('no_forecast_points'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: forecast.length,
                    itemBuilder: (context, idx) {
                      final point = forecast[idx];
                      return Container(
                        width: 130,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.charcoalSurface : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : const Color(0xFFE5EDE7),
                          ),
                          boxShadow: isDark
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Color(0x080D3D22),
                                    blurRadius: 10,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${point.timestamp.toLocal().day}/${point.timestamp.toLocal().month} ${point.timestamp.toLocal().hour}:00',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${point.temperatureCelsius.toStringAsFixed(0)}°C',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                                  ),
                                ),
                                const Icon(
                                  Icons.cloud_rounded,
                                  size: 20,
                                  color: Color(0xFF0F6E3B),
                                ),
                              ],
                            ),
                            Text(
                              '${state.tr('rain_label')}: ${point.rainfallMm?.toStringAsFixed(1) ?? '0.0'} mm',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // ===============================================================
            // 3. SMART IRRIGATION ASSESSMENT CALCULATOR
            // ===============================================================
            SectionHeader(
              title: state.tr('irrigation_assessment'),
              subtitle: state.tr('irrigation_description'),
            ),
            const SizedBox(height: 4),
            AppCard(
              padding: const EdgeInsets.all(20),
              borderRadius: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _crop,
                    decoration: InputDecoration(
                      labelText: state.tr('crop_name'),
                      hintText: 'e.g. Cotton, Rice, Chilli',
                      prefixIcon: const Icon(Icons.grass_rounded, color: AppColors.forestPine),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _moisture,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: state.tr('soil_moisture'),
                      hintText: '0 - 100%',
                      prefixIcon: const Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
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
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardElevatedDark : const Color(0xFFF9FAF8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFE2EBE5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.forestPine),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _lastIrrigation == null
                                  ? state.tr('select_last_irrigation_date')
                                  : '${state.tr('last_irrigation')}: ${_fmtDate(_lastIrrigation!)}',
                              style: TextStyle(
                                fontSize: 14.5,
                                color: _lastIrrigation == null ? AppColors.textMuted : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    text: state.tr(_busy ? 'assessing' : 'get_assessment'),
                    icon: Icons.water_drop_rounded,
                    isLoading: _busy,
                    isPill: true,
                    height: 52,
                    onPressed: _busy ? null : _assessIrrigation,
                  ),
                ],
              ),
            ),

            if (_irrigationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDEA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFB4AB)),
                ),
                child: Text(
                  _irrigationError!,
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            if (_assessment != null) ...[
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.mistMint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: AppColors.forestPine, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${state.tr('assessment')}: ${_assessment!['recommendation'] ?? state.tr('unavailable')}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      state.currentLanguage == 'te'
                          ? '${_assessment!['advisory_te'] ?? ''}'
                          : '${_assessment!['advisory_en'] ?? ''}',
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${state.tr('next_assessment_date')}: ${_assessment!['next_assessment_date'] ?? state.tr('unavailable')}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    if ((_assessment!['missing_information'] as List? ?? const []).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${state.tr('missing_information')}: ${(_assessment!['missing_information'] as List).join(', ')}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _heroWeatherSub(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.limeAccent),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
