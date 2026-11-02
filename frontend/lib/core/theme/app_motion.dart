import 'package:flutter/material.dart';

/// Centralized Motion & Animation Tokens for AgriVerse AI.
/// Optimized for 60 FPS transitions and battery efficiency on mobile hardware.
class AppMotion {
  // Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration relaxed = Duration(milliseconds: 380);
  static const Duration scanner = Duration(milliseconds: 1400);

  // Easing Curves
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.decelerate;
  static const Curve spring = Curves.easeOutBack;

  /// Check whether animations should run based on system accessibility settings.
  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.of(context).disableAnimations;
  }

  /// Get adjusted duration based on accessibility settings.
  static Duration duration(BuildContext context, Duration preferredDuration) {
    if (MediaQuery.of(context).disableAnimations) {
      return Duration.zero;
    }
    return preferredDuration;
  }
}
