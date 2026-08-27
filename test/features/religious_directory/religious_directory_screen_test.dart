import 'dart:async';

import 'package:communio/features/religious_directory/data/member_directory_repository.dart';
import 'package:communio/features/religious_directory/models/member_directory_entry.dart';
import 'package:communio/features/religious_directory/screens/religious_directory_screen.dart';
import 'package:communio/features/religious_directory/state/member_directory_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _members = [
  MemberDirectoryEntry(
    id: '1',
    religiousId: 'REL-0001',
    displayName: 'Joseph Mathew',
    title: 'Fr.',
    memberStatus: 'Active',
    canonicalStatus: 'Priest',
    community: 'Provincial House',
    communityRole: 'Community Superior',
    nativeState: 'Kerala',
    mobile: '+91 70000 00001',
    whatsApp: '+91 70000 00001',
    officialEmail: 'rel0001@demo.communio.example',
  ),
  MemberDirectoryEntry(
    id: '2',
    religiousId: 'REL-0024',
    displayName: 'Antony Paul',
    title: 'Fr.',
    memberStatus: 'Deceased',
    canonicalStatus: 'Priest',
    community: 'St. Joseph Community',
    communityRole: 'Member',
    nativeState: 'Tamil Nadu',
  ),
  MemberDirectoryEntry(
    id: '3',
    religiousId: 'REL-0042',
    displayName: 'Justin Mukkath',
    title: 'Bro.',
    memberStatus: 'Higher Studies',
    community: 'St. Thomas Community',
    communityRole: 'Member',
    ministry: 'St. Xavier College of Education',
    ministryRole: 'Student',
  ),
];

void main() {
  testWidgets('renders desktop directory and deceased visual state', (
    tester,
  ) async {
    await _pump(tester, const Size(1200, 900), _Repository.value(_members));
    expect(find.text('Members of the Province'), findsOneWidget);
    expect(find.text('3 members'), findsOneWidget);
    expect(find.text('MINISTRY / ASSIGNMENT'), findsOneWidget);
    expect(find.text('COMMUNITY ROLE'), findsOneWidget);
    expect(find.text('Fr. Joseph Mathew'), findsOneWidget);
    expect(find.byTooltip('Call Fr. Joseph Mathew'), findsOneWidget);
    expect(find.byTooltip('WhatsApp Fr. Joseph Mathew'), findsOneWidget);
    expect(find.byTooltip('Email Fr. Joseph Mathew'), findsOneWidget);
    expect(find.text('REL-0001'), findsNothing);
    expect(find.byKey(const Key('status-deceased')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders mobile cards without table headings', (tester) async {
    await _pump(tester, const Size(390, 844), _Repository.value(_members));
    expect(find.byKey(const Key('member-card-1')), findsOneWidget);
    expect(find.byTooltip('Call Fr. Joseph Mathew'), findsOneWidget);
    expect(find.byTooltip('WhatsApp Fr. Joseph Mathew'), findsOneWidget);
    expect(find.byTooltip('Email Fr. Joseph Mathew'), findsOneWidget);
    expect(find.text('REL-0001'), findsNothing);
    expect(find.text('Provincial House'), findsOneWidget);
    expect(find.text('Community Superior'), findsOneWidget);
    expect(find.text('St. Joseph Community'), findsOneWidget);
    expect(find.text('Member'), findsNWidgets(2));
    expect(
      find.text('St. Xavier College of Education · Student'),
      findsOneWidget,
    );
    expect(find.text('MINISTRY / ASSIGNMENT'), findsNothing);
    expect(find.text('Community not assigned'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows loading state then members', (tester) async {
    final completer = Completer<List<MemberDirectoryEntry>>();
    await _pump(
      tester,
      const Size(1000, 800),
      _Repository(completer.future),
      settle: false,
    );
    expect(find.byKey(const Key('directory-loading')), findsOneWidget);
    completer.complete(_members);
    await tester.pumpAndSettle();
    expect(find.text('Fr. Joseph Mathew'), findsOneWidget);
  });

  testWidgets('shows retryable friendly error', (tester) async {
    await _pump(tester, const Size(1000, 800), _ErrorRepository());
    expect(find.text('Unable to load the directory'), findsOneWidget);
    expect(
      find.text('The directory is temporarily unavailable. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
  });

  testWidgets('searches directory fields case-insensitively', (tester) async {
    await _pump(tester, const Size(1000, 800), _Repository.value(_members));
    await tester.enterText(find.byKey(const Key('directory-search')), 'tamil');
    await tester.pump();
    expect(find.text('1 of 3 members'), findsOneWidget);
    expect(find.text('Fr. Antony Paul'), findsOneWidget);
    expect(find.text('Fr. Joseph Mathew'), findsNothing);
  });

  test('controller filters by status and community', () async {
    final controller = MemberDirectoryController(_Repository.value(_members));
    await controller.load();
    controller.setFilters(
      const MemberDirectoryFilters(
        memberStatus: 'Active',
        community: 'Provincial House',
      ),
    );
    expect(controller.visibleMembers.map((member) => member.id), ['1']);
    controller.clearFilters();
    expect(controller.visibleMembers.length, 3);
    controller.dispose();
  });

  testWidgets('searches Religious ID without exposing it in results', (
    tester,
  ) async {
    await _pump(tester, const Size(1000, 800), _Repository.value(_members));
    await tester.enterText(
      find.byKey(const Key('directory-search')),
      'REL-0001',
    );
    await tester.pump();
    expect(find.byKey(const Key('member-row-1')), findsOneWidget);
  });

  test('formation members use their specific canonical stage', () {
    const novice = MemberDirectoryEntry(
      id: 'novice',
      religiousId: 'REL-0059',
      displayName: 'Formation Member',
      memberStatus: 'Formation',
      canonicalStatus: 'Novice',
    );
    const deacon = MemberDirectoryEntry(
      id: 'deacon',
      religiousId: 'REL-0048',
      displayName: 'Deacon Member',
      title: 'Dcn.',
      memberStatus: 'Formation',
      canonicalStatus: 'Perpetual Professed',
    );
    expect(novice.directoryStatus, 'Novice');
    expect(deacon.directoryStatus, 'Deacon');
  });

  test('controller preserves repository failure classification', () async {
    final controller = MemberDirectoryController(
      _ClassifiedErrorRepository(MemberDirectoryFailureKind.permission),
    );
    await controller.load();
    expect(controller.status, MemberDirectoryStatus.error);
    expect(controller.failureKind, MemberDirectoryFailureKind.permission);
    controller.dispose();
  });

  testWidgets('member row tap hands selected member to navigation', (
    tester,
  ) async {
    MemberDirectoryEntry? selected;
    await _pump(
      tester,
      const Size(1200, 900),
      _Repository.value(_members),
      onSelected: (member) => selected = member,
    );
    await tester.tap(find.byKey(const Key('member-row-1')));
    expect(selected?.religiousId, 'REL-0001');
  });

  testWidgets('mobile directory scrolls from first to final member', (
    tester,
  ) async {
    final members = List.generate(
      112,
      (index) => MemberDirectoryEntry(
        id: '${index + 1}',
        religiousId: 'REL-${(index + 1).toString().padLeft(4, '0')}',
        displayName: 'Member ${(index + 1).toString().padLeft(2, '0')}',
        memberStatus: 'Active',
      ),
    );
    await _pump(tester, const Size(390, 844), _Repository.value(members));

    expect(find.byKey(const Key('member-card-1')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('member-card-112')),
      700,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('member-card-112')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  MemberDirectoryRepository repository, {
  bool settle = true,
  ValueChanged<MemberDirectoryEntry>? onSelected,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReligiousDirectoryScreen(
          repository: repository,
          onMemberSelected: onSelected,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

class _Repository implements MemberDirectoryRepository {
  _Repository(this.result);
  _Repository.value(List<MemberDirectoryEntry> members)
    : result = Future.value(members);
  final Future<List<MemberDirectoryEntry>> result;
  @override
  Future<List<MemberDirectoryEntry>> fetchMembers() => result;
}

class _ErrorRepository implements MemberDirectoryRepository {
  @override
  Future<List<MemberDirectoryEntry>> fetchMembers() async =>
      throw Exception('private backend details');
}

class _ClassifiedErrorRepository implements MemberDirectoryRepository {
  const _ClassifiedErrorRepository(this.kind);

  final MemberDirectoryFailureKind kind;

  @override
  Future<List<MemberDirectoryEntry>> fetchMembers() async =>
      throw MemberDirectoryException(kind);
}
