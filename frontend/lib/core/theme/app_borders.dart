import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Border Tokens for AgriVerse AI.
class AppBorders {
  static const double thinWidth = 1.0;
  static const double standardWidth = 1.2;
  static const double activeWidth = 2.0;

  // Reusable border sides (Light)
  static const BorderSide subtle = BorderSide(
    color: AppColors.borderLight,
    width: standardWidth,
  );

  static const BorderSide medium = BorderSide(
    color: AppColors.borderMedium,
    width: standardWidth,
  );

  static const BorderSide focused = BorderSide(
    color: AppColors.borderFocused,
    width: activeWidth,
  );

  static const BorderSide error = BorderSide(
    color: AppColors.error,
    width: standardWidth,
  );

  static const BorderSide errorFocused = BorderSide(
    color: AppColors.error,
    width: activeWidth,
  );

  // Full Borders
  static Border get cardLight =>
      Border.all(color: AppColors.borderLight, width: standardWidth);

  static Border get cardDark =>
      Border.all(color: AppColors.borderDark, width: standardWidth);
}
