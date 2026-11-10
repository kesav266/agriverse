import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_card.dart';
import '../../widgets/card_illustrations.dart';
import '../../widgets/design_components.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/tts_button.dart';
import '../crops/smart_crop_recommendation_screen.dart';
import '../weather/weather_irrigation_screen.dart';
import '../health/crop_health_screen.dart';
import '../finance/yield_profit_estimator_screen.dart';
import '../assistant/personal_assistant_screen.dart';
import '../profile/farmer_profile_screen.dart';
import '../settings/farm_history_settings_screen.dart';

/// Screen 4: World-Class Modern AgriTech Farmer Dashboard Screen.
/// Inspired by modern agricultural intelligence dashboards with deep forest header,
/// overlapping floating weather telemetry card, service category tiles, and real-time alerts.
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

  String _formatCurrentDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final weekday = weekdays[(now.weekday - 1) % 7];
    final month = months[(now.month - 1) % 12];
    return '$weekday, ${now.day.toString().padLeft(2, '0')} $month ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDark ? AppColors.nightCanopy : const Color(0xFFF6F8F5),
      drawer: const MainDrawer(),
      body: RefreshIndicator(
        color: AppColors.forestPine,
        onRefresh: () => state.loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // ===============================================================
              // 1. HERO FOREST GREEN HEADER (matching reference image)
              // ===============================================================
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A2E1B), Color(0xFF134A2C), Color(0xFF185A36)],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x220A2E1B),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top App Bar Row: Drawer button, Greeting, Avatar & Quick Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(
                              builder: (ctx) => InkWell(
                                onTap: () => Scaffold.of(ctx).openDrawer(),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.menu_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Hello, Good Morning',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.limeAccent,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    farmerName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Quick Action Tools: Language, TTS, Avatar
                            Row(
                              children: [
                                TtsButton(
                                  textToSpeak: weather == null
                                      ? 'Welcome $farmerName. Weather information is not available.'
                                      : 'Welcome $farmerName. Current temperature in $location is ${weather.temperatureCelsius} degrees Celsius.',
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    final next = switch (state.currentLanguage) {
                                      'en' => 'te',
                                      'te' => 'hi',
                                      _ => 'en',
                                    };
                                    state.setLanguage(next);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      state.currentLanguage.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const FarmerProfileScreen(),
                                    ),
                                  ),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.limeAccent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Date & Location dropdown indicator (matching image)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatCurrentDate(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Translucent Search & Voice Query Bar (matching image)
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PersonalAssistantScreen(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.pillValue),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(AppRadii.pillValue),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    state.tr('ask_assistant_provider'),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.75),
                                      fontSize: 13.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Land & Parcel Stats Summary Ribbon
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _headerMetricItem(
                                state.tr('registered_land'),
                                '${farms.fold<double>(0, (sum, f) => sum + f.landAreaAcres).toStringAsFixed(1)} ${state.tr('acres')}',
                                Icons.landscape_rounded,
                              ),
                              Container(
                                width: 1,
                                height: 26,
                                color: Colors.white24,
                              ),
                              _headerMetricItem(
                                state.tr('active_parcels'),
                                '${farms.length} ${state.tr('fields')}',
                                Icons.grid_view_rounded,
                              ),
                              if (activeCrop != null) ...[
                                Container(
                                  width: 1,
                                  height: 26,
                                  color: Colors.white24,
                                ),
                                _headerMetricItem(
                                  activeCrop.cropName,
                                  activeCrop.stage,
                                  Icons.eco_rounded,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ===============================================================
              // 2. OVERLAPPING FLOATING WEATHER CARD (matching reference image)
              // ===============================================================
              Transform.translate(
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoalSurface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE5EDE7),
                        width: 1.2,
                      ),
                      boxShadow: isDark
                          ? AppShadows.darkElevated
                          : const [
                              BoxShadow(
                                color: Color(0x140D3D22),
                                blurRadius: 24,
                                offset: Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: AppColors.forestPine,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  locationText.isEmpty
                                      ? (location.isEmpty ? 'Regional Center' : location)
                                      : locationText,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textDarkPrimary
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mistMint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                weather?.forecastCondition ??
                                    (state.weatherState.isLoading
                                        ? state.tr('loading')
                                        : 'Live'),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forestPine,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Temperature & Icon Row (matching reference image)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  weather == null
                                      ? '—'
                                      : '+${weather.temperatureCelsius.toStringAsFixed(0)}°C',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.5,
                                    color: isDark
                                        ? AppColors.textDarkPrimary
                                        : AppColors.textHeadline,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (weather != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'H: ${(weather.temperatureCelsius + 3.0).toStringAsFixed(0)}°C',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          'L: ${(weather.temperatureCelsius - 4.0).toStringAsFixed(0)}°C',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            // Weather Condition Graphic
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF8F3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFD4E8DC),
                                ),
                              ),
                              child: Icon(
                                _weatherIcon(weather?.forecastCondition),
                                size: 36,
                                color: const Color(0xFF0F6E3B),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 4-Metric Tiles (Humidity, Precipitation, Pressure, Wind)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardElevatedDark
                                : const Color(0xFFF7FAF8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFE6EFE9),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _weatherStatChip(
                                'Humidity',
                                weather?.humidityPercentage == null
                                    ? '—'
                                    : '${weather!.humidityPercentage!.toStringAsFixed(0)}%',
                                Icons.water_drop_rounded,
                                const Color(0xFF0284C7),
                              ),
                              Container(width: 1, height: 28, color: const Color(0xFFDCE6DF)),
                              _weatherStatChip(
                                'Rainfall',
                                weather?.rainfallMm == null
                                    ? '—'
                                    : '${weather!.rainfallMm!.toStringAsFixed(1)} mm',
                                Icons.grain_rounded,
                                const Color(0xFF2563EB),
                              ),
                              Container(width: 1, height: 28, color: const Color(0xFFDCE6DF)),
                              _weatherStatChip(
                                'Wind',
                                weather?.windSpeedKmh == null
                                    ? '—'
                                    : '${weather!.windSpeedKmh!.toStringAsFixed(0)} km/h',
                                Icons.air_rounded,
                                const Color(0xFF0D9488),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Sunrise / Sunset Visual Arc
                        const SunriseArcWidget(
                          sunrise: '5:25 am',
                          sunset: '6:45 pm',
                          progress: 0.62,
                        ),

                        const SizedBox(height: 12),

                        // Agricultural Advisory Alert Banner
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5EE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCFE8D7)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.tips_and_updates_rounded,
                                color: Color(0xFF136838),
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
                                  style: const TextStyle(
                                    color: Color(0xFF144D2B),
                                    fontSize: 12.5,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ===============================================================
              // 3. CORE SERVICE MODULES GRID ("Invest by Category" Style)
              // ===============================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: state.tr('smart_agricultural_services'),
                      subtitle: state.tr('services_description'),
                    ),
                    const SizedBox(height: 8),

                    // Quick-Access Category Shortcut Ribbon (Matching Reference Panel 1)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _categoryTile(
                            context: context,
                            label: state.tr('crop_health'),
                            icon: Icons.camera_alt_rounded,
                            color: const Color(0xFFE65100),
                            bgColor: const Color(0xFFFFF3E0),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CropHealthScreen(),
                              ),
                            ),
                          ),
                          _categoryTile(
                            context: context,
                            label: state.tr('smart_recommendation'),
                            icon: Icons.psychology_rounded,
                            color: AppColors.forestPine,
                            bgColor: const Color(0xFFE8F5E9),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SmartCropRecommendationScreen(),
                              ),
                            ),
                          ),
                          _categoryTile(
                            context: context,
                            label: state.tr('weather_summary'),
                            icon: Icons.water_drop_rounded,
                            color: const Color(0xFF0284C7),
                            bgColor: const Color(0xFFE0F7FA),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WeatherIrrigationScreen(),
                              ),
                            ),
                          ),
                          _categoryTile(
                            context: context,
                            label: state.tr('yield_estimator'),
                            icon: Icons.calculate_rounded,
                            color: const Color(0xFF7C3AED),
                            bgColor: const Color(0xFFF3E5F5),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const YieldProfitEstimatorScreen(),
                              ),
                            ),
                          ),
                          _categoryTile(
                            context: context,
                            label: state.tr('personal_assistant'),
                            icon: Icons.support_agent_rounded,
                            color: const Color(0xFF0D9488),
                            bgColor: const Color(0xFFE0F2F1),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PersonalAssistantScreen(),
                              ),
                            ),
                          ),
                          _categoryTile(
                            context: context,
                            label: state.tr('farmer_profile'),
                            icon: Icons.landscape_rounded,
                            color: const Color(0xFF15803D),
                            bgColor: const Color(0xFFE8F5E9),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FarmerProfileScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Intelligent Farming Tools - Responsive Cards Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = state.isSimpleMode
                            ? 1
                            : (width > 680 ? 3 : 2);
                        final colWidth = (width - (crossAxisCount - 1) * 12) / crossAxisCount;
                        final cardHeight = state.isSimpleMode ? 82.0 : 194.0;
                        final childAspectRatio = (colWidth / cardHeight).clamp(0.72, 3.8);

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: childAspectRatio,
                          children: [
                            AnimatedActionCard(
                              title: state.tr('crop_health'),
                              subtitle: state.tr('screen_crop_image'),
                              icon: Icons.camera_alt_rounded,
                              iconColor: const Color(0xFFE65100),
                              badgeText: 'AI SCAN',
                              illustration: state.isSimpleMode
                                  ? null
                                  : const CardIllustration(
                                      type: CardIllustrationType.cropHealth,
                                      height: 112,
                                    ),
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
                              iconColor: AppColors.forestPine,
                              badgeText: 'ADVISOR',
                              illustration: state.isSimpleMode
                                  ? null
                                  : const CardIllustration(
                                      type: CardIllustrationType.cropRecommendation,
                                      height: 112,
                                    ),
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
                              iconColor: const Color(0xFF0284C7),
                              badgeText: 'RADAR',
                              illustration: state.isSimpleMode
                                  ? null
                                  : const CardIllustration(
                                      type: CardIllustrationType.weather,
                                      height: 112,
                                    ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const WeatherIrrigationScreen(),
                                ),
                              ),
                            ),
                            AnimatedActionCard(
                              title: state.tr('yield_estimator'),
                              subtitle: state.tr('estimate_user_values'),
                              icon: Icons.calculate_rounded,
                              iconColor: const Color(0xFF7C3AED),
                              badgeText: 'PROFIT',
                              illustration: state.isSimpleMode
                                  ? null
                                  : const CardIllustration(
                                      type: CardIllustrationType.yieldProfit,
                                      height: 112,
                                    ),
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
                              iconColor: const Color(0xFF0D9488),
                              badgeText: 'COPILOT',
                              illustration: state.isSimpleMode
                                  ? null
                                  : const CardIllustration(
                                      type: CardIllustrationType.aiAssistant,
                                      height: 112,
                                    ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const PersonalAssistantScreen(),
                                ),
                              ),
                            ),
                            AnimatedActionCard(
                              title: state.tr('farmer_profile'),
                              subtitle: state.tr('manage_farm_details'),
                              icon: Icons.landscape_rounded,
                              iconColor: const Color(0xFF15803D),
                              badgeText: 'FARMS',
                              illustration: state.isSimpleMode
                                  ? null
                                  : const CardIllustration(
                                      type: CardIllustrationType.farmProfile,
                                      height: 112,
                                    ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FarmerProfileScreen(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    // =========================================================
                    // 4. ACTIVE CROP STATUS ("Best Offers" Style Card)
                    // =========================================================
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
                          color: AppColors.forestPine,
                        ),
                        label: Text(
                          state.tr('view_all'),
                          style: const TextStyle(
                            color: AppColors.forestPine,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    AppCard(
                      padding: const EdgeInsets.all(18.0),
                      borderRadius: 20.0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: AppColors.mistMint,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.grass_rounded,
                                  color: AppColors.forestPine,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (state.activeCropCycleState.isLoading)
                                      Text(state.tr('loading'))
                                    else if (state.activeCropCycleState.hasError)
                                      Text(
                                        state.activeCropCycleState.errorMessage ??
                                            state.tr('connection_error'),
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        activeCrop?.cropName ??
                                            state.tr('no_active_crop_cycle'),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: isDark
                                              ? AppColors.textDarkPrimary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
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
                              if (state.activeCropCycleState.isSuccess && activeCrop != null)
                                FarmStatusBadge(
                                  label: state.tr(
                                    'stage_${activeCrop.stage.toLowerCase()}',
                                  ),
                                  icon: Icons.spa_rounded,
                                  color: AppColors.forestPine,
                                ),
                            ],
                          ),
                          if (activeCrop != null) ...[
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${state.tr('sowing_date')}: ${activeCrop.sowingDate}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (activeCrop.expectedHarvestDate != null &&
                                    activeCrop.expectedHarvestDate!.isNotEmpty)
                                  Text(
                                    'Harvest: ${activeCrop.expectedHarvestDate!}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =========================================================
                    // 5. RECOMMENDED ACTIONS / NEXT TASKS
                    // =========================================================
                    SectionHeader(
                      title: state.tr('next_tasks'),
                      subtitle: state.tr('rule_based_farm_inputs'),
                    ),
                    AppCard(
                      padding: const EdgeInsets.all(16.0),
                      borderRadius: 20.0,
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
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                state.tr('add_farm_for_recommendations'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : Column(
                              children: state.recommendations
                                  .map(
                                    (recommendation) => Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAF8),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE5EDE7),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.mistMint,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.eco_rounded,
                                              color: AppColors.forestPine,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  recommendation.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14.5,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  state.currentLanguage == 'te'
                                                      ? recommendation.detailsTe
                                                      : recommendation.detailsEn,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color: AppColors.textSecondary,
                                                    height: 1.35,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${state.tr('crop_prefix')}: ${recommendation.cropName} · ${state.tr('method_prefix')}: ${recommendation.methodology.replaceAll('_', ' ')}',
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
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
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
  bottomNavigationBar: AppBottomNav(
        currentIndex: _currentNavIndex,
        onTabSelected: _onBottomNavSelected,
      ),
    );
  }

  Widget _headerMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.limeAccent),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _weatherStatChip(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  IconData _weatherIcon(String? condition) {
    if (condition == null) return Icons.wb_sunny_rounded;
    final lower = condition.toLowerCase();
    if (lower.contains('rain') || lower.contains('shower')) {
      return Icons.grain_rounded;
    }
    if (lower.contains('cloud')) {
      return Icons.cloud_rounded;
    }
    if (lower.contains('thunder')) {
      return Icons.thunderstorm_rounded;
    }
    return Icons.wb_sunny_rounded;
  }

  Widget _categoryTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 86,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoalSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE5EDE7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : const Color(0x0A0D3D22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
