import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'features/authentication/services/authentication_service.dart';
import 'features/authentication/services/remember_me_local_storage.dart';
import 'features/authentication/services/session_store.dart';
import 'features/authentication/services/supabase_authentication_service.dart';
import 'features/authentication/services/unconfigured_authentication_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthenticationService authenticationService;
  final sessionStore = InMemorySessionStore();

  if (AppEnvironment.hasSupabaseConfiguration) {
    final localStorage = RememberMeLocalStorage();
    await Supabase.initialize(
      url: AppEnvironment.supabaseUrl,
      publishableKey: AppEnvironment.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(localStorage: localStorage),
    );
    authenticationService = SupabaseAuthenticationService(
      Supabase.instance.client,
      localStorage,
      AppEnvironment.passwordResetRedirectUrl,
    );
  } else {
    authenticationService = const UnconfiguredAuthenticationService();
  }

  runApp(
    CommunioApp(
      authenticationService: authenticationService,
      sessionStore: sessionStore,
    ),
  );
}
