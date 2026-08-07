import 'package:flutter/material.dart';

import '../../../core/constants/assets.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

class BackgroundLayer extends StatelessWidget {
  const BackgroundLayer({super.key});

  static const double _tabletBreakpoint = 768;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < _tabletBreakpoint;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  AppColors.surface,
                  AppColors.background,
                ],
              ),
            ),
          ),
          Positioned(
            top: -size.width * 0.35,
            left: -size.width * 0.55,
            width: isMobile ? size.width * 1.8 : size.width * 1.5,
            child: Opacity(
              opacity: isMobile ? 0.34 : 0.56,
              child: Image.asset(AppAssets.lightRays, fit: BoxFit.fitWidth),
            ),
          ),
          if (isMobile)
            Positioned(
              top: -AppSpacing.xxxl,
              left: -AppSpacing.huge,
              width: size.width * 1.6,
              child: Opacity(
                opacity: 0.34,
                child: Image.asset(AppAssets.goldenArc, fit: BoxFit.fitWidth),
              ),
            )
          else
            ..._goldenArc(size),
          if (isMobile)
            Positioned(
              top: AppSpacing.sm,
              right: -AppSpacing.mega,
              width: AppSpacing.mega * 2.5,
              child: Opacity(
                opacity: 0.34,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(-1, 1, 1),
                  child: Image.asset(AppAssets.dove, fit: BoxFit.fitWidth),
                ),
              ),
            ),
          if (!isMobile)
            Positioned(
              top: isMobile ? AppSpacing.none : AppSpacing.sm,
              right: isMobile ? -AppSpacing.massive : -AppSpacing.xxl,
              width: isMobile ? AppSpacing.mega * 3 : AppSpacing.max * 5,
              child: Opacity(
                opacity: isMobile ? 0.5 : 0.86,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(-1, 1, 1),
                  child: Image.asset(AppAssets.dove, fit: BoxFit.fitWidth),
                ),
              ),
            ),
          if (isMobile)
            Align(
              alignment: Alignment.bottomCenter,
              child: _CathedralPanorama(
                width: size.width * 1.25,
                alignment: Alignment.bottomCenter,
              ),
            )
          else ...[
            Positioned(
              left: -AppSpacing.mega,
              bottom: -AppSpacing.mega,
              child: _CathedralPanorama(
                width: size.width * 0.86,
                alignment: Alignment.bottomRight,
              ),
            ),
            Positioned(
              right: -AppSpacing.mega,
              bottom: -AppSpacing.mega,
              child: _CathedralPanorama(
                width: size.width * 0.86,
                alignment: Alignment.bottomLeft,
                flip: true,
              ),
            ),
          ],
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: isMobile ? size.height * 0.48 : size.height * 0.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface.withValues(alpha: 0.04),
                    AppColors.surface.withValues(alpha: 0.52),
                    AppColors.surface.withValues(alpha: isMobile ? 0.94 : 0.88),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _goldenArc(Size size) {
    final arcWidth = size.width * 0.8;
    final arcHeight = arcWidth / 1.5;
    final arcTop = -arcHeight * 0.3;
    final center = size.width / 2;
    final endpoint = arcWidth * 0.93;

    return [
      Positioned(
        left: center - endpoint,
        top: arcTop,
        width: arcWidth,
        child: const _GoldenArcHalf(opacity: 0.48),
      ),
      Positioned(
        left: center - (arcWidth - endpoint),
        top: arcTop,
        width: arcWidth,
        child: const _GoldenArcHalf(flip: true, opacity: 0.16),
      ),
    ];
  }
}

class _GoldenArcHalf extends StatelessWidget {
  const _GoldenArcHalf({this.flip = false, this.opacity = 0.58});

  final bool flip;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(flip ? -1 : 1, 1, 1),
        child: Image.asset(AppAssets.goldenArc, fit: BoxFit.fitWidth),
      ),
    );
  }
}

class _CathedralPanorama extends StatelessWidget {
  const _CathedralPanorama({
    required this.width,
    required this.alignment,
    this.flip = false,
  });

  final double width;
  final Alignment alignment;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(flip ? -1 : 1, 1, 1),
        child: Image.asset(
          AppAssets.cathedral,
          width: width,
          fit: BoxFit.fitWidth,
          alignment: alignment,
        ),
      ),
    );
  }
}
