import 'package:communio/features/authentication/models/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sign-in accepts any non-empty password for Supabase to verify', () {
    expect(AuthValidators.signInPassword(''), 'Enter your password.');
    expect(AuthValidators.signInPassword('short'), isNull);
  });

  test('sign-in requires a valid email address', () {
    expect(AuthValidators.email('member'), 'Enter a valid email address.');
    expect(AuthValidators.email('member@communio.com'), isNull);
  });
}
