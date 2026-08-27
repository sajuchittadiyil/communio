import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import 'auth_statistics.dart';

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: constraints.maxHeight * 0.18,
            left: constraints.maxWidth * 0.12,
            child: const _FaithGlyph(icon: Icons.menu_book_outlined),
          ),
          Positioned(
            top: constraints.maxHeight * 0.42,
            right: constraints.maxWidth * 0.12,
            child: const _FaithGlyph(icon: Icons.church_outlined),
          ),
          Positioned(
            bottom: constraints.maxHeight * 0.16,
            right: constraints.maxWidth * 0.18,
            child: const _FaithGlyph(icon: Icons.volunteer_activism_outlined),
          ),
          Transform.translate(
            offset: const Offset(0, -AppSpacing.xxxl),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.massive),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 1.12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            AppAssets.logo,
                            width: AppSpacing.max + AppSpacing.huge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'COMMUNIO',
                            textAlign: TextAlign.center,
                            style: AppTypography.responsive(context)
                                .brandDisplay
                                .copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: AppSpacing.sm,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Congregation Management Platform',
                            textAlign: TextAlign.center,
                            style: AppTypography.responsive(context).titleLarge
                                .copyWith(
                                  color: AppColors.secondary,
                                  letterSpacing: AppSpacing.xs,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    Image.asset(
                      AppAssets.divider,
                      width: AppSpacing.mega * 4,
                      height: AppSpacing.huge,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Transform.scale(
                      scale: 1.1,
                      child: Text(
                        'One Platform.\nEvery Congregation.\nEndless Possibilities.',
                        textAlign: TextAlign.center,
                        style: AppTypography.responsive(
                          context,
                        ).headlineLarge.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const AuthStatistics(),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Connected in Faith.\nUnited in Mission.',
                      textAlign: TextAlign.center,
                      style: AppTypography.responsive(context).headlineSmall
                          .copyWith(
                            color: AppColors.secondary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: constraints.maxHeight * 0.13,
            left: constraints.maxWidth * 0.62,
            width: AppSpacing.mega * 4,
            child: Opacity(
              opacity: 0.66,
              child: Image.asset(AppAssets.dove, fit: BoxFit.fitWidth),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaithGlyph extends StatelessWidget {
  const _FaithGlyph({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.giant,
      height: AppSpacing.giant,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.14)),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: AppColors.secondary.withValues(alpha: 0.22),
        size: AppSpacing.xxl,
      ),
    );
  }
}
