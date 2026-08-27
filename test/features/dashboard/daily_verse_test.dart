import 'package:communio/features/dashboard/models/daily_verse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily verse is deterministic for a date and changes next day', () {
    final date = DateTime(2026, 8, 20, 8, 30);
    final laterSameDay = DateTime(2026, 8, 20, 22, 45);
    final nextDay = DateTime(2026, 8, 21);

    expect(DailyVerseCalendar.verses.length, greaterThanOrEqualTo(30));
    expect(
      DailyVerseCalendar.forDate(date),
      same(DailyVerseCalendar.forDate(laterSameDay)),
    );
    expect(
      DailyVerseCalendar.forDate(nextDay).reference,
      isNot(DailyVerseCalendar.forDate(date).reference),
    );
  });
}
