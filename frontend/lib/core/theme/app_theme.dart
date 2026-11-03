import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radii.dart';
import 'app_borders.dart';

/// Centralized Material 3 Theme for AgriVerse AI.
/// Implements the "Agronomic Editorial & Ambient Precision" design system.
class AppTheme {
  // ---------------------------------------------------------------------------
  // Light Theme Specification
  // ---------------------------------------------------------------------------
  static ThemeData lightTheme({bool isSimpleMode = false}) {
    final textTheme = AppTypography.textTheme(
      isSimpleMode: isSimpleMode,
      isDark: false,
    );
    final double radiusValue = isSimpleMode
        ? AppRadii.xlValue
        : AppRadii.lgValue;
    final borderRadius = BorderRadius.circular(radiusValue);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.forestPine,
        onPrimary: AppColors.surfaceWhite,
        primaryContainer: AppColors.mistMint,
        onPrimaryContainer: AppColors.forestPine,
        secondary: AppColors.harvestGold,
        onSecondary: AppColors.surfaceWhite,
        secondaryContainer: Color(0xFFFEF3C7),
        onSecondaryContainer: Color(0xFF92400E),
        tertiary: AppColors.terracotta,
        onTertiary: AppColors.surfaceWhite,
        surface: AppColors.surfaceWhite,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.surfaceWhite,
      ),
      scaffoldBackgroundColor: AppColors.warmAlabaster,
      textTheme: textTheme,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.forestPine,
        foregroundColor: AppColors.surfaceWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.surfaceWhite,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.surfaceWhite),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: AppBorders.subtle,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
      ),

      // Elevated Button Theme (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestPine,
          foregroundColor: AppColors.surfaceWhite,
          elevation: 0,
          minimumSize: Size(double.infinity, isSimpleMode ? 56.0 : 48.0),
          padding: EdgeInsets.symmetric(
            horizontal: isSimpleMode ? 26.0 : 20.0,
            vertical: isSimpleMode ? 18.0 : 14.0,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forestPine,
          side: const BorderSide(color: AppColors.forestPine, width: 1.5),
          minimumSize: Size(double.infinity, isSimpleMode ? 56.0 : 48.0),
          padding: EdgeInsets.symmetric(
            horizontal: isSimpleMode ? 24.0 : 18.0,
            vertical: isSimpleMode ? 16.0 : 12.0,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forestPine,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.smValue),
          ),
        ),
      ),

      // Text Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18.0,
          vertical: isSimpleMode ? 18.0 : 15.0,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: AppBorders.medium,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: AppBorders.subtle,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: AppBorders.focused,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: AppBorders.error,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: AppBorders.errorFocused,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        selectedItemColor: AppColors.forestPine,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12.0,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.warmOat,
        selectedColor: AppColors.mistMint,
        side: const BorderSide(color: AppColors.borderLight, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.smValue),
        ),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xlValue),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.topSheet),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1.0,
        space: 20.0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepWoodland,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.surfaceWhite,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.mdValue),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.luminousSage,
        linearTrackColor: AppColors.mistMint,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dark Theme Specification
  // ---------------------------------------------------------------------------
  static ThemeData darkTheme({bool isSimpleMode = false}) {
    final textTheme = AppTypography.textTheme(
      isSimpleMode: isSimpleMode,
      isDark: true,
    );
    final double radiusValue = isSimpleMode
        ? AppRadii.xlValue
        : AppRadii.lgValue;
    final borderRadius = BorderRadius.circular(radiusValue);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.luminousSage,
        onPrimary: AppColors.nightCanopy,
        primaryContainer: AppColors.deepWoodland,
        onPrimaryContainer: AppColors.mistMint,
        secondary: AppColors.warmHoney,
        onSecondary: AppColors.nightCanopy,
        secondaryContainer: Color(0xFF452B0E),
        onSecondaryContainer: AppColors.warmHoney,
        tertiary: AppColors.sunlitClay,
        onTertiary: AppColors.nightCanopy,
        surface: AppColors.charcoalSurface,
        onSurface: AppColors.textDarkPrimary,
        error: AppColors.error,
        onError: AppColors.surfaceWhite,
      ),
      scaffoldBackgroundColor: AppColors.nightCanopy,
      textTheme: textTheme,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.charcoalSurface,
        foregroundColor: AppColors.textDarkPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.textDarkPrimary,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: const IconThemeData(color: AppColors.textDarkPrimary),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.charcoalSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: const BorderSide(color: AppColors.borderDark, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
      ),

      // Elevated Button Theme (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.luminousSage,
          foregroundColor: AppColors.nightCanopy,
          elevation: 0,
          minimumSize: Size(double.infinity, isSimpleMode ? 56.0 : 48.0),
          padding: EdgeInsets.symmetric(
            horizontal: isSimpleMode ? 26.0 : 20.0,
            vertical: isSimpleMode ? 18.0 : 14.0,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.nightCanopy,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.luminousSage,
          side: const BorderSide(color: AppColors.luminousSage, width: 1.5),
          minimumSize: Size(double.infinity, isSimpleMode ? 56.0 : 48.0),
          padding: EdgeInsets.symmetric(
            horizontal: isSimpleMode ? 24.0 : 18.0,
            vertical: isSimpleMode ? 16.0 : 12.0,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),

      // Text Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardElevatedDark,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18.0,
          vertical: isSimpleMode ? 18.0 : 15.0,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textDarkMuted,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textDarkSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(
            color: AppColors.luminousSage,
            width: 2.0,
          ),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.charcoalSurface,
        selectedItemColor: AppColors.luminousSage,
        unselectedItemColor: AppColors.textDarkSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cardElevatedDark,
        selectedColor: AppColors.deepWoodland,
        side: const BorderSide(color: AppColors.borderDark, width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.smValue),
        ),
        labelStyle: textTheme.labelMedium,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.charcoalSurface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xlValue),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.charcoalSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.topSheet),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1.0,
        space: 20.0,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardElevatedDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textDarkPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.mdValue),
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.luminousSage,
        linearTrackColor: AppColors.deepWoodland,
      ),
    );
  }
}
