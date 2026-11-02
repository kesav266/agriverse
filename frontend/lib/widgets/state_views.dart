import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state/app_state_provider.dart';
import '../core/theme/app_colors.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Reusable Loading State Widget with refined botanical spinner.
class LoadingView extends StatelessWidget {
  final String? message;
  final String? subtitle;

  const LoadingView({super.key, this.message, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                color: AppColors.forestPine,
                strokeWidth: 3.0,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message ?? state.tr('loading'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reusable Empty State Widget with clear call-to-action.
class EmptyStateView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.mistMint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Icon(icon, size: 40, color: AppColors.forestPine),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 20),
                AppButton(
                  text: actionLabel!,
                  icon: Icons.add_rounded,
                  onPressed: onAction,
                  variant: AppButtonVariant.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Error State Widget with explicit Retry Action.
class ErrorStateView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final String? title;

  const ErrorStateView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          border: Border.all(color: AppColors.errorBorder),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 38,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title ?? state.tr('unable_to_load_data'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AppButton(
                text: state.tr('retry_connection'),
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
                variant: AppButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Data Provenance Notice Banner.
/// Differentiates between live telemetry and regional offline benchmarks.
class DataSourceBanner extends StatelessWidget {
  final String? text;
  final bool isWarning;

  const DataSourceBanner({super.key, this.text, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final bgColor = isWarning
        ? AppColors.warningLight
        : AppColors.mistMint.withValues(alpha: 0.5);
    final borderColor = isWarning
        ? AppColors.warningBorder
        : AppColors.borderLight;
    final iconColor = isWarning ? AppColors.warning : AppColors.forestPine;
    final textColor = isWarning ? AppColors.warning : AppColors.forestPine;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWarning ? Icons.info_outline_rounded : Icons.sensors_rounded,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text ?? state.tr('data_source_status'),
              style: TextStyle(
                color: textColor,
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
