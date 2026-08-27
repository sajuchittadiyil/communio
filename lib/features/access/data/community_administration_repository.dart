import 'package:supabase_flutter/supabase_flutter.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

class CommunityEventRecord {
  const CommunityEventRecord({
    required this.id,
    required this.title,
    required this.type,
    required this.startsAt,
    required this.status,
    required this.visibleToProvince,
    this.endsAt,
    this.venue,
    this.description,
    this.responsibleMemberId,
  });
  final String id;
  final String title;
  final String type;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String status;
  final bool visibleToProvince;
  final String? venue;
  final String? description;
  final String? responsibleMemberId;
}

typedef CommunityResidentOption = ({String id, String name});

class CommunityMeetingRecord {
  const CommunityMeetingRecord({
    required this.id,
    required this.title,
    required this.meetingDate,
    required this.summary,
    required this.visibleToProvince,
    this.decisions,
    this.actionItems,
    this.nextMeetingDate,
    this.createdAt,
    this.updatedAt,
  });
  final String id;
  final String title;
  final DateTime meetingDate;
  final String summary;
  final String? decisions;
  final String? actionItems;
  final DateTime? nextMeetingDate;
  final bool visibleToProvince;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

abstract interface class CommunityAdministrationRepository {
  Future<List<CommunityEventRecord>> fetchEvents();
  Future<List<CommunityMeetingRecord>> fetchMeetings();
  Future<List<CommunityResidentOption>> fetchResidents();
  Future<void> saveEvent(CommunityEventRecord event, {required bool create});
  Future<void> saveMeeting(
    CommunityMeetingRecord meeting, {
    required bool create,
  });
  Future<void> deleteEvent(String id);
}

class SupabaseCommunityAdministrationRepository
    implements CommunityAdministrationRepository {
  const SupabaseCommunityAdministrationRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<CommunityEventRecord>> fetchEvents() async {
    final rows = await _client
        .from('community_events')
        .select()
        .order('starts_at');
    return rows.map(_event).toList(growable: false);
  }

  @override
  Future<List<CommunityMeetingRecord>> fetchMeetings() async {
    final rows = await _client
        .from('community_meetings')
        .select()
        .order('meeting_date', ascending: false);
    return rows.map(_meeting).toList(growable: false);
  }

  @override
  Future<List<CommunityResidentOption>> fetchResidents() async {
    final rows = await _client
        .from('v_community_superior_residents_safe')
        .select('member_id,display_name')
        .order('display_name');
    return rows
        .map(
          (row) => (
            id: row['member_id'].toString(),
            name: DemoPersonaPresenter.memberName(
              row['member_id']?.toString(),
              row['display_name']?.toString() ?? 'Religious',
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveEvent(
    CommunityEventRecord event, {
    required bool create,
  }) async {
    if (create) {
      await _client.rpc(
        'create_community_event_safe',
        params: {
          'event_title': event.title,
          'event_type_code': event.type,
          'event_starts_at': event.startsAt.toUtc().toIso8601String(),
          'event_ends_at': event.endsAt?.toUtc().toIso8601String(),
          'event_venue': event.venue,
          'event_description': event.description,
          'event_responsible_member_id': event.responsibleMemberId,
          'event_status': event.status,
          'event_visible_to_province': event.visibleToProvince,
        },
      );
      return;
    }
    await _client
        .from('community_events')
        .update({
          'title': event.title,
          'event_type': event.type,
          'starts_at': event.startsAt.toUtc().toIso8601String(),
          'ends_at': event.endsAt?.toUtc().toIso8601String(),
          'venue': event.venue,
          'description': event.description,
          'responsible_member_id': event.responsibleMemberId,
          'status': event.status,
          'visible_to_province': event.visibleToProvince,
        })
        .eq('id', event.id);
  }

  @override
  Future<void> saveMeeting(
    CommunityMeetingRecord meeting, {
    required bool create,
  }) async {
    if (create) {
      await _client.rpc(
        'save_community_meeting_safe',
        params: {
          'meeting_title': meeting.title,
          'meeting_on': _date(meeting.meetingDate),
          'meeting_summary': meeting.summary,
          'meeting_decisions': meeting.decisions,
          'meeting_action_items': meeting.actionItems,
          'meeting_next_date': meeting.nextMeetingDate == null
              ? null
              : _date(meeting.nextMeetingDate!),
          'meeting_visible_to_province': meeting.visibleToProvince,
        },
      );
      return;
    }
    await _client
        .from('community_meetings')
        .update({
          'meeting_date': _date(meeting.meetingDate),
          'title': meeting.title,
          'summary': meeting.summary,
          'decisions': meeting.decisions,
          'action_items': meeting.actionItems,
          'next_meeting_date': meeting.nextMeetingDate == null
              ? null
              : _date(meeting.nextMeetingDate!),
          'visible_to_province': meeting.visibleToProvince,
        })
        .eq('id', meeting.id);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _client.from('community_events').delete().eq('id', id);
  }

  static CommunityEventRecord _event(Map<String, dynamic> row) =>
      CommunityEventRecord(
        id: row['id'].toString(),
        title: row['title']?.toString() ?? 'Community event',
        type: row['event_type']?.toString() ?? 'other',
        startsAt: DateTime.parse(row['starts_at'].toString()).toLocal(),
        endsAt: DateTime.tryParse(row['ends_at']?.toString() ?? '')?.toLocal(),
        venue: row['venue']?.toString(),
        description: row['description']?.toString(),
        responsibleMemberId: row['responsible_member_id']?.toString(),
        status: row['status']?.toString() ?? 'confirmed',
        visibleToProvince: row['visible_to_province'] == true,
      );

  static CommunityMeetingRecord _meeting(Map<String, dynamic> row) =>
      CommunityMeetingRecord(
        id: row['id'].toString(),
        title: row['title']?.toString() ?? 'Community meeting',
        meetingDate: DateTime.parse(row['meeting_date'].toString()),
        summary: row['summary']?.toString() ?? '',
        decisions: row['decisions']?.toString(),
        actionItems: row['action_items']?.toString(),
        nextMeetingDate: DateTime.tryParse(
          row['next_meeting_date']?.toString() ?? '',
        ),
        visibleToProvince: row['visible_to_province'] == true,
        createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
      );

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
