import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized Typography Scale for AgriVerse AI.
/// Uses 'Plus Jakarta Sans' with safe platform fallbacks and bilingual support.
/// Dynamically scales for Farmer Simple Mode without breaking visual balance.
class AppTypography {
  static TextStyle _baseStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
    List<FontFeature>? fontFeatures,
  }) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontFamily: 'Roboto',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontFeatures: fontFeatures,
      );
    }
    try {
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontFeatures: fontFeatures,
      );
    } catch (_) {
      // Offline / platform fallback (Roboto on Android, San Francisco on iOS)
      return TextStyle(
        fontFamily: 'Roboto',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontFeatures: fontFeatures,
      );
    }
  }

  /// Master TextTheme for Light and Dark Modes
  static TextTheme textTheme({bool isSimpleMode = false, bool isDark = false}) {
    final scale = isSimpleMode ? 1.20 : 1.0;
    final primaryColor = isDark
        ? AppColors.textDarkPrimary
        : AppColors.textPrimary;
    final secondaryColor = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textSecondary;
    final mutedColor = isDark ? AppColors.textDarkMuted : AppColors.textMuted;

    return TextTheme(
      displayLarge: _baseStyle(
        fontSize: 32 * scale,
        fontWeight: FontWeight.w800,
        color: primaryColor,
        height: 1.18,
        letterSpacing: -0.8,
      ),
      displayMedium: _baseStyle(
        fontSize: 26 * scale,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.22,
        letterSpacing: -0.4,
      ),
      displaySmall: _baseStyle(
        fontSize: 22 * scale,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.26,
        letterSpacing: -0.3,
      ),
      headlineLarge: _baseStyle(
        fontSize: 22 * scale,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.28,
        letterSpacing: -0.3,
      ),
      headlineMedium: _baseStyle(
        fontSize: 19 * scale,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.30,
        letterSpacing: -0.2,
      ),
      headlineSmall: _baseStyle(
        fontSize: 17 * scale,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.32,
      ),
      titleLarge: _baseStyle(
        fontSize: 18 * scale,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        height: 1.35,
      ),
      titleMedium: _baseStyle(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.38,
      ),
      titleSmall: _baseStyle(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        height: 1.40,
      ),
      bodyLarge: _baseStyle(
        fontSize: 15 * scale,
        fontWeight: FontWeight.w500,
        color: primaryColor,
        height: 1.46,
      ),
      bodyMedium: _baseStyle(
        fontSize: 13.5 * scale,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.44,
      ),
      bodySmall: _baseStyle(
        fontSize: 12 * scale,
        fontWeight: FontWeight.w400,
        color: mutedColor,
        height: 1.40,
      ),
      labelLarge: _baseStyle(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: 0.3,
      ),
      labelMedium: _baseStyle(
        fontSize: 12.5 * scale,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        letterSpacing: 0.2,
      ),
      labelSmall: _baseStyle(
        fontSize: 11 * scale,
        fontWeight: FontWeight.w600,
        color: mutedColor,
        letterSpacing: 0.4,
      ),
    );
  }

  /// Numerical Metric Display (High-contrast precision with tabular figures)
  static TextStyle metricValue({
    bool isSimpleMode = false,
    Color? color,
    double fontSize = 28,
  }) {
    final scale = isSimpleMode ? 1.20 : 1.0;
    return _baseStyle(
      fontSize: fontSize * scale,
      fontWeight: FontWeight.w800,
      color: color ?? AppColors.textPrimary,
      letterSpacing: -0.6,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Editorial Hero Display for welcome and prominent banner headers
  static TextStyle displayHero({
    bool isSimpleMode = false,
    Color color = AppColors.forestPine,
  }) {
    final scale = isSimpleMode ? 1.20 : 1.0;
    return _baseStyle(
      fontSize: 32 * scale,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.18,
      letterSpacing: -0.8,
    );
  }
}
