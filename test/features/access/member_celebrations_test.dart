import 'package:communio/app/shell/models/app_navigation.dart';
import 'package:communio/features/access/data/member_celebrations_repository.dart';
import 'package:communio/features/access/models/member_celebration.dart';
import 'package:communio/features/access/screens/member_home_screen.dart';
import 'package:communio/features/religious_directory/data/member_directory_repository.dart';
import 'package:communio/features/religious_directory/models/member_directory_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('safe rows include only today and omit unsupported types', () {
    final items = MemberCelebrationMapper.fromRows(
      [
        _row('birthday', '2026-08-22', name: 'A Birthday'),
        _row('feast_day', '2026-08-22', name: 'B Feast'),
        _row('first_profession', '2026-08-22', year: 2001),
        _row('perpetual_profession', '2026-08-22', year: 2008),
        _row('ordination', '2026-08-22', name: 'C Ordination', year: 2012),
        _row('birthday', '2026-08-21', name: 'Yesterday'),
        _row('birthday', '2026-08-23', name: 'Tomorrow'),
        _row('private_travel', '2026-08-22', name: 'Private itinerary'),
      ],
      today: DateTime(2026, 8, 22),
      horizonDays: 0,
    );

    expect(items, hasLength(5));
    expect(
      items.map((item) => item.type),
      containsAll(MemberCelebrationType.values),
    );
    expect(items.any((item) => item.displayName == 'Yesterday'), false);
    expect(items.any((item) => item.displayName == 'Tomorrow'), false);
    expect(items.any((item) => item.displayName == 'Private itinerary'), false);
  });

  test('birthday projection contains month/day but no source year', () {
    final item = MemberCelebrationMapper.fromRows(
      [_row('birthday', '2026-08-25')],
      today: DateTime(2026, 8, 25),
      horizonDays: 0,
    ).single;

    expect(item.date.month, 8);
    expect(item.date.day, 25);
    expect(item.sourceYear, isNull);
  });

  testWidgets('MEMBER Home shows celebrations and opens safe member profile', (
    tester,
  ) async {
    String? selectedMember;
    String? selectedCommunity;
    String? selectedMinistry;
    AppDestination? topLevelDestination;
    await tester.pumpWidget(
      MaterialApp(
        home: MemberHomeScreen(
          displayName: 'Roy',
          memberId: 'roy',
          directoryRepository: const _DirectoryRepository(),
          celebrationsRepository: const _CelebrationsRepository(),
          onNavigate: (destination) => topLevelDestination = destination,
          onMyProfile: () {},
          onCelebrationMember: (id) => selectedMember = id,
          onCommunity: (id) => selectedCommunity = id,
          onMinistry: (id) => selectedMinistry = id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CELEBRATIONS'), findsOneWidget);
    expect(find.text('Joseph Vadakkel'), findsOneWidget);
    expect(find.textContaining('Birthday · Today'), findsOneWidget);
    expect(find.textContaining('birth year'), findsNothing);
    expect(find.textContaining('Travel'), findsNothing);
    expect(find.text('View All'), findsNothing);
    expect(
      tester.getTopLeft(find.text('CELEBRATIONS')).dy,
      lessThan(tester.getTopLeft(find.text('My Community')).dy),
    );

    await tester.tap(find.text('Joseph Vadakkel'));
    expect(selectedMember, 'canonical-member-uuid');

    await tester.tap(find.text('My Community'));
    expect(selectedCommunity, 'community-uuid');
    expect(topLevelDestination, isNull);

    await tester.tap(find.text('My Ministry'));
    expect(selectedMinistry, 'ministry-uuid');
    expect(topLevelDestination, isNull);
  });

  testWidgets('MEMBER Home shows calm celebrations empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MemberHomeScreen(
          displayName: 'Roy',
          memberId: 'roy',
          directoryRepository: const _DirectoryRepository(),
          onNavigate: (AppDestination _) {},
          onMyProfile: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No celebrations today.'), findsOneWidget);
    expect(find.text('View All'), findsNothing);
  });
}

Map<String, dynamic> _row(
  String type,
  String date, {
  String name = 'Member Name',
  int? year,
}) => {
  'member_id': 'member-$name',
  'religious_id': 'REL-TEST',
  'display_name': name,
  'celebration_type': type,
  'celebration_month': DateTime.parse(date).month,
  'celebration_day': DateTime.parse(date).day,
  'source_year': year,
  'next_celebration_date': date,
};

class _CelebrationsRepository implements MemberCelebrationsRepository {
  const _CelebrationsRepository();

  @override
  Future<List<MemberCelebration>> fetchToday({DateTime? today}) async => [
    MemberCelebration(
      memberId: 'canonical-member-uuid',
      religiousId: 'REL-0001',
      displayName: 'Joseph Vadakkel',
      type: MemberCelebrationType.birthday,
      date: DateTime.now(),
    ),
  ];
}

class _DirectoryRepository implements MemberDirectoryRepository {
  const _DirectoryRepository();

  @override
  Future<List<MemberDirectoryEntry>> fetchMembers() async => const [
    MemberDirectoryEntry(
      id: 'roy',
      religiousId: 'REL-0019',
      displayName: 'Roy Noronha',
      memberStatus: 'Active',
      community: 'Sacred Heart Community',
      communityId: 'community-uuid',
      ministry: 'St. Thomas Diocesan School',
      ministryId: 'ministry-uuid',
      ministryRole: 'Teacher',
    ),
  ];
}
