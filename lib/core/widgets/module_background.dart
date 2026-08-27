import 'package:flutter/material.dart';

import '../constants/assets.dart';
import '../theme/colors.dart';

class ModuleBackground extends StatelessWidget {
  const ModuleBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.dashboardIvory,
                AppColors.dashboardWarmCream,
                AppColors.dashboardSoftBeige,
              ],
            ),
          ),
        ),
        IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -size.width * .3,
                left: -size.width * .45,
                width: size.width * 1.55,
                child: Opacity(
                  opacity: .5,
                  child: Image.asset(AppAssets.lightRays, fit: BoxFit.fitWidth),
                ),
              ),
              Positioned(
                top: -size.width * .12,
                left: -size.width * .2,
                width: size.width * 1.25,
                child: Opacity(
                  opacity: .5,
                  child: Image.asset(AppAssets.goldenArc, fit: BoxFit.fitWidth),
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
