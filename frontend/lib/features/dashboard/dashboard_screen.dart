import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_card.dart';
import '../../widgets/design_components.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/state_views.dart';
import '../../widgets/tts_button.dart';
import '../crops/smart_crop_recommendation_screen.dart';
import '../weather/weather_irrigation_screen.dart';
import '../health/crop_health_screen.dart';
import '../finance/yield_profit_estimator_screen.dart';
import '../assistant/personal_assistant_screen.dart';
import '../profile/farmer_profile_screen.dart';
import '../settings/farm_history_settings_screen.dart';

/// Screen 4: World-Class Farmer Dashboard Hero Screen.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  void _onBottomNavSelected(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FarmerProfileScreen()),
      ).then((_) => setState(() => _currentNavIndex = 0));
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PersonalAssistantScreen()),
      ).then((_) => setState(() => _currentNavIndex = 0));
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FarmHistorySettingsScreen()),
      ).then((_) => setState(() => _currentNavIndex = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final profile = state.currentProfile;
    final activeCrop = state.activeCropCycle;
    final weather = state.weatherData;
    final farms = state.farms;

    final farmerName = profile?.fullName ?? state.tr('farmer');
    final locationText = [
      profile?.village,
      profile?.district,
      profile?.state,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
    final location = profile?.district ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: AppColors.limeAccent,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: AppColors.forestGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AgriVerse AI',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        actions: [
          TtsButton(
            textToSpeak: weather == null
                ? 'Welcome ${profile?.fullName ?? "Farmer"}. Weather information is not available.'
                : 'Welcome ${profile?.fullName ?? "Farmer"}. Current temperature in $location is ${weather.temperatureCelsius} degrees Celsius.',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.currentLanguage.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            tooltip: state.tr('select_language'),
            onPressed: () {
              final nextLanguage = switch (state.currentLanguage) {
                'en' => 'te',
                'te' => 'hi',
                _ => 'en',
              };
              state.setLanguage(nextLanguage);
            },
          ),
          Tooltip(
            message: state.tr('simple_mode'),
            child: IconButton(
              icon: Icon(
                state.isSimpleMode
                    ? Icons.accessibility_new_rounded
                    : Icons.accessibility_rounded,
                color: state.isSimpleMode
                    ? AppColors.limeAccent
                    : Colors.white70,
              ),
              onPressed: () => state.toggleSimpleMode(),
            ),
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: RefreshIndicator(
        color: AppColors.emerald,
        onRefresh: () => state.loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Telemetry status banner
              DataSourceBanner(
                text: state.weatherState.isLoading
                    ? state.tr('current_weather_loading')
                    : state.weatherState.hasError
                    ? state.tr('weather_temporarily_unavailable')
                    : weather == null
                    ? state.tr('no_weather_requested')
                    : 'Current observation from ${weather.dataSource}',
                isWarning: state.weatherState.hasError,
              ),

              if (state.isSimpleMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  color: AppColors.limeAccent.withValues(alpha: 0.35),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.accessibility_new_rounded,
                        size: 24,
                        color: AppColors.forestGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.tr('simple_mode_on'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HERO GREETING CARD
                    HeroDarkCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceWhite.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.limeAccent.withValues(
                                          alpha: 0.6,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 32,
                                      color: AppColors.surfaceWhite,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              state.tr('welcome_farmer'),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.limeAccent,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          farmerName,
                                          style: const TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.surfaceWhite,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              size: 14,
                                              color:
                                                  AppColors.textOnDarkSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              locationText.isEmpty
                                                  ? state.tr('location_not_set')
                                                  : locationText,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors
                                                    .textOnDarkSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 10.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(14.0),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _heroMetricItem(
                                      state.tr('registered_land'),
                                      '${farms.fold<double>(0, (sum, f) => sum + f.landAreaAcres).toStringAsFixed(1)} ${state.tr('acres')}',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 26,
                                      color: Colors.white24,
                                    ),
                                    _heroMetricItem(
                                      state.tr('active_parcels'),
                                      '${farms.length} ${state.tr('fields')}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.04, end: 0),

                    const SizedBox(height: 14),

                    // ATMOSPHERIC WEATHER & IRRIGATION SUMMARY
                    AppCard(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F3B5C), Color(0xFF1E5E8A)],
                      ),
                      borderRadius: 20.0,
                      padding: const EdgeInsets.all(20.0),
                      border: Border.all(
                        color: const Color(0xFF2E75A6),
                        width: 1.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.wb_sunny_rounded,
                                      color: Colors.amberAccent,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.tr('weather_summary'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        weather?.forecastCondition ??
                                            (state.weatherState.isLoading
                                                ? state.tr('loading')
                                                : state.tr(
                                                    'weather_unavailable',
                                                  )),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                weather == null
                                    ? '—'
                                    : '${weather.temperatureCelsius.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _weatherSubMetric(
                                  state.tr('humidity_short'),
                                  weather?.humidityPercentage == null
                                      ? state.tr('unavailable')
                                      : '${weather!.humidityPercentage!.toStringAsFixed(0)}%',
                                  Icons.water_drop_rounded,
                                ),
                                _weatherSubMetric(
                                  state.tr('rainfall_short'),
                                  weather?.rainfallMm == null
                                      ? state.tr('unavailable')
                                      : '${weather!.rainfallMm!.toStringAsFixed(1)} mm',
                                  Icons.grain_rounded,
                                ),
                                _weatherSubMetric(
                                  state.tr('wind_short'),
                                  weather?.windSpeedKmh == null
                                      ? state.tr('unavailable')
                                      : '${weather!.windSpeedKmh!.toStringAsFixed(1)} km/h',
                                  Icons.air_rounded,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.tips_and_updates_rounded,
                                color: AppColors.limeAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  weather == null
                                      ? (state.weatherState.errorMessage ??
                                            state.tr('no_weather_advisory'))
                                      : state.currentLanguage == 'te'
                                      ? weather.advisoryTe
                                      : weather.advisoryEn,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontSize: 13.5,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 60.ms),

                    const SizedBox(height: 16),

                    // ACTIVE CROP STATUS CARD
                    SectionHeader(
                      title: state.tr('current_crop_cycle'),
                      subtitle: state.tr('current_field_cycle'),
                      trailing: TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FarmerProfileScreen(),
                          ),
                        ),
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.emerald,
                        ),
                        label: Text(
                          state.tr('view_all'),
                          style: const TextStyle(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    AppCard(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.grass_rounded,
                                  color: AppColors.emerald,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (state.activeCropCycleState.isLoading)
                                      Text(state.tr('loading'))
                                    else if (state
                                        .activeCropCycleState
                                        .hasError)
                                      Text(
                                        state
                                                .activeCropCycleState
                                                .errorMessage ??
                                            state.tr('connection_error'),
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        activeCrop?.cropName ??
                                            state.tr('no_active_crop_cycle'),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        activeCrop == null
                                            ? state.tr('add_crop_cycle_help')
                                            : '${state.tr('variety')}: ${activeCrop.variety}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (state.activeCropCycleState.isSuccess)
                                FarmStatusBadge(
                                  label: activeCrop == null
                                      ? state.tr('no_cycle')
                                      : state.tr(
                                          'stage_${activeCrop.stage.toLowerCase()}',
                                        ),
                                  icon: Icons.spa_rounded,
                                  color: AppColors.emerald,
                                ),
                            ],
                          ),
                          if (activeCrop != null) ...[
                            const Divider(height: 24),
                            Text(
                              '${state.tr('sowing_date')}: ${activeCrop.sowingDate}',
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 120.ms),

                    const SizedBox(height: 16),

                    // RECOMMENDED ACTIONS & TASKS
                    SectionHeader(
                      title: state.tr('next_tasks'),
                      subtitle: state.tr('rule_based_farm_inputs'),
                    ),
                    AppCard(
                      padding: const EdgeInsets.all(16.0),
                      child: state.recommendationsState.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : state.recommendationsState.hasError
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.recommendationsState.errorMessage ??
                                      state.tr('recommendations_unavailable'),
                                ),
                                TextButton(
                                  onPressed: state.loadDashboardData,
                                  child: Text(state.tr('retry')),
                                ),
                              ],
                            )
                          : state.recommendations.isEmpty
                          ? Text(state.tr('add_farm_for_recommendations'))
                          : Column(
                              children: state.recommendations
                                  .map(
                                    (recommendation) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.eco_outlined,
                                            color: AppColors.emerald,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  recommendation.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  state.currentLanguage == 'te'
                                                      ? recommendation.detailsTe
                                                      : recommendation
                                                            .detailsEn,
                                                ),
                                                Text(
                                                  '${state.tr('crop_prefix')}: ${recommendation.cropName} · ${state.tr('method_prefix')}: ${recommendation.methodology.replaceAll('_', ' ')}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ).animate().fadeIn(duration: 400.ms, delay: 180.ms),

                    const SizedBox(height: 20),

                    // CORE SERVICE MODULES GRID
                    SectionHeader(
                      title: state.tr('smart_agricultural_services'),
                      subtitle: state.tr('services_description'),
                    ),
                    GridView.count(
                      crossAxisCount: state.isSimpleMode ? 1 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: state.isSimpleMode ? 2.6 : 1.15,
                      children: [
                        AnimatedActionCard(
                          title: state.tr('crop_health'),
                          subtitle: state.tr('screen_crop_image'),
                          icon: Icons.camera_alt_rounded,
                          iconColor: const Color(0xFFE65100),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CropHealthScreen(),
                            ),
                          ),
                        ),
                        AnimatedActionCard(
                          title: state.tr('smart_recommendation'),
                          subtitle: state.tr('screen_crops_by_conditions'),
                          icon: Icons.psychology_rounded,
                          iconColor: AppColors.emerald,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SmartCropRecommendationScreen(),
                            ),
                          ),
                        ),
                        AnimatedActionCard(
                          title: state.tr('weather_summary'),
                          subtitle: state.tr('forecast_and_irrigation'),
                          icon: Icons.water_drop_rounded,
                          iconColor: const Color(0xFF0277BD),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WeatherIrrigationScreen(),
                            ),
                          ),
                        ),
                        AnimatedActionCard(
                          title: state.tr('yield_estimator'),
                          subtitle: state.tr('estimate_user_values'),
                          icon: Icons.calculate_rounded,
                          iconColor: const Color(0xFF6A1B9A),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const YieldProfitEstimatorScreen(),
                            ),
                          ),
                        ),
                        AnimatedActionCard(
                          title: state.tr('personal_assistant'),
                          subtitle: state.tr('ask_assistant_provider'),
                          icon: Icons.support_agent_rounded,
                          iconColor: const Color(0xFF00897B),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PersonalAssistantScreen(),
                            ),
                          ),
                        ),
                        AnimatedActionCard(
                          title: state.tr('farmer_profile'),
                          subtitle: state.tr('manage_farm_details'),
                          icon: Icons.landscape_rounded,
                          iconColor: AppColors.forestGreen,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FarmerProfileScreen(),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms, delay: 240.ms),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTabSelected: _onBottomNavSelected,
      ),
    );
  }

  Widget _heroMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Widget _weatherSubMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
