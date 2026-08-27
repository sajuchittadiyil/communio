import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../widgets/auth_brand_panel.dart';
import '../widgets/background_layer.dart';
import '../widgets/branding_header.dart';
import '../widgets/login_card.dart';
import '../widgets/mobile_branding.dart';
import '../widgets/security_card.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const double _tabletBreakpoint = 768;
  static const double _desktopBreakpoint = 1440;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < _tabletBreakpoint;
    final isDesktop = width >= _desktopBreakpoint;

    return Scaffold(
      body: Stack(
        children: [
          const BackgroundLayer(),
          SafeArea(
            child: isDesktop
                ? const _DesktopLoginLayout()
                : isMobile
                ? const _MobileLoginLayout()
                : const _ScrollableLoginLayout(),
          ),
        ],
      ),
    );
  }
}

class _DesktopLoginLayout extends StatelessWidget {
  const _DesktopLoginLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 6, child: AuthBrandPanel()),
        Expanded(
          flex: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surface, AppColors.background],
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxxl,
                  AppSpacing.xxxl,
                  AppSpacing.xxxl,
                  AppSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppSpacing.max * 5 + AppSpacing.huge,
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -AppSpacing.xl),
                    child: const _SignInColumn(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScrollableLoginLayout extends StatelessWidget {
  const _ScrollableLoginLayout();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxxl,
        vertical: AppSpacing.huge,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppSpacing.mega * 7),
          child: Column(
            children: [
              const BrandingHeader(isCompact: false),
              const SizedBox(height: AppSpacing.huge),
              const _SignInColumn(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileLoginLayout extends StatelessWidget {
  const _MobileLoginLayout();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = _isCompactHeight(constraints.maxHeight);
        final keyboardIsOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
        final content = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: compact ? AppSpacing.sm : AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MobileBranding(compact: compact),
              SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
              _SignInColumn(useMobileSpacing: true, compactMobile: compact),
            ],
          ),
        );

        // Keep the complete sign-in experience in the visible safe area. When
        // the keyboard is present, scrolling remains available so fields are
        // not obscured while editing.
        if (keyboardIsOpen) {
          return SingleChildScrollView(child: content);
        }

        return SizedBox.expand(
          child: FittedBox(
            alignment: Alignment.topCenter,
            fit: BoxFit.scaleDown,
            child: SizedBox(width: constraints.maxWidth, child: content),
          ),
        );
      },
    );
  }

  bool _isCompactHeight(double height) => height < AppSpacing.max * 9;
}

class _SignInColumn extends StatelessWidget {
  const _SignInColumn({
    this.useMobileSpacing = false,
    this.compactMobile = false,
  });

  final bool useMobileSpacing;
  final bool compactMobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: LoginCard(compactMobile: compactMobile),
        ),
        SizedBox(
          height: useMobileSpacing
              ? compactMobile
                    ? AppSpacing.sm
                    : AppSpacing.lg
              : AppSpacing.none,
        ),
        SizedBox(
          width: double.infinity,
          child: SecurityCard(
            mobileStyle: useMobileSpacing,
            compact: compactMobile,
          ),
        ),
        SizedBox(height: compactMobile ? AppSpacing.md : AppSpacing.xl),
        Text(
          '© 2026 Communio. All rights reserved.',
          textAlign: TextAlign.center,
          style: AppTypography.responsive(context).labelSmall.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.76),
          ),
        ),
      ],
    );
  }
}
