import 'package:supabase_flutter/supabase_flutter.dart';

/// Allows each sign-in attempt to opt in or out of Supabase session storage.
class RememberMeLocalStorage extends LocalStorage {
  RememberMeLocalStorage({String persistSessionKey = 'communio.auth.session'})
    : _delegate = SharedPreferencesLocalStorage(
        persistSessionKey: persistSessionKey,
      );

  final SharedPreferencesLocalStorage _delegate;
  bool _persistenceEnabled = true;

  Future<void> setPersistenceEnabled(bool enabled) async {
    _persistenceEnabled = enabled;
    if (!enabled) await _delegate.removePersistedSession();
  }

  @override
  Future<String?> accessToken() => _delegate.accessToken();

  @override
  Future<bool> hasAccessToken() => _delegate.hasAccessToken();

  @override
  Future<void> initialize() => _delegate.initialize();

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (_persistenceEnabled) {
      await _delegate.persistSession(persistSessionString);
    }
  }

  @override
  Future<void> removePersistedSession() => _delegate.removePersistedSession();
}
