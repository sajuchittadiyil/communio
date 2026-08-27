import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class AuthActionButton extends StatefulWidget {
  const AuthActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  }) : _isGoogle = false,
       enabled = onPressed != null;

  const AuthActionButton.google({
    required this.onPressed,
    required this.enabled,
    super.key,
  }) : label = 'Sign in with Google',
       icon = Icons.g_mobiledata_rounded,
       isLoading = false,
       _isGoogle = true;

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool _isGoogle;
  final bool enabled;

  @override
  State<AuthActionButton> createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget._isGoogle
        ? AppColors.textPrimary
        : AppColors.textLight;
    final background = widget._isGoogle ? AppColors.surface : AppColors.primary;

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: _hovered && widget.enabled ? 1.01 : 1,
        child: SizedBox(
          height: AppSpacing.giant,
          child: ElevatedButton(
            onPressed: widget.enabled ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: background,
              disabledBackgroundColor: background,
              foregroundColor: foreground,
              disabledForegroundColor: foreground.withValues(alpha: 0.65),
              elevation: AppSpacing.none,
              side: widget._isGoogle
                  ? const BorderSide(color: AppColors.border)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: AppSpacing.xxl,
                    width: AppSpacing.xxl,
                    child: CircularProgressIndicator(
                      color: AppColors.textLight,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.icon,
                        color: widget._isGoogle ? AppColors.primary : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        widget.label,
                        style: AppTypography.responsive(context).labelLarge,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
