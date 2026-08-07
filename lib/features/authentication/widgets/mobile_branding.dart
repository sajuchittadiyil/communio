import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class MobileBranding extends StatelessWidget {
  const MobileBranding({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Communio, Congregation Management Platform',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: compact ? AppSpacing.max : AppSpacing.max + AppSpacing.md,
            right: -AppSpacing.lg,
            width: AppSpacing.mega * 2.5,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(AppAssets.dove, fit: BoxFit.fitWidth),
            ),
          ),
          Column(
            children: [
              Image.asset(
                AppAssets.logo,
                width:
                    (compact
                        ? AppSpacing.max + AppSpacing.md
                        : AppSpacing.max + AppSpacing.xxl) *
                    1.15,
              ),
              SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
              Text(
                'COMMUNIO',
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  color: AppColors.primary,
                  fontSize: compact ? 44 : 48,
                  letterSpacing: AppSpacing.xs,
                ),
              ),
              SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Congregation Management Platform',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.secondaryDark,
                        letterSpacing: AppSpacing.xxs,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
              Text(
                'Serving Congregations Through Technology',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
              MobileFeatureStrip(compact: compact),
            ],
          ),
        ],
      ),
    );
  }
}

class MobileFeatureStrip extends StatelessWidget {
  const MobileFeatureStrip({this.compact = false, super.key});

  final bool compact;

  static const _items = [
    _FeatureItem('RELIGIOUS', AppAssets.mobileReligious),
    _FeatureItem('COMMUNITIES', AppAssets.mobileCommunities),
    _FeatureItem('MISSION', AppAssets.mobileMission),
    _FeatureItem('GOVERNANCE', AppAssets.mobileGovernance),
    _FeatureItem('STEWARDSHIP', AppAssets.mobileStewardship),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _items
          .map(
            (item) => Expanded(
              child: _MobileFeatureEmblem(item: item, compact: compact),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MobileFeatureEmblem extends StatelessWidget {
  const _MobileFeatureEmblem({required this.item, required this.compact});

  final _FeatureItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FractionallySizedBox(
          widthFactor: compact ? 0.85 : 0.9,
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipOval(child: Image.asset(item.asset, fit: BoxFit.cover)),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.xxs : AppSpacing.xs),
        const Icon(
          Icons.auto_awesome,
          color: AppColors.secondary,
          size: AppSpacing.md,
        ),
      ],
    );
  }
}

class _FeatureItem {
  const _FeatureItem(this.label, this.asset);

  final String label;
  final String asset;
}
