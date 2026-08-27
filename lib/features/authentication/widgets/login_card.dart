import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/shadows.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/auth_validators.dart';
import '../screens/forgot_password_screen.dart';
import '../state/authentication_scope.dart';
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
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = AuthenticationScope.of(context);
    final signedIn = await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
    if (!mounted || signedIn) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.errorMessage ??
              'We could not sign you in. Please try again.',
        ),
      ),
    );
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _showUnavailableMessage(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider sign-in will be available soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authentication = AuthenticationScope.of(context);
    final isLoading = authentication.isLoading;
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
                              ? AppTypography.responsive(context).headlineLarge
                              : AppTypography.responsive(context).displayMedium)
                          .copyWith(color: AppColors.primary),
                ),
                SizedBox(
                  height: isCompactMobile ? AppSpacing.xxs : AppSpacing.sm,
                ),
                Text(
                  'Sign in to continue to your account.',
                  textAlign: TextAlign.center,
                  style: AppTypography.responsive(
                    context,
                  ).titleSmall.copyWith(color: AppColors.textSecondary),
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
                  enabled: !isLoading,
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
                  enabled: !isLoading,
                  verticalContentPadding: isCompactMobile
                      ? AppSpacing.md
                      : AppSpacing.xl,
                  validator: _validatePassword,
                  suffix: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: isLoading
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
                  enabled: !isLoading,
                  compact: isCompactMobile,
                  onRememberChanged: (value) =>
                      setState(() => _rememberMe = value),
                  onForgotPassword: _openForgotPassword,
                ),
                SizedBox(
                  height: isCompactMobile ? AppSpacing.xs : AppSpacing.md,
                ),
                AuthActionButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: isLoading,
                  onPressed: _canSubmit && !isLoading ? _continueSignIn : null,
                ),
                SizedBox(
                  height: isCompactMobile ? AppSpacing.sm : AppSpacing.xl,
                ),
                AuthActionButton.google(
                  enabled: !isLoading,
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
    return AuthValidators.email(value);
  }

  String? _validatePassword(String? value) {
    return AuthValidators.signInPassword(value);
  }
}
