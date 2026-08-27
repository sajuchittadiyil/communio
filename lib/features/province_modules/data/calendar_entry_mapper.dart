import '../models/province_models.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

class CalendarEntryMapper {
  const CalendarEntryMapper._();

  static const leadershipOfficeTerms = {
    'provincial',
    'assistant_provincial',
    'vice_provincial',
    'provincial_secretary',
    'provincial_bursar',
    'provincial_treasurer',
    'provincial_councillor',
  };

  static Set<String> leadershipMemberIds(
    Iterable<Map<String, dynamic>> officeRows,
  ) => officeRows
      .where(
        (row) => _isLeadershipOffice(
          _text(row, ['office_type_code', 'office_code', 'office_name']),
        ),
      )
      .map((row) => _text(row, ['member_id']))
      .whereType<String>()
      .toSet();

  static List<CalendarEntry> map({
    required Iterable<Map<String, dynamic>> officeRows,
    required Iterable<Map<String, dynamic>> memberRows,
    required Iterable<Map<String, dynamic>> attentionRows,
    required Iterable<Map<String, dynamic>> communityRows,
    required int calendarYear,
  }) {
    final teamIds = leadershipMemberIds(officeRows);
    final recurringYears = [calendarYear - 1, calendarYear, calendarYear + 1];
    final entries = <CalendarEntry>[
      for (final year in recurringYears)
        ..._birthdays(memberRows, teamIds, year),
      ...attentionRows
          .map((row) => _attention(row, teamIds))
          .whereType<CalendarEntry>(),
      for (final year in recurringYears)
        ...communityRows
            .map((row) => _communityFeast(row, year))
            .whereType<CalendarEntry>(),
    ];
    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries;
  }

  static Iterable<CalendarEntry> _birthdays(
    Iterable<Map<String, dynamic>> rows,
    Set<String> teamIds,
    int year,
  ) sync* {
    for (final row in rows) {
      final memberId = _text(row, ['member_id', 'id']);
      final birth = _date(row, ['date_of_birth']);
      if (memberId == null || birth == null || !teamIds.contains(memberId)) {
        continue;
      }
      yield CalendarEntry(
        id: 'birthday-$memberId-$year',
        title:
            '${_text(row, ['display_name']) ?? 'Provincial team member'}’s birthday',
        date: DateTime(year, birth.month, birth.day),
        category: 'Birthday',
        eventType: 'birthday',
        memberId: memberId,
        relatedEntityType: 'member',
        relatedEntityId: memberId,
      );
    }
  }

  static CalendarEntry? _attention(
    Map<String, dynamic> row,
    Set<String> teamIds,
  ) {
    final start = _date(row, ['from_date', 'start_date', 'event_date']);
    if (start == null) return null;
    final type = (_text(row, ['event_type', 'event_type_code']) ?? '')
        .toLowerCase();
    final title = _text(row, ['title', 'event_title']) ?? 'Province event';
    final lowerTitle = title.toLowerCase();
    final memberId = _text(row, ['member_id']);
    final category = _category(type, lowerTitle);
    if (category == null) return null;
    if (category == 'Travel' &&
        (memberId == null || !teamIds.contains(memberId))) {
      return null;
    }
    return CalendarEntry(
      id: _text(row, ['id', 'event_id']),
      title: title,
      date: start,
      endDate: _date(row, ['to_date', 'end_date']),
      category: category,
      eventType: type,
      memberId: memberId,
      relatedEntityType: _text(row, ['related_entity_type']),
      relatedEntityId: _text(row, [
        'related_entity_id',
        'community_id',
        'ministry_id',
      ]),
      location: _text(row, ['location', 'location_name']),
      priority: _text(row, ['priority']),
      demo: _bool(row, ['is_demo', 'demo']),
    );
  }

  static CalendarEntry? _communityFeast(Map<String, dynamic> row, int year) {
    final month = _integer(row, ['feast_month']);
    final day = _integer(row, ['feast_day']);
    if (month == null ||
        day == null ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      return null;
    }
    final id = _text(row, ['community_id', 'id']);
    final name = _text(row, ['community_name', 'name']) ?? 'Community';
    return CalendarEntry(
      id: 'community-feast-${id ?? name}-$year',
      title: '$name feast',
      date: DateTime(year, month, day),
      category: 'Community',
      eventType: 'community_feast',
      relatedEntityType: 'community',
      relatedEntityId: id,
      location: _text(row, ['city', 'place', 'location']),
    );
  }

  static String? _category(String type, String title) {
    if (type == 'travel') return 'Travel';
    if (title.contains('visitation')) {
      return 'Visitation';
    }
    const institutionalTerms = [
      'affiliation',
      'licence',
      'license',
      'registration',
      'fcra',
      'statutory',
      'insurance',
      'policy',
      'accreditation',
      'compliance',
      'government approval',
    ];
    final institutional = institutionalTerms.any(title.contains);
    final deadlineLanguage = const [
      'renewal',
      'deadline',
      'filing',
    ].any(title.contains);
    if (type == 'filing' ||
        type == 'compliance' ||
        (institutional &&
            ({'renewal', 'deadline'}.contains(type) || deadlineLanguage))) {
      return 'Deadline / Renewal';
    }
    if ({
          'council',
          'commission',
          'chapter',
          'meeting',
          'governance',
          'audit',
        }.contains(type) ||
        const [
          'council',
          'commission',
          'chapter',
          'governance meeting',
        ].any(title.contains)) {
      return 'Meeting / Governance';
    }
    if (type == 'community_meeting' ||
        title.contains('community feast') ||
        title.contains('community meeting')) {
      return 'Community';
    }
    if ({
          'ministry_meeting',
          'inspection',
          'affiliation',
          'celebration',
        }.contains(type) ||
        const [
          'annual day',
          'inspection',
          'affiliation',
          'ministry meeting',
        ].any(title.contains)) {
      return 'Ministry';
    }
    return null;
  }

  static bool _isLeadershipOffice(String? raw) {
    if (raw == null) return false;
    final value = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return leadershipOfficeTerms.contains(value) ||
        value.startsWith('provincial_councillor');
  }

  static String? _text(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        final text = value.toString().trim();
        if (key.contains('name') || key.contains('title')) {
          return DemoPersonaPresenter.memberName(
            row['member_id']?.toString(),
            text,
          );
        }
        return text;
      }
    }
    return null;
  }

  static DateTime? _date(Map<String, dynamic> row, List<String> keys) {
    final value = _text(row, keys);
    return value == null ? null : DateTime.tryParse(value)?.toLocal();
  }

  static int? _integer(Map<String, dynamic> row, List<String> keys) =>
      int.tryParse(_text(row, keys) ?? '');

  static bool _bool(Map<String, dynamic> row, List<String> keys) {
    final value = _text(row, keys)?.toLowerCase();
    return value == 'true' || value == '1';
  }
}
