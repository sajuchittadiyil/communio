import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../models/auth_validators.dart';
import '../state/authentication_scope.dart';
import '../widgets/auth_action_button.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() => _isLoading = true);
    final controller = AuthenticationScope.of(context);
    final updated = await controller.updatePassword(_passwordController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated
              ? 'Your password has been updated.'
              : controller.errorMessage ?? 'Unable to update your password.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSpacing.max * 5),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose a new password',
                      style: AppTypography.responsive(
                        context,
                      ).displaySmall.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AuthTextField(
                      controller: _passwordController,
                      hintText: 'New password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      validator: AuthValidators.password,
                      suffix: IconButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthTextField(
                      controller: _confirmationController,
                      hintText: 'Confirm new password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: true,
                      enabled: !_isLoading,
                      validator: (value) => value == _passwordController.text
                          ? null
                          : 'Passwords do not match.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthActionButton(
                      label: 'Update password',
                      icon: Icons.arrow_forward_rounded,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _updatePassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
