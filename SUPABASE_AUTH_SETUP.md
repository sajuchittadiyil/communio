# Supabase Authentication Setup

Communio reads client-safe configuration from Flutter build defines. No keys
belong in Dart source files.

## Required build values

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_OR_ANON_KEY \
  --dart-define=SUPABASE_PASSWORD_RESET_REDIRECT_URL=communio://auth/reset-password
```

Use CI secret variables for release builds. Never pass a `service_role` or
secret server key to Flutter.

For local web development, use a fixed port and override only the reset URL:

```sh
flutter run -d chrome --web-port=7357 \
  --dart-define-from-file=config/dev_environment.json \
  --dart-define=SUPABASE_PASSWORD_RESET_REDIRECT_URL=http://localhost:7357
```

The VS Code `Communio - Development (Chrome)` profile uses the same settings.
When the shared mobile configuration is used without an override, Communio
automatically uses the current web origin instead of sending a browser to the
mobile custom scheme. For deployed web builds, explicitly set the reset URL to
the deployed HTTPS origin.

## Supabase Dashboard

1. Enable Email authentication and create users through an approved admin or
   server-side workflow.
2. Add `communio://auth/reset-password` to Authentication > URL Configuration
   > Redirect URLs.
3. For local web development, add `http://localhost:7357` to Redirect URLs.
4. Add the deployed web origin to Redirect URLs.
5. Set Site URL to the deployed production web origin. Do not replace it with
   localhost.

The Android intent filter and iOS custom URL scheme are included. Production
universal/app links require an owned HTTPS domain plus its Android asset links
and Apple associated-domain files; configure those before replacing the custom
scheme.
