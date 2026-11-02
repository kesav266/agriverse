import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state/app_state_provider.dart';
import '../core/theme/app_colors.dart';
import '../features/welcome/welcome_language_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/profile/farmer_profile_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/crops/smart_crop_recommendation_screen.dart';
import '../features/weather/weather_irrigation_screen.dart';
import '../features/health/crop_health_screen.dart';
import '../features/finance/yield_profit_estimator_screen.dart';
import '../features/assistant/personal_assistant_screen.dart';
import '../features/settings/farm_history_settings_screen.dart';

/// Comprehensive Drawer Navigation providing seamless access to all 10 screens.
class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final profile = state.currentProfile;
    final location = [
      profile?.village,
      profile?.district,
      profile?.state,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');

    return Drawer(
      backgroundColor: AppColors.warmIvory,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.forestHeroGradient,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.limeAccent, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? state.tr('welcome_farmer'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location.isEmpty
                            ? state.tr('location_not_set')
                            : location,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Drawer Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                _drawerTile(
                  context,
                  title: state.tr('dashboard'),
                  icon: Icons.dashboard_rounded,
                  onTap: () => _navigate(context, const DashboardScreen()),
                ),
                _drawerTile(
                  context,
                  title: state.tr('farmer_profile'),
                  icon: Icons.landscape_rounded,
                  onTap: () => _navigate(context, const FarmerProfileScreen()),
                ),
                _drawerTile(
                  context,
                  title: state.tr('smart_recommendation'),
                  icon: Icons.psychology_rounded,
                  onTap: () =>
                      _navigate(context, const SmartCropRecommendationScreen()),
                ),
                _drawerTile(
                  context,
                  title: state.tr('weather_summary'),
                  icon: Icons.cloud_rounded,
                  onTap: () =>
                      _navigate(context, const WeatherIrrigationScreen()),
                ),
                _drawerTile(
                  context,
                  title: state.tr('crop_health'),
                  icon: Icons.camera_alt_rounded,
                  onTap: () => _navigate(context, const CropHealthScreen()),
                ),
                _drawerTile(
                  context,
                  title: state.tr('yield_estimator'),
                  icon: Icons.calculate_rounded,
                  onTap: () =>
                      _navigate(context, const YieldProfitEstimatorScreen()),
                ),
                _drawerTile(
                  context,
                  title: state.tr('personal_assistant'),
                  icon: Icons.support_agent_rounded,
                  onTap: () =>
                      _navigate(context, const PersonalAssistantScreen()),
                ),
                _drawerTile(
                  context,
                  title: state.tr('farm_history_settings'),
                  icon: Icons.history_rounded,
                  onTap: () =>
                      _navigate(context, const FarmHistorySettingsScreen()),
                ),
                _drawerTile(
                  context,
                  title: state.tr('select_language'),
                  icon: Icons.language_rounded,
                  onTap: () =>
                      _navigate(context, const WelcomeLanguageScreen()),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(),
                ),
                _drawerTile(
                  context,
                  title: state.isLoggedIn
                      ? state.tr('logout')
                      : state.tr('login'),
                  icon: state.isLoggedIn
                      ? Icons.logout_rounded
                      : Icons.login_rounded,
                  color: state.isLoggedIn ? AppColors.error : AppColors.emerald,
                  onTap: () async {
                    if (state.isLoggedIn) await state.logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                      (_) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.forestGreen;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: effectiveColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _navigate(BuildContext context, Widget target) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }
}
