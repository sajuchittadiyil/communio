import 'package:communio/features/authentication/models/auth_exception.dart';
import 'package:communio/features/authentication/services/supabase_authentication_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  test('maps invalid credentials without exposing backend details', () {
    const backendError = supabase.AuthApiException(
      'backend detail must not reach the UI',
      statusCode: '400',
      code: 'invalid_credentials',
    );

    final error = SupabaseAuthenticationService.mapSupabaseError(backendError);

    expect(error.code, AuthFailureCode.invalidCredentials);
    expect(
      error.userMessage,
      'The email or password you entered is incorrect.',
    );
  });

  test('maps rate limiting to a retry-friendly failure', () {
    const backendError = supabase.AuthApiException(
      'rate limit exceeded',
      statusCode: '429',
    );

    final error = SupabaseAuthenticationService.mapSupabaseError(backendError);

    expect(error.code, AuthFailureCode.rateLimited);
  });

  test('maps retryable fetch failures to network errors', () {
    final backendError = supabase.AuthRetryableFetchException();

    final error = SupabaseAuthenticationService.mapSupabaseError(backendError);

    expect(error.code, AuthFailureCode.network);
  });

  test('maps retryable server responses to service unavailable', () {
    final backendError = supabase.AuthRetryableFetchException(
      statusCode: '503',
    );

    final error = SupabaseAuthenticationService.mapSupabaseError(backendError);

    expect(error.code, AuthFailureCode.serviceUnavailable);
  });
}
