import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/state/app_state_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radii.dart';
import '../core/theme/app_shadows.dart';

/// Modern Navigation Bar for AgriVerse AI.
/// Provides tactile haptic feedback, active indicator pill, and dark theme support.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.charcoalSurface : AppColors.surfaceWhite;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22.0)),
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
        boxShadow: isDark ? AppShadows.darkElevated : AppShadows.bottomBar,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                context,
                0,
                Icons.dashboard_rounded,
                Icons.dashboard_outlined,
                state.tr('dashboard'),
              ),
              _navItem(
                context,
                1,
                Icons.landscape_rounded,
                Icons.landscape_outlined,
                state.tr('farmer_profile'),
              ),
              _navItem(
                context,
                2,
                Icons.psychology_rounded,
                Icons.psychology_outlined,
                state.tr('personal_assistant'),
              ),
              _navItem(
                context,
                3,
                Icons.settings_rounded,
                Icons.settings_outlined,
                state.tr('farm_history_settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedColor = isDark
        ? AppColors.nightCanopy
        : AppColors.surfaceWhite;
    final unselectedColor = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textSecondary;
    final activeBgColor = isDark
        ? AppColors.luminousSage
        : AppColors.forestPine;

    return InkWell(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
        }
        onTabSelected(index);
      },
      borderRadius: BorderRadius.circular(AppRadii.pillValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16.0 : 12.0,
          vertical: 9.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pillValue),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: AppColors.forestPine.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: isSelected ? 1.05 : 1,
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                size: 21,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selectedColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
