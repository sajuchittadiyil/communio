import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/colors.dart';
import '../models/dashboard_event_classifier.dart';
import '../models/dashboard_models.dart';
import 'dashboard_repository.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

class SupabaseDashboardRepository implements DashboardRepository {
  const SupabaseDashboardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<DashboardSnapshot> fetchDashboard() async {
    try {
      final results = await Future.wait([
        _client.from('v_demo_province_pulse').select(),
        _client.from('v_demo_upcoming_birthdays').select(),
        _client.from('v_demo_upcoming_feast_days').select(),
        _client.from('v_demo_member_attention_events').select(),
        _client.from('v_demo_recent_appointments').select(),
        _client.from('v_demo_current_communities').select(),
        _client.from('v_demo_formation_pipeline').select(),
        _client.from('v_demo_current_office_holders').select(),
        _client.from('v_demo_member_public_contacts').select(),
        _client.from('members').select('id,photo_url'),
        _client
            .from('province_updates')
            .select()
            .eq('is_active', true)
            .eq('is_dashboard_visible', true)
            .eq('visibility', 'province')
            .order('published_at', ascending: false)
            .limit(6),
        _client
            .from('community_events')
            .select('*,communities(name)')
            .neq('status', 'cancelled')
            .order('starts_at')
            .limit(12),
        _client
            .from('community_meetings')
            .select('*,communities(name)')
            .order('updated_at', ascending: false)
            .limit(6),
      ]);
      final pulse = results[0].firstOrNull ?? const <String, dynamic>{};
      final memberPhotos = <String, String?>{};
      for (final row in results[9]) {
        final id = _text(row, ['id']);
        if (id != null) memberPhotos[id] = _text(row, ['photo_url']);
      }
      final events = results[3].map((row) => _event(row, memberPhotos)).toList()
        ..sort(_eventOrder);
      final publicContacts = {
        for (final row in results[8]) _text(row, ['member_id']): row,
      };
      final celebrations = [
        ...results[1].map(
          (row) => _birthday(row, publicContacts, memberPhotos),
        ),
        ...results[2].map(
          (row) => _feastDay(row, publicContacts, memberPhotos),
        ),
      ]..sort((a, b) => a.date.compareTo(b.date));

      return DashboardSnapshot(
        metrics: [
          _metric(
            _value(pulse, ['active_members'], results[0].length),
            'Religious',
            Icons.groups_2_outlined,
            AppColors.info,
          ),
          _metric(
            _value(pulse, ['active_communities'], results[5].length),
            'Communities',
            Icons.church_outlined,
            AppColors.success,
          ),
          _metric(
            _value(pulse, ['ministries']),
            'Ministries',
            Icons.volunteer_activism_outlined,
            AppColors.purple,
          ),
          _metric(
            _value(pulse, ['members_in_formation'], results[6].length),
            'Total Formation',
            Icons.school_outlined,
            AppColors.cyan,
          ),
          _metric(
            _value(pulse, ['candidates']),
            'Candidates',
            Icons.person_add_alt_outlined,
            AppColors.warning,
          ),
          _metric(
            _value(pulse, ['novices']),
            'Novices',
            Icons.auto_stories_outlined,
            AppColors.info,
          ),
          _metric(
            _value(pulse, ['temporary_professed']),
            'Temporary Professed',
            Icons.workspace_premium_outlined,
            AppColors.success,
          ),
          _metric(
            '${results[7].length}',
            'Office Holders',
            Icons.badge_outlined,
            AppColors.purple,
          ),
        ],
        attention: [
          ...events.where(DashboardEventClassifier.isProvinceAttention),
          ..._appointmentAttentionEvents(results[4], memberPhotos),
        ]..sort(_currentAttentionOrder),
        celebrations: celebrations
            .where(DashboardEventClassifier.isCurrentCelebration)
            .take(6)
            .toList(),
        movements: events
            .where(DashboardEventClassifier.isCurrentMovement)
            .toList(),
        upcomingEvents:
            events
                .where(DashboardEventClassifier.isUpcomingGovernanceEvent)
                .followedBy(results[11].map(_communityEvent))
                .toList()
              ..sort(
                (a, b) => (a.fromDate ?? DateTime(1)).compareTo(
                  b.fromDate ?? DateTime(1),
                ),
              ),
        recentAppointments: _appointments(results[4], memberPhotos),
        recentUpdates: [
          ..._communityUpdates(results[12]),
          ..._communityEventUpdates(results[11]),
          ..._recentUpdates(results[10]),
        ].take(6).toList(),
      );
    } catch (error) {
      throw DashboardException(cause: error);
    }
  }

  PulseEvent _communityEvent(Map<String, dynamic> row) {
    final community = row['communities'] as Map<String, dynamic>?;
    return PulseEvent(
      id: row['id'].toString(),
      memberName: community?['name']?.toString() ?? 'Community',
      type: row['event_type']?.toString() ?? 'community_event',
      title: row['title']?.toString() ?? 'Community event',
      location: [
        community?['name'],
        row['venue'],
      ].whereType<Object>().join(' · '),
      fromDate: _date(row, ['starts_at']),
      toDate: _date(row, ['ends_at']),
      timing: 'UPCOMING',
      priority: row['status']?.toString() ?? 'confirmed',
      icon: Icons.event_outlined,
      accent: AppColors.info,
    );
  }

  List<ProvinceUpdate> _communityUpdates(List<Map<String, dynamic>> rows) =>
      rows.map((row) {
        final community = row['communities'] as Map<String, dynamic>?;
        return ProvinceUpdate(
          title: 'Community Meeting Minutes added',
          detail: community?['name']?.toString() ?? 'Community',
          date: _friendlyDate(_date(row, ['updated_at', 'meeting_date'])),
          icon: Icons.description_outlined,
        );
      }).toList();

  List<ProvinceUpdate> _communityEventUpdates(
    List<Map<String, dynamic>> rows,
  ) => rows.map((row) {
    final community = row['communities'] as Map<String, dynamic>?;
    return ProvinceUpdate(
      title: '${row['title'] ?? 'Community event'} updated',
      detail: community?['name']?.toString() ?? 'Community',
      date: _friendlyDate(_date(row, ['updated_at', 'starts_at'])),
      icon: Icons.edit_calendar_outlined,
    );
  }).toList();

  OverviewMetric _metric(
    String value,
    String label,
    IconData icon,
    Color accent,
  ) => OverviewMetric(value: value, label: label, icon: icon, accent: accent);

  List<PulseEvent> _appointmentAttentionEvents(
    List<Map<String, dynamic>> rows,
    Map<String, String?> memberPhotos,
  ) {
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final alerts = <PulseEvent>[];

    bool withinTwoDays(DateTime? value) {
      if (value == null) return false;
      final local = value.toLocal();
      final date = DateTime(local.year, local.month, local.day);
      final days = date.difference(today).inDays;
      return days >= 0 && days <= 2;
    }

    for (final row in rows) {
      final start = _date(row, ['from_date', 'start_date', 'appointment_date']);
      final end = _date(row, ['to_date', 'end_date', 'appointment_end_date']);

      final startingSoon = withinTwoDays(start);
      final endingSoon = withinTwoDays(end);

      if (!startingSoon && !endingSoon) continue;

      final memberId = _text(row, ['member_id']);
      final office = _label(_text(row, ['appointment_code'])) ?? 'Appointment';
      final location =
          _text(row, ['location_name']) ?? _text(row, ['appointment_category']);

      final alertDate = startingSoon ? start : end;
      final action = startingSoon ? 'Upcoming' : 'Ending';

      alerts.add(
        PulseEvent(
          id: 'appointment-${memberId ?? 'unknown'}-${_text(row, ['appointment_code']) ?? 'office'}-${alertDate?.millisecondsSinceEpoch ?? 0}',
          memberId: memberId,
          photoUrl: memberPhotos[memberId],
          memberName: _text(row, ['display_name']) ?? 'Religious',
          type: 'appointment',
          title: '$action $office',
          location: location,
          fromDate: alertDate,
          toDate: null,
          timing: 'UPCOMING',
          priority: 'high',
          icon: Icons.badge_outlined,
          accent: AppColors.warning,
        ),
      );
    }

    return alerts;
  }

  List<ProvinceUpdate> _recentUpdates(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final publishedAt = _date(row, ['published_at']);

      final type = _code(row, ['update_type']) ?? 'update';

      final icon = switch (type) {
        'provincial_circular' => Icons.campaign_outlined,
        'provincial_announcement' => Icons.notifications_active_outlined,
        'community_meeting' => Icons.groups_outlined,
        'community_update' => Icons.home_work_outlined,
        'ministry_meeting' => Icons.meeting_room_outlined,
        'ministry_update' => Icons.volunteer_activism_outlined,
        'ministry_achievement' => Icons.emoji_events_outlined,
        'celebration' => Icons.celebration_outlined,
        'formation_update' => Icons.school_outlined,
        _ => Icons.new_releases_outlined,
      };

      final source = _text(row, ['source_label']);
      final summary = _text(row, ['summary']);

      final detail = [?source, ?summary].join(' · ');

      return ProvinceUpdate(
        title: _text(row, ['title']) ?? 'Province Update',
        detail: detail,
        date: _friendlyDate(publishedAt),
        icon: icon,
      );
    }).toList();
  }

  List<ProvinceUpdate> _appointments(
    List<Map<String, dynamic>> rows,
    Map<String, String?> memberPhotos,
  ) {
    final values = rows.map((row) {
      final start = _date(row, ['from_date', 'start_date', 'appointment_date']);
      return (
        start: start,
        provincial: _code(row, ['appointment_category']) == 'province office',
        update: ProvinceUpdate(
          title: _label(_text(row, ['appointment_code'])) ?? 'Appointment',
          detail:
              '${_text(row, ['display_name']) ?? 'Religious'} · ${_text(row, ['location_name']) ?? _text(row, ['appointment_category']) ?? 'Province'}',
          date: _friendlyDate(start),
          icon: Icons.badge_outlined,
          memberId: _text(row, ['member_id']),
          photoUrl: memberPhotos[_text(row, ['member_id'])],
        ),
      );
    }).toList();
    values.sort((a, b) {
      final aOffice = a.provincial ? 0 : 1;
      final bOffice = b.provincial ? 0 : 1;
      final category = aOffice.compareTo(bOffice);
      return category != 0
          ? category
          : (b.start ?? DateTime(1)).compareTo(a.start ?? DateTime(1));
    });
    return values.map((value) => value.update).take(6).toList();
  }

  PulseEvent _event(
    Map<String, dynamic> row,
    Map<String, String?> memberPhotos,
  ) {
    final type = _code(row, ['event_type']) ?? 'event';
    final visual = _eventVisual(type);
    return PulseEvent(
      id: _text(row, ['event_id']) ?? '$type-${_text(row, ['member_id'])}',
      memberId: _text(row, ['member_id']),
      photoUrl: memberPhotos[_text(row, ['member_id'])],
      memberName: _text(row, ['display_name']) ?? 'Religious',
      type: type,
      title: _text(row, ['title']) ?? _label(type) ?? 'Province event',
      location: _text(row, ['location']),
      fromDate: _date(row, ['from_date']),
      toDate: _date(row, ['to_date']),
      timing: _text(row, ['timing_status']) ?? 'UPCOMING',
      priority: _text(row, ['priority']) ?? 'normal',
      icon: visual.icon,
      accent: visual.color,
    );
  }

  CelebrationItem _birthday(
    Map<String, dynamic> row,
    Map<String?, Map<String, dynamic>> contacts,
    Map<String, String?> memberPhotos,
  ) => CelebrationItem(
    memberId: _text(row, ['member_id']),
    photoUrl: memberPhotos[_text(row, ['member_id'])],
    memberName: _text(row, ['display_name']) ?? 'Religious',
    kind: 'Birthday',
    detail: _text(row, ['turning_age']) == null
        ? null
        : 'Turning ${_text(row, ['turning_age'])}',
    date: _date(row, ['next_birthday']) ?? DateTime(9999),
    daysUntil: _birthdayDays(row),
    icon: Icons.cake_outlined,
    accent: AppColors.purple,
    mobile: _text(contacts[_text(row, ['member_id'])] ?? const {}, ['mobile']),
    whatsApp: _text(contacts[_text(row, ['member_id'])] ?? const {}, [
      'whatsapp',
    ]),
  );

  CelebrationItem _feastDay(
    Map<String, dynamic> row,
    Map<String?, Map<String, dynamic>> contacts,
    Map<String, String?> memberPhotos,
  ) => CelebrationItem(
    memberId: _text(row, ['member_id']),
    photoUrl: memberPhotos[_text(row, ['member_id'])],
    memberName: _text(row, ['display_name']) ?? 'Religious',
    kind: 'Feast Day',
    detail: _text(row, ['feast_name']),
    date: _date(row, ['next_feast_date']) ?? DateTime(9999),
    daysUntil: int.tryParse(_text(row, ['days_until_feast']) ?? '') ?? 9999,
    icon: Icons.church_outlined,
    accent: AppColors.secondaryDark,
    mobile: _text(contacts[_text(row, ['member_id'])] ?? const {}, ['mobile']),
    whatsApp: _text(contacts[_text(row, ['member_id'])] ?? const {}, [
      'whatsapp',
    ]),
  );

  int _eventOrder(PulseEvent a, PulseEvent b) {
    int group(PulseEvent event) => event.isHighPriority
        ? (event.isCurrent ? 0 : 1)
        : (event.isCurrent ? 2 : 3);
    final grouped = group(a).compareTo(group(b));
    return grouped != 0
        ? grouped
        : (a.fromDate ?? DateTime(9999)).compareTo(
            b.fromDate ?? DateTime(9999),
          );
  }

  int _currentAttentionOrder(PulseEvent a, PulseEvent b) {
    final priority = (a.isHighPriority ? 0 : 1).compareTo(
      b.isHighPriority ? 0 : 1,
    );
    return priority != 0
        ? priority
        : (a.fromDate ?? DateTime(9999)).compareTo(
            b.fromDate ?? DateTime(9999),
          );
  }

  int _birthdayDays(Map<String, dynamic> row) {
    final birth = _date(row, ['date_of_birth']);
    if (birth == null) return 9999;
    final today = DateTime.now();
    return birth.month == today.month && birth.day == today.day
        ? 0
        : int.tryParse(_text(row, ['days_until']) ?? '') ?? 9999;
  }

  ({IconData icon, Color color}) _eventVisual(String type) => switch (type) {
    'hospital' => (icon: Icons.local_hospital_outlined, color: AppColors.error),
    'travel' => (icon: Icons.flight_outlined, color: AppColors.info),
    'training' => (
      icon: Icons.workspace_premium_outlined,
      color: AppColors.cyan,
    ),
    'meeting' => (icon: Icons.groups_outlined, color: AppColors.purple),
    'retreat' => (
      icon: Icons.self_improvement_outlined,
      color: AppColors.secondaryDark,
    ),
    'home_leave' => (icon: Icons.home_outlined, color: AppColors.warning),
    'study' => (icon: Icons.school_outlined, color: AppColors.cyan),
    'visit' => (
      icon: Icons.travel_explore_outlined,
      color: AppColors.secondaryDark,
    ),
    'return' => (icon: Icons.login_outlined, color: AppColors.success),
    _ => (icon: Icons.event_outlined, color: AppColors.primary),
  };

  String _value(
    Map<String, dynamic> row,
    List<String> keys, [
    int fallback = 0,
  ]) => _text(row, keys) ?? '$fallback';

  static String? _text(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        final memberId = row['member_id']?.toString();
        if (key.contains('photo')) {
          return DemoPersonaPresenter.memberPhoto(memberId, value);
        }
        if (memberId != null &&
            (key.contains('name') || key.contains('title'))) {
          return DemoPersonaPresenter.memberName(memberId, value);
        }
        return value;
      }
    }
    return null;
  }

  static String? _code(Map<String, dynamic> row, List<String> keys) =>
      _text(row, keys)?.toLowerCase();
  static DateTime? _date(Map<String, dynamic> row, List<String> keys) =>
      DateTime.tryParse(_text(row, keys) ?? '');
  static String? _label(String? value) => value
      ?.split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
  static String _friendlyDate(DateTime? date) => date == null
      ? 'Date unavailable'
      : '${date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';
}
