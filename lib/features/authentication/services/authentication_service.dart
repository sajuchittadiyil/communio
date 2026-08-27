import '../models/auth_session.dart';

/// Backend-independent authentication contract.
///
/// A Supabase adapter can implement this interface without leaking Supabase
/// types into screens, widgets, or authentication state.
abstract interface class AuthenticationService {
  Stream<AuthSession?> get sessionChanges;
  Stream<void> get passwordRecoveryRequests;
  AuthSession? get currentSession;

  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  });

  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String password);

  Future<void> signOut();
}
