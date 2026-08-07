import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/shadows.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import 'auth_action_button.dart';
import 'auth_text_field.dart';
import 'login_options.dart';

class LoginCard extends StatefulWidget {
  const LoginCard({this.compactMobile = false, super.key});

  final bool compactMobile;

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_refresh);
    _passwordController.addListener(_refresh);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_refresh)
      ..dispose();
    _passwordController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _continueSignIn() async {
    if (!_canSubmit || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showUnavailableMessage(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider sign-in will be available soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    final isCompactMobile = isMobile && widget.compactMobile;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: AppSpacing.md, end: AppSpacing.none),
      builder: (context, offset, child) => Opacity(
        opacity: 1 - (offset / AppSpacing.lg),
        child: Transform.translate(
          offset: Offset(AppSpacing.none, offset),
          child: Transform.scale(
            scale: 1 - (offset / AppSpacing.mega),
            child: child,
          ),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(
          isCompactMobile
              ? AppSpacing.md
              : isMobile
              ? AppSpacing.xl
              : AppSpacing.huge,
        ),
        constraints: BoxConstraints(
          minHeight: isMobile ? AppSpacing.none : AppSpacing.mega * 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppRadius.xxxl),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.76)),
          boxShadow: AppShadows.medium,
        ),
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isMobile)
                  Container(
                    height: AppSpacing.xs,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.transparent,
                          AppColors.secondary,
                          AppColors.transparent,
                        ],
                      ),
                    ),
                  ),
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style:
                      (isCompactMobile
                              ? AppTypography.headlineLarge
                              : AppTypography.displayMedium)
                          .copyWith(color: AppColors.primary),
                ),
                SizedBox(
                  height: isCompactMobile ? AppSpacing.xxs : AppSpacing.sm,
                ),
                Text(
                  'Sign in to continue to your account.',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(
                  height: isCompactMobile ? AppSpacing.sm : AppSpacing.xxl,
                ),
                AuthTextField(
                  controller: _emailController,
                  hintText: 'Email or Username',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  prefixIcon: Icons.mail_outline_rounded,
                  enabled: !_isLoading,
                  verticalContentPadding: isCompactMobile
                      ? AppSpacing.md
                      : AppSpacing.xl,
                  validator: _validateEmail,
                ),
                SizedBox(
                  height: isCompactMobile ? AppSpacing.sm : AppSpacing.lg,
                ),
                AuthTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  prefixIcon: Icons.lock_outline_rounded,
                  enabled: !_isLoading,
                  verticalContentPadding: isCompactMobile
                      ? AppSpacing.md
                      : AppSpacing.xl,
                  validator: _validatePassword,
                  suffix: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: _isLoading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  height: isCompactMobile ? AppSpacing.xxs : AppSpacing.xs,
                ),
                LoginOptions(
                  rememberMe: _rememberMe,
                  enabled: !_isLoading,
                  compact: isCompactMobile,
                  onRememberChanged: (value) =>
                      setState(() => _rememberMe = value),
                  onForgotPassword: () =>
                      _showUnavailableMessage('Password recovery'),
                ),
                SizedBox(
                  height: isCompactMobile ? AppSpacing.xs : AppSpacing.md,
                ),
                AuthActionButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _canSubmit && !_isLoading ? _continueSignIn : null,
                ),
                SizedBox(
                  height: isCompactMobile ? AppSpacing.sm : AppSpacing.xl,
                ),
                AuthActionButton.google(
                  enabled: !_isLoading,
                  onPressed: () => _showUnavailableMessage('Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value?.length ?? 0) < AppSpacing.sm) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }
}
