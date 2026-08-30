import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';

class LoginOptions extends StatelessWidget {
  const LoginOptions({
    required this.rememberMe,
    required this.enabled,
    required this.onRememberChanged,
    required this.onForgotPassword,
    this.compact = false,
    super.key,
  });

  final bool rememberMe;
  final bool enabled;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgotPassword;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final useStackedLayout =
        compact && MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final rememberOption = Row(
      children: [
        Checkbox(
          value: rememberMe,
          onChanged: enabled
              ? (value) => onRememberChanged(value ?? false)
              : null,
          activeColor: AppColors.secondary,
          materialTapTargetSize: compact
              ? MaterialTapTargetSize.shrinkWrap
              : MaterialTapTargetSize.padded,
          visualDensity: compact ? VisualDensity.compact : null,
        ),
        Expanded(
          child: Text(
            'Remember me',
            style: AppTypography.responsive(context).bodySmall,
          ),
        ),
      ],
    );
    final forgotPassword = TextButton(
      onPressed: enabled ? onForgotPassword : null,
      style: compact
          ? TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      child: Text(
        'Forgot password?',
        style: AppTypography.responsive(
          context,
        ).labelMedium.copyWith(color: AppColors.secondary),
      ),
    );

    if (useStackedLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rememberOption,
          Align(alignment: Alignment.centerRight, child: forgotPassword),
        ],
      );
    }

    return Row(
      children: [
        Checkbox(
          value: rememberMe,
          onChanged: enabled
              ? (value) => onRememberChanged(value ?? false)
              : null,
          activeColor: AppColors.secondary,
          materialTapTargetSize: compact
              ? MaterialTapTargetSize.shrinkWrap
              : MaterialTapTargetSize.padded,
          visualDensity: compact ? VisualDensity.compact : null,
        ),
        Expanded(
          child: Text(
            'Remember me',
            style: AppTypography.responsive(context).bodySmall,
          ),
        ),
        forgotPassword,
      ],
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'OR',
            style: AppTypography.responsive(
              context,
            ).labelSmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
