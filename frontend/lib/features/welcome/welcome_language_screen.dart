import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/state/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

/// Screen 1: Premium Welcome & Language Selection Screen.
class WelcomeLanguageScreen extends StatelessWidget {
  const WelcomeLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Hero Brand Emblem
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: AppColors.forestHeroGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forestGreen.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
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

              // Title
              Text(
                state.tr('app_name'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 350.ms, delay: 100.ms),

              const SizedBox(height: 6),

              Text(
                '${state.tr('app_subtitle')}\n${state.tr('welcome_description')}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ).animate().fadeIn(duration: 350.ms, delay: 150.ms),

              const SizedBox(height: 24),

              // Value Proposition Pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _featurePill(
                    Icons.camera_alt_rounded,
                    state.tr('feature_diagnosis'),
                  ),
                  const SizedBox(width: 8),
                  _featurePill(
                    Icons.cloud_rounded,
                    state.tr('feature_weather'),
                  ),
                  const SizedBox(width: 8),
                  _featurePill(
                    Icons.trending_up_rounded,
                    state.tr('feature_yield'),
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms, delay: 200.ms),

              const SizedBox(height: 28),

              // Language Selector Card
              AppCard(
                    padding: const EdgeInsets.all(22.0),
                    borderRadius: 22.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.translate_rounded,
                                color: AppColors.emerald,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.tr('select_language'),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // English Option
                        _languageOptionTile(
                          isSelected: state.currentLanguage == 'en',
                          onTap: () => state.setLanguage('en'),
                          title: state.tr('english'),
                          subtitle: state.tr('language_english_detail'),
                          badge: state.tr('language_standard'),
                        ),

                        const SizedBox(height: 12),

                        // Telugu Option
                        _languageOptionTile(
                          isSelected: state.currentLanguage == 'te',
                          onTap: () => state.setLanguage('te'),
                          title: state.tr('telugu'),
                          subtitle: state.tr('language_telugu_detail'),
                          badge: state.tr('language_regional'),
                        ),

                        const SizedBox(height: 12),

                        _languageOptionTile(
                          isSelected: state.currentLanguage == 'hi',
                          onTap: () => state.setLanguage('hi'),
                          title: state.tr('hindi'),
                          subtitle: state.tr('language_hindi_detail'),
                          badge: state.tr('language_regional'),
                        ),

                        const SizedBox(height: 24),

                        // Primary Get Started CTA
                        AppButton(
                          text: state.tr('get_started'),
                          expanded: true,
                          height: 52,
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
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 250.ms)
                  .slideY(begin: 0.05, end: 0),

              const SizedBox(height: 20),

              // Existing Account Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.tr('already_registered'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 2.0,
                      ),
                      child: Text(
                        state.tr('login'),
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 350.ms, delay: 300.ms),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.emerald),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.forestGreen,
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.emerald.withValues(alpha: 0.08)
              : AppColors.warmIvory,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected ? AppColors.emerald : AppColors.borderLight,
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
                  color: isSelected ? AppColors.emerald : AppColors.textMuted,
                  width: 2.0,
                ),
                color: isSelected ? AppColors.emerald : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 13, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
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
                              ? AppColors.forestGreen
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.limeAccent
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.forestGreen
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
