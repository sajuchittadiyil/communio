import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/shadows.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(AppRadius.md),
      boxShadow: AppShadows.sm,
    ),
    child: Padding(padding: padding, child: child),
  );
}

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    required this.title,
    required this.icon,
    this.actionLabel,
    this.onAction,
    this.accent = AppColors.secondaryDark,
    super.key,
  });

  final String title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 17, color: accent),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          title,
          style: AppTypography.responsive(context).labelLarge.copyWith(
            color: AppColors.textPrimary,
            letterSpacing: 0.4,
          ),
        ),
      ),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel!,
            style: AppTypography.responsive(
              context,
            ).labelMedium.copyWith(color: AppColors.info),
          ),
        ),
    ],
  );
}
