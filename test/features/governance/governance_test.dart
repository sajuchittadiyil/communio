import 'package:communio/core/theme/theme.dart';
import 'package:communio/features/governance/data/governance_repository.dart';
import 'package:communio/features/governance/data/supabase_governance_repository.dart';
import 'package:communio/features/governance/models/governance_models.dart';
import 'package:communio/features/governance/screens/governance_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final asOf = DateTime(2026, 8, 28);
  final education = GovernanceBody(
    id: 'body-education',
    code: 'EDUCATION_COMMISSION',
    name: 'Education Commission',
    bodyTypeCode: 'COMMISSION',
    statusCode: 'ACTIVE',
    displayOrder: 20,
    purpose: 'Coordinates the Province educational apostolate.',
    memberships: [
      GovernanceMembership(
        id: 'current-chair',
        memberId: 'member-chair',
        religiousId: 'REL-0003',
        displayName: 'Joseph Antony',
        roleCode: 'CHAIR',
        startDate: DateTime(2024, 7),
        endDate: DateTime(2027, 6, 30),
        statusCode: 'ACTIVE',
      ),
      GovernanceMembership(
        id: 'current-member',
        memberId: 'member-current',
        displayName: 'David Pradhan',
        roleCode: 'MEMBER',
        startDate: DateTime(2024, 7),
        endDate: DateTime(2027, 6, 30),
        statusCode: 'ACTIVE',
      ),
      GovernanceMembership(
        id: 'former-chair',
        memberId: 'member-former',
        displayName: 'Roy Noronha',
        roleCode: 'CHAIR',
        startDate: DateTime(2021, 7),
        endDate: DateTime(2024, 6, 30),
        statusCode: 'ACTIVE',
      ),
    ],
  );

  test('maps, orders, and resolves effective-dated governance terms', () async {
    final repository = SupabaseGovernanceRepository.forTesting(
      () async => [
        {
          'governance_body_id': 'second',
          'code': 'FINANCE_COMMISSION',
          'name': 'Finance Commission',
          'body_type_code': 'COMMISSION',
          'status_code': 'ACTIVE',
          'display_order': 30,
          'memberships': <Object?>[],
        },
        {
          'governance_body_id': 'first',
          'code': education.code,
          'name': education.name,
          'body_type_code': education.bodyTypeCode,
          'status_code': education.statusCode,
          'display_order': education.displayOrder,
          'memberships': [
            {
              'membership_id': 'chair',
              'member_id': 'member-chair',
              'display_name': 'Joseph Antony',
              'role_code': 'CHAIR',
              'start_date': '2024-07-01',
              'end_date': '2027-06-30',
              'status_code': 'ACTIVE',
            },
          ],
        },
      ],
    );

    final bodies = await repository.fetchBodies();
    expect(bodies.map((body) => body.name), [
      'Education Commission',
      'Finance Commission',
    ]);
    expect(bodies.first.currentMemberships(asOf), hasLength(1));
    expect(bodies.first.currentLeader(asOf)?.displayName, 'Joseph Antony');
  });

  test(
    'repository returns empty results and normalizes Supabase errors',
    () async {
      final empty = SupabaseGovernanceRepository.forTesting(() async => []);
      expect(await empty.fetchBodies(), isEmpty);

      final failing = SupabaseGovernanceRepository.forTesting(
        () async => throw StateError('database detail'),
      );
      expect(failing.fetchBodies(), throwsA(isA<GovernanceDataException>()));
    },
  );

  test('current ordering puts leadership first and history newest first', () {
    expect(education.currentMemberships(asOf).map((item) => item.roleCode), [
      'CHAIR',
      'MEMBER',
    ]);
    expect(
      education.historicalMemberships(asOf).single.displayName,
      'Roy Noronha',
    );
    expect(
      formatGovernanceTerm(education.currentMemberships(asOf).first),
      'Jul 1, 2024 – Jun 30, 2027',
    );
  });

  for (final testCase in <(String, Size, double)>[
    ('mobile', const Size(390, 844), 1),
    ('tablet', const Size(900, 700), 1),
    ('desktop', const Size(1440, 900), 1),
    ('accessible mobile', const Size(390, 844), 1.5),
  ]) {
    testWidgets('directory renders on ${testCase.$1}', (tester) async {
      await _surface(tester, testCase.$2);
      await tester.pumpWidget(
        _app(
          GovernanceDirectoryScreen(
            repository: _FakeGovernanceRepository([education]),
            onMember: (_) {},
          ),
          textScale: testCase.$3,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Governance Bodies'), findsOneWidget);
      expect(find.text('Education Commission'), findsOneWidget);
      expect(find.text('Chair: Joseph Antony'), findsOneWidget);
      expect(find.text('2 current members'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('profile shows roles, terms, history, and member navigation', (
    tester,
  ) async {
    await _surface(tester, const Size(1440, 900));
    GovernanceMembership? selected;
    await tester.pumpWidget(
      _app(
        GovernanceDirectoryScreen(
          repository: _FakeGovernanceRepository([education]),
          onMember: (member) => selected = member,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('governance-body-EDUCATION_COMMISSION')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current Leadership'), findsOneWidget);
    expect(find.text('Current Members'), findsOneWidget);
    expect(find.text('Membership History'), findsOneWidget);
    expect(find.textContaining('Jul 1, 2024 – Jun 30, 2027'), findsWidgets);
    expect(find.text('Roy Noronha'), findsOneWidget);

    await tester.tap(find.text('David Pradhan'));
    await tester.pump();
    expect(selected?.memberId, 'member-current');
    expect(tester.takeException(), isNull);
  });

  testWidgets('directory and profile render precise empty states', (
    tester,
  ) async {
    await _surface(tester, const Size(390, 844));
    await tester.pumpWidget(
      _app(
        const GovernanceDirectoryScreen(
          repository: _FakeGovernanceRepository([]),
          onMember: _ignoreMember,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No governance bodies recorded'), findsOneWidget);

    const emptyBody = GovernanceBody(
      id: 'empty',
      code: 'EMPTY_BODY',
      name: 'Advisory Body',
      bodyTypeCode: 'COMMITTEE',
      statusCode: 'ACTIVE',
      displayOrder: 1,
      memberships: [],
    );
    await tester.pumpWidget(
      _app(
        const GovernanceBodyProfileScreen(
          body: emptyBody,
          onMember: _ignoreMember,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No chair is currently recorded.'), findsOneWidget);
    expect(
      find.text('No current members are recorded for this governance body.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'No historical membership is recorded for this governance body.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(body: child),
  ),
);

Future<void> _surface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void _ignoreMember(GovernanceMembership _) {}

class _FakeGovernanceRepository implements GovernanceRepository {
  const _FakeGovernanceRepository(this.bodies);
  final List<GovernanceBody> bodies;

  @override
  Future<List<GovernanceBody>> fetchBodies() async => bodies;
}
