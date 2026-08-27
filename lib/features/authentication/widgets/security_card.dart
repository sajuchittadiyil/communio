import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/shadows.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class SecurityCard extends StatelessWidget {
  const SecurityCard({
    this.mobileStyle = false,
    this.compact = false,
    super.key,
  });

  final bool mobileStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your data is protected with industry-standard security',
      child: Container(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            SizedBox(
              width: compact ? AppSpacing.massive : AppSpacing.giant,
              height: compact ? AppSpacing.massive : AppSpacing.giant,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: mobileStyle
                      ? AppColors.secondary.withValues(alpha: 0.08)
                      : AppColors.transparent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.secondary,
                  size: AppSpacing.huge,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mobileStyle
                        ? 'Your data is secure with us'
                        : 'Secure & Trusted Platform',
                    style:
                        (mobileStyle
                                ? AppTypography.responsive(context).titleMedium
                                : AppTypography.responsive(context).titleSmall)
                            .copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    mobileStyle
                        ? 'We follow best practices to protect your information.'
                        : 'Your data is protected with enterprise-grade security and encryption to ensure complete confidentiality.',
                    style: AppTypography.responsive(
                      context,
                    ).bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (mobileStyle) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
