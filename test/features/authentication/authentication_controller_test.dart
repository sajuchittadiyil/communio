import 'package:communio/features/authentication/models/auth_exception.dart';
import 'package:communio/features/authentication/models/auth_session.dart';
import 'package:communio/features/authentication/models/auth_user.dart';
import 'package:communio/features/authentication/services/authentication_service.dart';
import 'package:communio/features/authentication/services/session_store.dart';
import 'package:communio/features/authentication/state/authentication_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthSession session;

  setUp(() {
    session = AuthSession(
      user: const AuthUser(id: 'user-1', email: 'member@example.com'),
      accessToken: 'test-access-token',
      refreshToken: 'test-refresh-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  });

  test('successful remembered sign-in persists the session', () async {
    final store = InMemorySessionStore();
    final controller = AuthenticationController(
      _FakeAuthenticationService(session: session),
      store,
    );

    final result = await controller.signIn(
      email: 'member@example.com',
      password: 'password123',
      rememberMe: true,
    );

    expect(result, isTrue);
    expect(controller.status, AuthenticationStatus.signedIn);
    expect(await store.read(), same(session));
    controller.dispose();
  });

  test('sign-in without Remember Me clears persisted session', () async {
    final store = InMemorySessionStore();
    await store.write(session);
    final controller = AuthenticationController(
      _FakeAuthenticationService(session: session),
      store,
    );

    await controller.signIn(
      email: 'member@example.com',
      password: 'password123',
      rememberMe: false,
    );

    expect(await store.read(), isNull);
    controller.dispose();
  });

  test('invalid credentials expose a user-friendly error', () async {
    final controller = AuthenticationController(
      _FakeAuthenticationService(
        failure: AuthException(AuthFailureCode.invalidCredentials),
      ),
      InMemorySessionStore(),
    );

    final result = await controller.signIn(
      email: 'member@example.com',
      password: 'wrong-password',
      rememberMe: true,
    );

    expect(result, isFalse);
    expect(controller.status, AuthenticationStatus.signedOut);
    expect(
      controller.errorMessage,
      'The email or password you entered is incorrect.',
    );
    controller.dispose();
  });

  test('logout clears both active and persisted sessions', () async {
    final store = InMemorySessionStore();
    final service = _FakeAuthenticationService(session: session);
    final controller = AuthenticationController(service, store);
    await controller.signIn(
      email: 'member@example.com',
      password: 'password123',
      rememberMe: true,
    );

    await controller.signOut();

    expect(service.didSignOut, isTrue);
    expect(controller.session, isNull);
    expect(controller.status, AuthenticationStatus.signedOut);
    expect(await store.read(), isNull);
    controller.dispose();
  });
}

class _FakeAuthenticationService implements AuthenticationService {
  _FakeAuthenticationService({this.session, this.failure});

  final AuthSession? session;
  final AuthException? failure;
  bool _didSignOut = false;

  bool get didSignOut => _didSignOut;

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<void> get passwordRecoveryRequests => const Stream.empty();

  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (failure case final error?) throw error;
  }

  @override
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (failure case final error?) throw error;
    return session!;
  }

  @override
  Future<void> signOut() async => _didSignOut = true;

  @override
  Future<void> updatePassword(String password) async {
    if (failure case final error?) throw error;
  }
}
