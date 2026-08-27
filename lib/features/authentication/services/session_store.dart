import '../models/auth_session.dart';

/// Persistence boundary for remembered sessions.
///
/// The production implementation must use platform-secure storage. Tokens
/// must never be stored in plain preferences or source files.
abstract interface class SessionStore {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

/// Safe default until secure platform storage is configured. It intentionally
/// does not persist across application restarts.
class InMemorySessionStore implements SessionStore {
  AuthSession? _session;

  @override
  Future<void> clear() async => _session = null;

  @override
  Future<AuthSession?> read() async => _session;

  @override
  Future<void> write(AuthSession session) async => _session = session;
}
