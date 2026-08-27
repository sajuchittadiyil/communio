import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/member_celebration.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

abstract interface class MemberCelebrationsRepository {
  Future<List<MemberCelebration>> fetchToday({DateTime? today});
}

class SupabaseMemberCelebrationsRepository
    implements MemberCelebrationsRepository {
  const SupabaseMemberCelebrationsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MemberCelebration>> fetchToday({DateTime? today}) async {
    final start = _dateOnly(today ?? DateTime.now());
    final rows = await _client
        .from('v_member_celebrations_safe')
        .select()
        .eq('next_celebration_date', _iso(start))
        .order('next_celebration_date')
        .order('display_name');
    return MemberCelebrationMapper.fromRows(rows, today: start, horizonDays: 0);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class MemberCelebrationMapper {
  MemberCelebrationMapper._();

  static List<MemberCelebration> fromRows(
    Iterable<Map<String, dynamic>> rows, {
    required DateTime today,
    int horizonDays = 30,
  }) {
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(Duration(days: horizonDays));
    final celebrations = rows
        .map(_fromRow)
        .whereType<MemberCelebration>()
        .where((item) => !item.date.isBefore(start) && !item.date.isAfter(end))
        .toList(growable: false);
    return [...celebrations]..sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date != 0 ? date : a.displayName.compareTo(b.displayName);
    });
  }

  static MemberCelebration? _fromRow(Map<String, dynamic> row) {
    final memberId = row['member_id']?.toString();
    final religiousId = row['religious_id']?.toString();
    final displayName = row['display_name']?.toString();
    final type = _type(row['celebration_type']?.toString());
    final date = DateTime.tryParse(
      row['next_celebration_date']?.toString() ?? '',
    );
    if (memberId == null ||
        religiousId == null ||
        displayName == null ||
        type == null ||
        date == null) {
      return null;
    }
    return MemberCelebration(
      memberId: memberId,
      religiousId: religiousId,
      displayName: DemoPersonaPresenter.memberName(memberId, displayName),
      photoUrl: DemoPersonaPresenter.memberPhoto(
        memberId,
        row['photo_url']?.toString(),
      ),
      type: type,
      date: DateTime(date.year, date.month, date.day),
      sourceYear: int.tryParse(row['source_year']?.toString() ?? ''),
    );
  }

  static MemberCelebrationType? _type(String? value) => switch (value) {
    'birthday' => MemberCelebrationType.birthday,
    'feast_day' => MemberCelebrationType.feastDay,
    'first_profession' => MemberCelebrationType.firstProfession,
    'perpetual_profession' => MemberCelebrationType.perpetualProfession,
    'ordination' => MemberCelebrationType.ordination,
    _ => null,
  };
}

class EmptyMemberCelebrationsRepository
    implements MemberCelebrationsRepository {
  const EmptyMemberCelebrationsRepository();

  @override
  Future<List<MemberCelebration>> fetchToday({DateTime? today}) async =>
      const [];
}
