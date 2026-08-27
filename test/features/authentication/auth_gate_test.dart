import 'package:communio/features/authentication/models/auth_session.dart';
import 'package:communio/features/authentication/models/auth_user.dart';
import 'package:communio/features/authentication/screens/auth_gate.dart';
import 'package:communio/features/authentication/screens/login_screen.dart';
import 'package:communio/features/authentication/services/authentication_service.dart';
import 'package:communio/features/authentication/services/session_store.dart';
import 'package:communio/features/authentication/state/authentication_controller.dart';
import 'package:communio/features/authentication/state/authentication_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('routes signed-out, signed-in, and logged-out states', (
    tester,
  ) async {
    final session = AuthSession(
      user: const AuthUser(id: 'user-1', email: 'member@example.com'),
      accessToken: 'test-access-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
    final controller = AuthenticationController(
      _RoutingAuthenticationService(session),
      InMemorySessionStore(),
    );
    await controller.restoreSession();

    await tester.pumpWidget(
      AuthenticationScope(
        controller: controller,
        child: const MaterialApp(
          home: AuthGate(
            authenticatedShell: Scaffold(body: Text('Authenticated shell')),
          ),
        ),
      ),
    );
    expect(find.byType(LoginScreen), findsOneWidget);

    await controller.signIn(
      email: 'member@example.com',
      password: 'password123',
      rememberMe: true,
    );
    await tester.pump();
    expect(find.text('Authenticated shell'), findsOneWidget);

    await controller.signOut();
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);

    controller.dispose();
  });
}

class _RoutingAuthenticationService implements AuthenticationService {
  _RoutingAuthenticationService(this._session);

  final AuthSession _session;

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
  }) async => _session;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updatePassword(String password) async {}
}
