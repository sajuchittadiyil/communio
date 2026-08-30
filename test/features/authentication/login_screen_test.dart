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
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(1200, 800),
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

  testWidgets('login remains usable at 150% text scaling', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
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
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in const [
    (Size(390, 844), 'mobile-login'),
    (Size(768, 1024), 'tablet-login'),
    (Size(900, 700), 'tablet-login'),
    (Size(1200, 800), 'desktop-login'),
    (Size(1366, 768), 'desktop-login'),
    (Size(1440, 900), 'desktop-login'),
    (Size(1920, 1080), 'desktop-login'),
  ]) {
    testWidgets('selects ${scenario.$2} at ${scenario.$1}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.$1;
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
      expect(find.byKey(ValueKey(scenario.$2)), findsOneWidget);
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
