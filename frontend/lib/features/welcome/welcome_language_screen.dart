import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

/// Screen 1: Premium Modern Welcome & Language Selection Screen.
class WelcomeLanguageScreen extends StatelessWidget {
  const WelcomeLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightCanopy : const Color(0xFFF6F8F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Green Header Curve Banner
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A2E1B), Color(0xFF134A2C), Color(0xFF185A36)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  child: Column(
                    children: [
                      // Hero Brand Emblem
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.limeAccent,
                            width: 2.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x30000000),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.eco_rounded,
                            size: 42,
                            color: AppColors.limeAccent,
                          ),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                      const SizedBox(height: 16),

                      Text(
                        state.tr('app_name'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.6,
                        ),
                      ).animate().fadeIn(duration: 350.ms, delay: 100.ms),

                      const SizedBox(height: 8),

                      Text(
                        '${state.tr('app_subtitle')}\n${state.tr('welcome_description')}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ).animate().fadeIn(duration: 350.ms, delay: 150.ms),

                      const SizedBox(height: 20),

                      // Feature Highlights Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _featurePill(Icons.camera_alt_rounded, state.tr('feature_diagnosis')),
                          const SizedBox(width: 8),
                          _featurePill(Icons.cloud_rounded, state.tr('feature_weather')),
                          const SizedBox(width: 8),
                          _featurePill(Icons.trending_up_rounded, state.tr('feature_yield')),
                        ],
                      ).animate().fadeIn(duration: 350.ms, delay: 200.ms),
                    ],
                  ),
                ),
              ),
            ),

            // Overlapping Card for Language Selection
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  padding: const EdgeInsets.all(22.0),
                  borderRadius: 24.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: AppColors.mistMint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.translate_rounded,
                              color: AppColors.forestPine,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.tr('select_language'),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.textDarkPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Choose your preferred voice & text language',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // English Option
                      _languageOptionTile(
                        isSelected: state.currentLanguage == 'en',
                        onTap: () => state.setLanguage('en'),
                        title: state.tr('english'),
                        subtitle: state.tr('language_english_detail'),
                        badge: state.tr('language_standard'),
                        isDark: isDark,
                      ),

                      const SizedBox(height: 12),

                      // Telugu Option
                      _languageOptionTile(
                        isSelected: state.currentLanguage == 'te',
                        onTap: () => state.setLanguage('te'),
                        title: state.tr('telugu'),
                        subtitle: state.tr('language_telugu_detail'),
                        badge: state.tr('language_regional'),
                        isDark: isDark,
                      ),

                      const SizedBox(height: 12),

                      // Hindi Option
                      _languageOptionTile(
                        isSelected: state.currentLanguage == 'hi',
                        onTap: () => state.setLanguage('hi'),
                        title: state.tr('hindi'),
                        subtitle: state.tr('language_hindi_detail'),
                        badge: state.tr('language_regional'),
                        isDark: isDark,
                      ),

                      const SizedBox(height: 24),

                      // Primary Get Started CTA Button
                      AppButton(
                        text: state.tr('get_started'),
                        expanded: true,
                        height: 52,
                        isPill: true,
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Already Registered Link
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.tr('already_registered'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Text(
                        state.tr('login'),
                        style: const TextStyle(
                          color: AppColors.forestPine,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.limeAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageOptionTile({
    required bool isSelected,
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required String badge,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.deepWoodland
                    : const Color(0xFFEFF8F3))
              : (isDark ? AppColors.cardElevatedDark : const Color(0xFFF9FAF8)),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? AppColors.forestPine : const Color(0xFFE2EBE5),
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.forestPine : AppColors.textMuted,
                  width: 2.0,
                ),
                color: isSelected ? AppColors.forestPine : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 13, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? (isDark ? AppColors.textDarkPrimary : AppColors.forestPine)
                              : (isDark ? AppColors.textDarkPrimary : AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.mistMint
                              : (isDark ? Colors.white10 : const Color(0xFFEFF3F0)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.forestPine
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
