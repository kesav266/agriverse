import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radii.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_borders.dart';

/// Standard AppCard with precision elevation, border geometry, and optional touch feedback.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18.0),
    this.margin = const EdgeInsets.symmetric(vertical: 6.0),
    this.onTap,
    this.color,
    this.gradient,
    this.border,
    this.borderRadius = AppRadii.lgValue,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorder =
        border ?? (isDark ? AppBorders.cardDark : AppBorders.cardLight);
    final defaultBg = isDark
        ? AppColors.charcoalSurface
        : AppColors.surfaceWhite;
    final effectiveShadow =
        boxShadow ?? (isDark ? AppShadows.darkCard : AppShadows.subtle);

    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? defaultBg) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding(
        padding: margin,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: AppColors.forestPine.withValues(alpha: 0.08),
            highlightColor: AppColors.forestPine.withValues(alpha: 0.04),
            child: cardContent,
          ),
        ),
      );
    }

    return Padding(padding: margin, child: cardContent);
  }
}

/// Dark Hero Card for prominent sections (Welcome, Diagnostics, Dashboard Pulse).
class HeroDarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const HeroDarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22.0),
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      margin: margin,
      onTap: onTap,
      gradient: gradient ?? AppColors.heroEditorialGradient,
      border: Border.all(color: AppColors.borderDark, width: 1.2),
      borderRadius: AppRadii.xlValue,
      boxShadow: [
        BoxShadow(
          color: AppColors.forestPine.withValues(alpha: 0.25),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      child: child,
    );
  }
}
