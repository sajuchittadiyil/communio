import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/shadows.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/dashboard_models.dart';

class QuickOverview extends StatelessWidget {
  const QuickOverview({
    required this.metrics,
    required this.onSelected,
    super.key,
  });

  final List<OverviewMetric> metrics;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surface, AppColors.primary.withValues(alpha: .025)],
      ),
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: AppShadows.sm,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 17,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'QUICK OVERVIEW',
                maxLines: 2,
                style: AppTypography.responsive(context).labelLarge.copyWith(
                  color: AppColors.primary,
                  letterSpacing: .4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 600;
            final columns = mobile
                ? 4
                : constraints.maxWidth >= 760
                ? 5
                : constraints.maxWidth >= 450
                ? 3
                : 2;
            final width =
                (constraints.maxWidth - AppSpacing.sm * (columns - 1)) /
                columns;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var index = 0; index < metrics.length; index++)
                  SizedBox(
                    width: width,
                    child: _OverviewTile(
                      metric: metrics[index],
                      compact: mobile,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({
    required this.metric,
    required this.compact,
    required this.onTap,
  });

  final OverviewMetric metric;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${metric.label}: ${metric.value}',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 82 : AppSpacing.max),
        padding: EdgeInsets.all(compact ? AppSpacing.xs : AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              metric.accent.withValues(alpha: .13),
              metric.accent.withValues(alpha: .045),
            ],
          ),
          border: Border.all(color: metric.accent.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              metric.icon,
              color: metric.accent,
              size: compact ? AppSpacing.xl : AppSpacing.xxl,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              metric.value,
              style: compact
                  ? AppTypography.responsive(context).titleSmall
                  : AppTypography.responsive(context).titleLarge,
            ),
            Text(
              metric.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.responsive(context).labelSmall,
            ),
          ],
        ),
      ),
    ),
  );
}
