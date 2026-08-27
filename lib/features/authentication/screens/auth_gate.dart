import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../state/authentication_scope.dart';
import '../state/authentication_controller.dart';
import 'authenticated_shell.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({this.authenticatedShell, super.key});

  final Widget? authenticatedShell;

  @override
  Widget build(BuildContext context) {
    final authentication = AuthenticationScope.of(context);
    if (authentication.isPasswordRecovery) {
      return const ResetPasswordScreen();
    }
    if (authentication.isAuthenticated) {
      return authenticatedShell ?? const AuthenticatedShell();
    }
    if (authentication.status == AuthenticationStatus.initializing) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }
    return const LoginScreen();
  }
}
