import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class AuthStatistics extends StatelessWidget {
  const AuthStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '150 plus communities, 8,000 plus religious members, 42 countries',
      child: Row(
        children: const [
          Expanded(
            child: _Statistic(
              icon: Icons.groups_outlined,
              value: '150+',
              label: 'Communities',
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: SizedBox(
              height: AppSpacing.huge,
              child: VerticalDivider(color: AppColors.secondary),
            ),
          ),
          Expanded(
            child: _Statistic(
              icon: Icons.person_outline_rounded,
              value: '8,000+',
              label: 'Religious',
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: SizedBox(
              height: AppSpacing.huge,
              child: VerticalDivider(color: AppColors.secondary),
            ),
          ),
          Expanded(
            child: _Statistic(
              icon: Icons.public_outlined,
              value: '42',
              label: 'Countries',
            ),
          ),
        ],
      ),
    );
  }
}

class _Statistic extends StatelessWidget {
  const _Statistic({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppColors.secondary,
          size: AppSpacing.xxl + AppSpacing.xs,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.responsive(
            context,
          ).titleMedium.copyWith(color: AppColors.secondary),
        ),
        Text(
          label,
          style: AppTypography.responsive(
            context,
          ).labelSmall.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
