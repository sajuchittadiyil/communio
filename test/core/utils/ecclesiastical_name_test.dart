import 'package:communio/core/utils/ecclesiastical_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not duplicate an existing ecclesiastical title', () {
    expect(
      composeEcclesiasticalName(
        displayName: 'Bro. Jaison Kollamparambil',
        title: 'Bro.',
      ),
      'Bro. Jaison Kollamparambil',
    );
    expect(
      composeEcclesiasticalName(displayName: 'fr Thomas Mathew', title: 'Fr.'),
      'fr Thomas Mathew',
    );
  });

  test('adds a separately stored title when the name has none', () {
    expect(
      composeEcclesiasticalName(displayName: 'Thomas Mathew', title: 'Fr.'),
      'Fr. Thomas Mathew',
    );
  });

  test('does not confuse a name beginning with Fr with a title', () {
    expect(
      composeEcclesiasticalName(
        displayName: 'Francis Puthenpurackal',
        title: 'Fr.',
      ),
      'Fr. Francis Puthenpurackal',
    );
  });
}
