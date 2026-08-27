enum AuthFailureCode {
  invalidCredentials,
  network,
  serviceUnavailable,
  rateLimited,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.code, {this.message});

  final AuthFailureCode code;
  final String? message;

  String get userMessage => switch (code) {
    AuthFailureCode.invalidCredentials =>
      'The email or password you entered is incorrect.',
    AuthFailureCode.network =>
      'Unable to connect. Check your internet connection and try again.',
    AuthFailureCode.serviceUnavailable =>
      message ?? 'Sign-in is temporarily unavailable. Please try again later.',
    AuthFailureCode.rateLimited =>
      'Too many attempts. Please wait a moment and try again.',
    AuthFailureCode.unknown => 'We could not sign you in. Please try again.',
  };
}
