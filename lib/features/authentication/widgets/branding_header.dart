import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class BrandingHeader extends StatelessWidget {
  const BrandingHeader({
    required this.isCompact,
    this.alignment = CrossAxisAlignment.center,
    this.textAlign = TextAlign.center,
    super.key,
  });

  final bool isCompact;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final logoSize = isCompact
        ? AppSpacing.mega
        : AppSpacing.max + AppSpacing.xxl;

    return Semantics(
      header: true,
      label: 'Communio, Congregation Management Platform',
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Image.asset(AppAssets.logo, width: logoSize),
          const SizedBox(height: AppSpacing.md),
          Text(
            'COMMUNIO',
            textAlign: textAlign,
            style:
                (isCompact
                        ? AppTypography.displayMedium
                        : AppTypography.brandDisplay)
                    .copyWith(
                      color: AppColors.primary,
                      letterSpacing: AppSpacing.xs,
                    ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Congregation Management Platform',
            textAlign: textAlign,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: alignment == CrossAxisAlignment.start
                ? Alignment.centerLeft
                : Alignment.center,
            child: Opacity(
              opacity: isCompact ? 0.7 : 0.9,
              child: Image.asset(
                AppAssets.divider,
                width: AppSpacing.mega * 4,
                height: AppSpacing.huge,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: isCompact ? AppSpacing.lg : AppSpacing.xxl),
          Text(
            'Serving Congregations Through Technology',
            textAlign: textAlign,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
