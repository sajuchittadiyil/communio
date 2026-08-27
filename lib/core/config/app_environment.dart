import 'package:flutter/foundation.dart';

class AppEnvironment {
  AppEnvironment._();

  // Supabase publishable configuration is safe to ship in the client. Keep
  // environment overrides for alternate deployments, while allowing the
  // standard Communio mobile launch to authenticate without IDE-specific
  // --dart-define arguments.
  static const _communioSupabaseUrl =
      'https://spcqxnrdaucxbxkrkqdq.supabase.co';
  static const _communioSupabasePublishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwY3F4bnJkYXVjeGJ4a3JrcWRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU1NjI3MTUsImV4cCI6MjEwMTEzODcxNX0.'
      'Lqsl8AP2zqMY9BbFkdTy2AkcCIgtVZ0cYa_9Hr0t-fA';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _communioSupabaseUrl,
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _communioSupabasePublishableKey,
  );
  static const configuredPasswordResetRedirectUrl = String.fromEnvironment(
    'SUPABASE_PASSWORD_RESET_REDIRECT_URL',
  );

  static String get passwordResetRedirectUrl => resolvePasswordResetRedirectUrl(
    configuredUrl: configuredPasswordResetRedirectUrl,
    isWeb: kIsWeb,
    webOrigin: kIsWeb ? Uri.base.origin : null,
  );

  static bool get hasSupabaseConfiguration =>
      supabaseUrl.trim().isNotEmpty && supabasePublishableKey.trim().isNotEmpty;

  @visibleForTesting
  static String resolvePasswordResetRedirectUrl({
    required String configuredUrl,
    required bool isWeb,
    String? webOrigin,
  }) {
    final candidate = configuredUrl.trim();
    if (!isWeb) return candidate;

    final configuredUri = Uri.tryParse(candidate);
    if (configuredUri != null &&
        (configuredUri.scheme == 'http' || configuredUri.scheme == 'https')) {
      return candidate;
    }

    return webOrigin?.trim() ?? '';
  }
}
