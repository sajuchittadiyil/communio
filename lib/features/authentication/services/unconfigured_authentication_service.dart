import '../models/auth_exception.dart';
import '../models/auth_session.dart';
import 'authentication_service.dart';

/// Explicit fail-closed service used until a backend adapter is configured.
class UnconfiguredAuthenticationService implements AuthenticationService {
  const UnconfiguredAuthenticationService();

  static const _exception = AuthException(
    AuthFailureCode.serviceUnavailable,
    message: 'Sign-in is not configured yet. Please contact support.',
  );

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<void> get passwordRecoveryRequests => const Stream.empty();

  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      Future<void>.error(_exception);

  @override
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) => Future<AuthSession>.error(_exception);

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updatePassword(String password) =>
      Future<void>.error(_exception);
}
