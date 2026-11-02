import 'package:flutter/material.dart';

/// Responsive Breakpoint and Container Helpers for AgriVerse AI.
class ResponsiveLayout {
  // Breakpoints
  static const double compactMobileMaxWidth = 360.0;
  static const double mobileMaxWidth = 600.0;
  static const double tabletMaxWidth = 900.0;
  static const double desktopContentMaxWidth = 1040.0;

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width <= compactMobileMaxWidth;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= mobileMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > mobileMaxWidth &&
      MediaQuery.of(context).size.width <= tabletMaxWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > tabletMaxWidth;

  /// Clamps width to a maximum content container for wider screens
  static Widget constrainedContainer({
    required Widget child,
    double maxWidth = desktopContentMaxWidth,
    EdgeInsetsGeometry? padding,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding, child: child)
            : child,
      ),
    );
  }
}
