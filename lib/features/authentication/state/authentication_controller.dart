import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth_exception.dart';
import '../models/auth_session.dart';
import '../services/authentication_service.dart';
import '../services/session_store.dart';

enum AuthenticationStatus { initializing, signedOut, authenticating, signedIn }

class AuthenticationController extends ChangeNotifier {
  AuthenticationController(this._service, this._sessionStore) {
    _sessionSubscription = _service.sessionChanges.listen(_handleSessionChange);
    _passwordRecoverySubscription = _service.passwordRecoveryRequests.listen((
      _,
    ) {
      _isPasswordRecovery = true;
      notifyListeners();
    });
  }

  final AuthenticationService _service;
  final SessionStore _sessionStore;
  late final StreamSubscription<AuthSession?> _sessionSubscription;
  late final StreamSubscription<void> _passwordRecoverySubscription;

  AuthenticationStatus _status = AuthenticationStatus.initializing;
  AuthSession? _session;
  String? _errorMessage;
  bool _isPasswordRecovery = false;

  AuthenticationStatus get status => _status;
  AuthSession? get session => _session;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthenticationStatus.authenticating;
  bool get isAuthenticated => _status == AuthenticationStatus.signedIn;
  bool get isPasswordRecovery => _isPasswordRecovery;

  Future<void> restoreSession() async {
    final storedSession = _service.currentSession ?? await _sessionStore.read();
    if (storedSession == null || storedSession.isExpired) {
      if (storedSession?.isExpired ?? false) await _sessionStore.clear();
      _session = null;
      _status = AuthenticationStatus.signedOut;
    } else {
      _session = storedSession;
      _status = AuthenticationStatus.signedIn;
    }
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (isLoading) return false;
    _errorMessage = null;
    _status = AuthenticationStatus.authenticating;
    notifyListeners();

    try {
      final authenticatedSession = await _service.signInWithPassword(
        email: email.trim(),
        password: password,
        rememberMe: rememberMe,
      );
      _session = authenticatedSession;
      _status = AuthenticationStatus.signedIn;
      if (rememberMe) {
        await _sessionStore.write(authenticatedSession);
      } else {
        await _sessionStore.clear();
      }
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      _setAuthenticationFailure(error.userMessage);
    } catch (_) {
      _setAuthenticationFailure(
        const AuthException(AuthFailureCode.unknown).userMessage,
      );
    }
    return false;
  }

  Future<bool> requestPasswordReset(String email) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.sendPasswordResetEmail(email.trim());
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.userMessage;
    } catch (_) {
      _errorMessage = const AuthException(AuthFailureCode.unknown).userMessage;
    }
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    try {
      await _service.signOut();
    } finally {
      await _sessionStore.clear();
      _session = null;
      _errorMessage = null;
      _status = AuthenticationStatus.signedOut;
      _isPasswordRecovery = false;
      notifyListeners();
    }
  }

  Future<bool> updatePassword(String password) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.updatePassword(password);
      _isPasswordRecovery = false;
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.userMessage;
    } catch (_) {
      _errorMessage = const AuthException(AuthFailureCode.unknown).userMessage;
    }
    notifyListeners();
    return false;
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleSessionChange(AuthSession? session) {
    _session = session;
    _status = session == null
        ? AuthenticationStatus.signedOut
        : AuthenticationStatus.signedIn;
    notifyListeners();
  }

  void _setAuthenticationFailure(String message) {
    _session = null;
    _errorMessage = message;
    _status = AuthenticationStatus.signedOut;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionSubscription.cancel();
    _passwordRecoverySubscription.cancel();
    super.dispose();
  }
}
