import 'package:communio/core/widgets/contact_action_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'normalizes an international phone for WhatsApp without country loss',
    () {
      expect(normalizeInternationalPhone('+91 (90000) 000-00'), '919000000000');
    },
  );

  test('validates optional phone and email contact values', () {
    expect(isValidPhone(null), isFalse);
    expect(isValidPhone(''), isFalse);
    expect(isValidPhone('+91 90000 00000'), isTrue);
    expect(isValidEmail(null), isFalse);
    expect(isValidEmail('not-an-email'), isFalse);
    expect(isValidEmail('member@example.org'), isTrue);
  });
}
