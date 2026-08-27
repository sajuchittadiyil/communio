import 'package:communio/features/religious_profile/data/member_timeline_mapper.dart';
import 'package:communio/features/religious_profile/models/religious_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes every trusted timeline source', () {
    final profile = _profile(
      vocation: [
        VocationEvent(
          sourceId: 'voc-1',
          label: 'First Profession',
          date: DateTime(1990, 6, 15),
        ),
      ],
      communities: [
        AssignmentRecord(
          kind: 'Community',
          name: 'St. Antony Community',
          role: 'Community Member',
          fromDate: DateTime(1994),
          toDate: DateTime(1998),
          relatedEntityId: 'community-1',
        ),
      ],
      ministries: [
        AssignmentRecord(
          kind: 'Ministry',
          name: 'St. Antony School',
          role: 'Teacher',
          fromDate: DateTime(1995),
          toDate: DateTime(2001),
          relatedEntityId: 'ministry-1',
        ),
      ],
      offices: [
        OfficeAppointment(
          office: 'Principal',
          context: 'St. Antony School',
          contextKind: OfficeContextKind.ministry,
          relatedEntityId: 'ministry-1',
          fromDate: DateTime(2018),
          toDate: DateTime(2024),
        ),
        OfficeAppointment(
          office: 'Community Superior',
          context: 'St. Antony Community',
          contextKind: OfficeContextKind.community,
          relatedEntityId: 'community-1',
          fromDate: DateTime(2002),
          toDate: DateTime(2005),
        ),
        OfficeAppointment(
          office: 'Provincial Councillor',
          context: 'Indian Province',
          contextKind: OfficeContextKind.province,
          relatedEntityId: 'province-1',
          fromDate: DateTime(2010),
          toDate: DateTime(2013),
        ),
      ],
      leave: [
        LeaveRecord(
          type: 'Sabbatical',
          fromDate: DateTime(2011),
          toDate: DateTime(2012),
          location: 'Rome, Italy',
        ),
      ],
    );

    final events = MemberTimelineMapper.fromProfile(profile);

    expect(events.map((event) => event.category).toSet(), {
      MemberTimelineCategory.vocation,
      MemberTimelineCategory.community,
      MemberTimelineCategory.ministry,
      MemberTimelineCategory.office,
      MemberTimelineCategory.leave,
    });
    expect(events.any((event) => event.title == 'First Profession'), isTrue);
    expect(events.any((event) => event.title == 'Community Member'), isTrue);
    expect(events.any((event) => event.title == 'Teacher'), isTrue);
    expect(
      events.any(
        (event) =>
            event.title == 'Principal' && event.relatedEntityType == 'ministry',
      ),
      isTrue,
    );
    expect(
      events.any(
        (event) =>
            event.title == 'Community Superior' &&
            event.relatedEntityType == 'community',
      ),
      isTrue,
    );
    expect(
      events.any(
        (event) =>
            event.title == 'Provincial Councillor' &&
            event.relatedEntityType == 'province',
      ),
      isTrue,
    );
    expect(
      events.any(
        (event) =>
            event.title == 'Sabbatical' && event.location == 'Rome, Italy',
      ),
      isTrue,
    );
  });

  test('marks valid open assignments current and retains exact precision', () {
    final events = MemberTimelineMapper.fromProfile(
      _profile(
        vocation: [
          VocationEvent(label: 'Ordination', date: DateTime(2001, 4, 21)),
          VocationEvent(
            label: 'First Profession',
            date: DateTime(1995),
            datePrecision: TimelineDatePrecision.year,
          ),
        ],
        ministries: [
          AssignmentRecord(
            kind: 'Ministry',
            name: 'St. Antony School',
            role: 'Principal',
            fromDate: DateTime(2023),
          ),
          AssignmentRecord(
            kind: 'Ministry',
            name: 'Future Ministry',
            role: 'Future Role',
            fromDate: DateTime.now().add(const Duration(days: 30)),
          ),
        ],
      ),
    );

    expect(
      events.firstWhere((event) => event.title == 'Principal').isCurrent,
      isTrue,
    );
    expect(
      events.firstWhere((event) => event.title == 'Future Role').isCurrent,
      isFalse,
    );
    expect(
      events.firstWhere((event) => event.title == 'Ordination').startPrecision,
      TimelineDatePrecision.day,
    );
    expect(
      events
          .firstWhere((event) => event.title == 'First Profession')
          .startPrecision,
      TimelineDatePrecision.year,
    );
  });

  test('suppresses only high-confidence office duplicates', () {
    final exactDates = (from: DateTime(2018), to: DateTime(2024));
    final events = MemberTimelineMapper.fromProfile(
      _profile(
        ministries: [
          AssignmentRecord(
            kind: 'Ministry',
            name: 'St. Antony School',
            role: 'Principal',
            relatedEntityId: 'ministry-1',
            fromDate: exactDates.from,
            toDate: exactDates.to,
          ),
          AssignmentRecord(
            kind: 'Ministry',
            name: 'St. Antony School',
            role: 'Principal',
            relatedEntityId: 'ministry-1',
            fromDate: DateTime(2017),
            toDate: exactDates.to,
          ),
        ],
        offices: [
          OfficeAppointment(
            office: 'Principal',
            context: 'St. Antony School',
            contextKind: OfficeContextKind.ministry,
            relatedEntityId: 'ministry-1',
            fromDate: exactDates.from,
            toDate: exactDates.to,
          ),
        ],
      ),
    );

    expect(events.where((event) => event.title == 'Principal'), hasLength(2));
    expect(
      events.where((event) => event.category == MemberTimelineCategory.office),
      hasLength(1),
    );
    expect(
      events.where(
        (event) => event.category == MemberTimelineCategory.ministry,
      ),
      hasLength(1),
    );
  });

  test('preserves overlapping uncertain records and sorts newest first', () {
    final events = MemberTimelineMapper.fromProfile(
      _profile(
        ministries: [
          AssignmentRecord(
            kind: 'Ministry',
            name: 'School A',
            role: 'Teacher',
            fromDate: DateTime(2019),
            toDate: DateTime(2022),
          ),
        ],
        offices: [
          OfficeAppointment(
            office: 'Teacher',
            context: 'School A',
            fromDate: DateTime(2020),
            toDate: DateTime(2022),
          ),
        ],
        leave: [
          LeaveRecord(
            type: 'Home Leave',
            fromDate: DateTime(2024, 5, 12),
            toDate: DateTime(2024, 5, 30),
          ),
        ],
      ),
    );

    expect(events, hasLength(3));
    expect(events.first.title, 'Home Leave');
    expect(events[1].startDate, DateTime(2020));
    expect(events[2].startDate, DateTime(2019));
  });

  test('empty structured history produces an empty timeline', () {
    expect(MemberTimelineMapper.fromProfile(_profile()), isEmpty);
  });
}

ReligiousProfile _profile({
  List<VocationEvent> vocation = const [],
  List<AssignmentRecord> communities = const [],
  List<AssignmentRecord> ministries = const [],
  List<OfficeAppointment> offices = const [],
  List<LeaveRecord> leave = const [],
}) => ReligiousProfile(
  memberId: 'member-1',
  religiousId: 'REL-0001',
  displayName: 'Timeline Member',
  memberStatus: 'Active',
  sections: ReligiousProfileSections(
    vocationEvents: vocation,
    communityAssignments: communities,
    ministryAssignments: ministries,
    offices: offices,
    leaveHistory: leave,
  ),
);
