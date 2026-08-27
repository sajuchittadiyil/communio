import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/auth_exception.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';
import 'authentication_service.dart';
import 'remember_me_local_storage.dart';

class SupabaseAuthenticationService implements AuthenticationService {
  SupabaseAuthenticationService(
    this._client,
    this._localStorage,
    this._passwordResetRedirectUrl,
  );

  final supabase.SupabaseClient _client;
  final RememberMeLocalStorage _localStorage;
  final String? _passwordResetRedirectUrl;

  @override
  AuthSession? get currentSession => _mapSession(_client.auth.currentSession);

  @override
  Stream<AuthSession?> get sessionChanges =>
      _client.auth.onAuthStateChange.map((state) => _mapSession(state.session));

  @override
  Stream<void> get passwordRecoveryRequests => _client.auth.onAuthStateChange
      .where(
        (state) => state.event == supabase.AuthChangeEvent.passwordRecovery,
      )
      .map((_) {});

  @override
  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      await _localStorage.setPersistenceEnabled(rememberMe);
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = _mapSession(response.session);
      if (session == null) {
        throw const AuthException(AuthFailureCode.invalidCredentials);
      }
      return session;
    } on supabase.AuthException catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: _nonEmpty(_passwordResetRedirectUrl),
      );
    } on supabase.AuthException catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(
        supabase.UserAttributes(password: password),
      );
    } on supabase.AuthException catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      await _localStorage.removePersistedSession();
    } on supabase.AuthException catch (error) {
      throw mapSupabaseError(error);
    }
  }

  static AuthException mapSupabaseError(supabase.AuthException error) {
    final code = error.code?.toLowerCase();
    final status = int.tryParse(error.statusCode ?? '');
    if (code == 'invalid_credentials' || code == 'email_not_confirmed') {
      return const AuthException(AuthFailureCode.invalidCredentials);
    }
    if (status == 429 || code == 'over_request_rate_limit') {
      return const AuthException(AuthFailureCode.rateLimited);
    }
    if (status != null && status >= 500) {
      return const AuthException(AuthFailureCode.serviceUnavailable);
    }
    if (error is supabase.AuthRetryableFetchException) {
      return const AuthException(AuthFailureCode.network);
    }
    return const AuthException(AuthFailureCode.unknown);
  }

  static AuthSession? _mapSession(supabase.Session? session) {
    if (session == null) return null;
    final expiresAt = session.expiresAt == null
        ? DateTime.now().add(const Duration(hours: 1))
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return AuthSession(
      user: AuthUser(id: session.user.id, email: session.user.email ?? ''),
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: expiresAt,
    );
  }

  static String? _nonEmpty(String? value) {
    final candidate = value?.trim();
    return candidate == null || candidate.isEmpty ? null : candidate;
  }
}
