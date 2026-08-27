import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/shadows.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class ProvincePulseHeader extends StatelessWidget {
  const ProvincePulseHeader({required this.displayName, super.key});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    final today = DateTime.now();
    final weekday = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][today.weekday - 1];
    final date =
        '${today.day} ${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][today.month - 1]} ${today.year}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;
        final introduction = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppColors.secondaryDark,
                    size: 19,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Province Pulse',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (mobile
                                ? AppTypography.responsive(
                                    context,
                                  ).headlineMedium
                                : AppTypography.responsive(
                                    context,
                                  ).headlineLarge)
                            .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$greeting, $displayName!',
              style: AppTypography.responsive(
                context,
              ).bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        );
        final dateText = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              weekday,
              maxLines: 2,
              style: AppTypography.responsive(context).labelMedium,
            ),
            Text(
              date,
              maxLines: 2,
              style: AppTypography.responsive(
                context,
              ).bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        );
        final dateCard = Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: .82),
            border: Border.all(color: AppColors.primary.withValues(alpha: .1)),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (mobile) Expanded(child: dateText) else dateText,
            ],
          ),
        );
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? AppSpacing.lg : AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                AppColors.info.withValues(alpha: .035),
                AppColors.secondary.withValues(alpha: .055),
              ],
            ),
            border: Border.all(color: AppColors.primary.withValues(alpha: .1)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.md,
          ),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    introduction,
                    const SizedBox(height: AppSpacing.sm),
                    Align(alignment: Alignment.centerLeft, child: dateCard),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: introduction),
                    const SizedBox(width: AppSpacing.lg),
                    dateCard,
                  ],
                ),
        );
      },
    );
  }
}
