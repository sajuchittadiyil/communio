import 'package:communio/features/authentication/screens/login_screen.dart';
import 'package:communio/features/authentication/models/auth_session.dart';
import 'package:communio/features/authentication/services/authentication_service.dart';
import 'package:communio/features/authentication/services/session_store.dart';
import 'package:communio/features/authentication/state/authentication_controller.dart';
import 'package:communio/features/authentication/state/authentication_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in const [
    Size(1366, 768),
    Size(1440, 900),
    Size(1920, 1080),
    Size(900, 700),
  ]) {
    testWidgets('login remains overflow-free at ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);

      final controller = AuthenticationController(
        const _SignedOutAuthenticationService(),
        InMemorySessionStore(),
      );
      await controller.restoreSession();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AuthenticationScope(
          controller: controller,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('© 2026 Communio. All rights reserved.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

class _SignedOutAuthenticationService implements AuthenticationService {
  const _SignedOutAuthenticationService();

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<void> get passwordRecoveryRequests => const Stream.empty();

  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updatePassword(String password) async {}
}
