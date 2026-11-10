import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radii.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

/// Reusable Tactile AppButton with spring-damping press feedback, loading state,
/// and accessible touch target compliance.
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final bool expanded;
  final double? borderRadius;
  final bool isPill;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50.0,
    this.expanded = false,
    this.borderRadius,
    this.isPill = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    Border? border;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bgColor = AppColors.forestPine;
        fgColor = AppColors.surfaceWhite;
        break;
      case AppButtonVariant.secondary:
        bgColor = AppColors.mistMint;
        fgColor = AppColors.forestPine;
        break;
      case AppButtonVariant.outline:
        bgColor = Colors.transparent;
        fgColor = AppColors.forestPine;
        border = Border.all(color: AppColors.forestPine, width: 1.5);
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = AppColors.textPrimary;
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.error;
        fgColor = AppColors.surfaceWhite;
        break;
    }

    final isDisabled = widget.onPressed == null || widget.isLoading;
    if (isDisabled &&
        widget.variant != AppButtonVariant.outline &&
        widget.variant != AppButtonVariant.ghost) {
      bgColor = bgColor.withValues(alpha: 0.45);
      fgColor = fgColor.withValues(alpha: 0.7);
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 20, color: fgColor),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: TextStyle(
            color: fgColor,
            fontSize: 15.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    final double radius = widget.borderRadius ??
        (widget.isPill ? AppRadii.pillValue : AppRadii.lgValue);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: widget.height,
          width: widget.expanded ? double.infinity : widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius),
            border: border,
            boxShadow: widget.variant == AppButtonVariant.primary && !isDisabled
                ? [
                    BoxShadow(
                      color: AppColors.forestPine.withValues(alpha: 0.20),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
