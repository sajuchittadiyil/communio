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
  static const double _desktopBreakpoint = 1200;

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
                ? const _DesktopLoginLayout(key: ValueKey('desktop-login'))
                : isMobile
                ? const _MobileLoginLayout(key: ValueKey('mobile-login'))
                : const _ScrollableLoginLayout(key: ValueKey('tablet-login')),
          ),
        ],
      ),
    );
  }
}

class _DesktopLoginLayout extends StatelessWidget {
  const _DesktopLoginLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewport) {
        final compact = viewport.maxHeight < 820;
        return Row(
          children: [
            Expanded(flex: 6, child: AuthBrandPanel(compact: compact)),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final padding = EdgeInsets.fromLTRB(
                      compact ? AppSpacing.xxl : AppSpacing.xxxl,
                      compact ? AppSpacing.lg : AppSpacing.xxxl,
                      compact ? AppSpacing.xxl : AppSpacing.xxxl,
                      compact ? AppSpacing.sm : AppSpacing.lg,
                    );
                    return SingleChildScrollView(
                      padding: padding,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight -
                              padding.top -
                              padding.bottom,
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: AppSpacing.max * 5 + AppSpacing.huge,
                            ),
                            child: Transform.translate(
                              offset: const Offset(0, -AppSpacing.xl),
                              child: _SignInColumn(compactDesktop: compact),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScrollableLoginLayout extends StatelessWidget {
  const _ScrollableLoginLayout({super.key});

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
  const _MobileLoginLayout({super.key});

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
    this.compactDesktop = false,
  });

  final bool useMobileSpacing;
  final bool compactMobile;
  final bool compactDesktop;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: LoginCard(
            compactMobile: compactMobile,
            compactDesktop: compactDesktop,
          ),
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
        SizedBox(
          height: compactMobile || compactDesktop
              ? AppSpacing.md
              : AppSpacing.xl,
        ),
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
