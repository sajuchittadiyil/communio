import 'package:communio/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('standard Communio launch has Supabase authentication configured', () {
    expect(AppEnvironment.hasSupabaseConfiguration, isTrue);
  });

  group('password reset redirect URL', () {
    test('preserves the mobile custom scheme', () {
      final redirectUrl = AppEnvironment.resolvePasswordResetRedirectUrl(
        configuredUrl: 'communio://auth/reset-password',
        isWeb: false,
      );

      expect(redirectUrl, 'communio://auth/reset-password');
    });

    test('uses the local web origin instead of a mobile custom scheme', () {
      final redirectUrl = AppEnvironment.resolvePasswordResetRedirectUrl(
        configuredUrl: 'communio://auth/reset-password',
        isWeb: true,
        webOrigin: 'http://localhost:7357',
      );

      expect(redirectUrl, 'http://localhost:7357');
    });

    test('preserves an explicit HTTPS web redirect', () {
      final redirectUrl = AppEnvironment.resolvePasswordResetRedirectUrl(
        configuredUrl: 'https://communio.example/auth/reset-password',
        isWeb: true,
        webOrigin: 'http://localhost:7357',
      );

      expect(redirectUrl, 'https://communio.example/auth/reset-password');
    });
  });
}
