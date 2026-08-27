import 'package:communio/features/province_modules/data/calendar_entry_mapper.dart';
import 'package:communio/features/province_modules/data/province_repository.dart';
import 'package:communio/features/province_modules/models/province_models.dart';
import 'package:communio/features/province_modules/screens/calendar_screen.dart';
import 'package:communio/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('week calculation uses Monday through Sunday', () {
    final start = startOfCalendarWeek(DateTime(2026, 8, 20));
    expect(start, DateTime(2026, 8, 17));
    expect(start.add(const Duration(days: 6)), DateTime(2026, 8, 23));
    expect(
      calendarWeekRange(start, start.add(const Duration(days: 6))),
      '17–23 August 2026',
    );
  });

  test('multi-day event occurs on each inclusive date', () {
    final event = CalendarEntry(
      title: 'Provincial visitation',
      date: DateTime(2026, 8, 19),
      endDate: DateTime(2026, 8, 21),
      category: 'Visitation',
    );
    expect(event.occursOn(DateTime(2026, 8, 18)), isFalse);
    expect(event.occursOn(DateTime(2026, 8, 19)), isTrue);
    expect(event.occursOn(DateTime(2026, 8, 21)), isTrue);
    expect(event.occursOn(DateTime(2026, 8, 22)), isFalse);
  });

  test('mapper includes only Provincial-team birthdays and travel', () {
    final entries = CalendarEntryMapper.map(
      officeRows: const [
        {'member_id': 'leader', 'office_type_code': 'provincial'},
        {'member_id': 'ordinary', 'office_type_code': 'community_superior'},
      ],
      memberRows: const [
        {
          'member_id': 'leader',
          'display_name': 'Leader',
          'date_of_birth': '1970-08-20',
        },
        {
          'member_id': 'ordinary',
          'display_name': 'Ordinary',
          'date_of_birth': '1975-08-21',
        },
      ],
      attentionRows: const [
        {
          'id': 'team-travel',
          'member_id': 'leader',
          'event_type': 'travel',
          'title': 'Provincial travelling to Ranchi',
          'from_date': '2026-08-19',
          'to_date': '2026-08-21',
        },
        {
          'id': 'ordinary-travel',
          'member_id': 'ordinary',
          'event_type': 'travel',
          'title': 'Member travelling',
          'from_date': '2026-08-19',
        },
        {
          'id': 'council',
          'event_type': 'council',
          'title': 'Provincial Council Meeting',
          'from_date': '2026-08-20',
        },
        {
          'id': 'noise',
          'event_type': 'health',
          'title': 'Routine event',
          'from_date': '2026-08-20',
        },
        {
          'id': 'student-renewal',
          'event_type': 'renewal',
          'title': 'Student renewal due',
          'from_date': '2026-08-25',
        },
        {
          'id': 'teacher-renewal',
          'event_type': 'renewal',
          'title': 'Teacher renewal due',
          'from_date': '2026-08-25',
        },
        {
          'id': 'social-worker-renewal',
          'event_type': 'renewal',
          'title': 'Social Worker renewal due',
          'from_date': '2026-08-25',
        },
        {
          'id': 'affiliation-renewal',
          'event_type': 'renewal',
          'title': 'School affiliation renewal',
          'from_date': '2026-08-26',
        },
      ],
      communityRows: const [
        {
          'id': 'community-1',
          'name': 'St. Antony Community',
          'feast_month': 8,
          'feast_day': 22,
        },
      ],
      calendarYear: 2026,
    );

    final birthdays = entries.where((entry) => entry.category == 'Birthday');
    expect(birthdays.map((entry) => entry.memberId).toSet(), {'leader'});
    expect(birthdays.map((entry) => entry.date.year), [2025, 2026, 2027]);
    expect(
      entries.where((entry) => entry.category == 'Travel').single.id,
      'team-travel',
    );
    expect(entries.any((entry) => entry.id == 'ordinary-travel'), isFalse);
    expect(entries.any((entry) => entry.id == 'noise'), isFalse);
    expect(entries.any((entry) => entry.id == 'student-renewal'), isFalse);
    expect(entries.any((entry) => entry.id == 'teacher-renewal'), isFalse);
    expect(
      entries.any((entry) => entry.id == 'social-worker-renewal'),
      isFalse,
    );
    expect(
      entries
          .where((entry) => entry.category == 'Deadline / Renewal')
          .single
          .id,
      'affiliation-renewal',
    );
    expect(
      entries.map((entry) => entry.category),
      containsAll(['Meeting / Governance', 'Community', 'Deadline / Renewal']),
    );
  });

  test('category presentation uses the Communio semantic palette', () {
    expect(calendarCategoryColor('Meeting / Governance'), AppColors.primary);
    expect(calendarCategoryIcon('Travel'), Icons.flight_outlined);
    expect(calendarCategoryIcon('Birthday'), Icons.cake_outlined);
    expect(
      calendarShortCategory(
        CalendarEntry(
          title: 'Provincial Council Meeting',
          date: DateTime(2026, 8, 20),
          category: 'Meeting / Governance',
          eventType: 'council',
        ),
      ),
      'Council',
    );
    expect(
      calendarShortCategory(
        CalendarEntry(
          title: 'Community feast',
          date: DateTime(2026, 8, 20),
          category: 'Community',
          eventType: 'community_feast',
        ),
      ),
      'Feast',
    );
  });

  testWidgets(
    'week is default, navigates, selects days, and shows event labels',
    (tester) async {
      await _pumpCalendar(tester);

      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('17–23 August 2026'), findsOneWidget);
      expect(find.text('Council'), findsOneWidget);
      expect(find.text('Travel'), findsNWidgets(3));
      expect(find.text('Ranchi travel'), findsWidgets);
      expect(find.text('Provincial Council Meeting'), findsWidgets);

      await tester.tap(find.byKey(const Key('calendar-day-2026-8-22')));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('DAY AGENDA'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('DAY AGENDA'), findsOneWidget);
      expect(
        find.text('No important Province events scheduled for this date.'),
        findsOneWidget,
      );

      await tester.drag(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, 1600),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('next-week')));
      await tester.pump();
      expect(find.text('24–30 August 2026'), findsOneWidget);
      await tester.tap(find.byKey(const Key('previous-week')));
      await tester.pump();
      expect(find.text('17–23 August 2026'), findsOneWidget);
    },
  );

  testWidgets(
    'month toggle, month navigation, and chronological month events work',
    (tester) async {
      await _pumpCalendar(tester);
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(find.text('MONTH OVERVIEW'), findsOneWidget);
      expect(find.text('August 2026'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('MONTH EVENTS'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Provincial Council Meeting'), findsOneWidget);
      expect(find.text('Ranchi travel'), findsWidgets);

      await tester.tap(find.byKey(const Key('next-month')));
      await tester.pump();
      expect(find.text('September 2026'), findsOneWidget);
      await tester.drag(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, 1200),
      );
      await tester.pump();
      await tester.tap(find.text('Week'));
      await tester.pump();
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(
        find.text('Birthdays currently available from Supabase.'),
        findsNothing,
      );
      expect(find.text('Upcoming birthdays'), findsNothing);
    },
  );
}

Future<void> _pumpCalendar(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: CalendarScreen(
        repository: const _CalendarRepository(),
        initialDate: DateTime(2026, 8, 20),
        onMember: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _CalendarRepository implements ProvinceRepository {
  const _CalendarRepository();
  @override
  Future<List<CalendarEntry>> fetchCalendarEntries() async => [
    CalendarEntry(
      id: 'council',
      title: 'Provincial Council Meeting',
      date: DateTime(2026, 8, 20),
      category: 'Meeting / Governance',
      location: 'Provincial House',
    ),
    CalendarEntry(
      id: 'travel',
      title: 'Ranchi travel',
      date: DateTime(2026, 8, 19),
      endDate: DateTime(2026, 8, 21),
      category: 'Travel',
    ),
  ];
  @override
  Future<List<AppointmentCompliance>> fetchAppointmentCompliance() async =>
      const [];
  @override
  Future<List<CommunityRecord>> fetchCommunities() async => const [];
  @override
  Future<List<EligibilityRecord>> fetchEligibility(
    String roleCode, {
    required bool office,
  }) async => const [];
  @override
  Future<List<EligibilityRole>> fetchEligibilityRoles() async => const [];
  @override
  Future<List<FormationMember>> fetchFormation() async => const [];
  @override
  Future<List<MinistryRecord>> fetchMinistries() async => const [];
  @override
  Future<List<OfficeHolder>> fetchOfficeHolders() async => const [];
}
