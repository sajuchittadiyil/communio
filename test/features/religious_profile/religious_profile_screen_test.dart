import 'dart:async';

import 'package:communio/features/religious_profile/data/religious_profile_repository.dart';
import 'package:communio/features/religious_profile/models/religious_profile.dart';
import 'package:communio/features/religious_profile/screens/religious_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _profile = ReligiousProfile(
  memberId: 'member-uuid-1',
  religiousId: 'REL-0001',
  displayName: 'Joseph Vadakkel',
  title: 'Bro.',
  memberStatus: 'Active',
  canonicalStatus: 'Perpetually Professed',
  dateOfBirth: DateTime(1980, 4, 12),
  nationality: 'Indian',
  bloodGroup: 'O+',
  patronSaint: 'St. Joseph',
  community: 'St. Anne Community',
  communityRole: 'Community Accountant',
  ministry: 'St. Joseph School',
  ministryRole: 'Administrator',
  ministryType: 'Education',
  communityFromDate: DateTime(2024, 6, 1),
  ministryFromDate: DateTime(2024, 6, 1),
  origin: const MemberOriginDetails(
    nativePlace: 'Kottayam',
    homeParish: "St. Mary's Parish, Kottayam",
    diocese: 'Archdiocese of Changanassery',
    district: 'Kottayam',
    state: 'Kerala',
    country: 'India',
  ),
  sections: ReligiousProfileSections(
    vocationEvents: [
      VocationEvent(label: 'Joining', date: DateTime(2000, 6, 1)),
      VocationEvent(label: 'First Profession', date: DateTime(2005, 5, 31)),
    ],
    qualifications: const [
      QualificationRecord(
        qualification: 'M.Ed.',
        category: 'Postgraduate',
        specialization: 'Educational Leadership',
        institution: 'St. Xavier College',
        universityBoard: 'St. Xavier University',
        year: 2018,
        country: 'India',
      ),
      QualificationRecord(qualification: 'Class 10'),
    ],
    languages: const [
      MemberLanguage(
        name: 'Malayalam',
        proficiencyLevelCode: 'NATIVE',
        canSpeak: true,
        canRead: true,
        canWrite: true,
        isPrimary: true,
        isNative: true,
      ),
      MemberLanguage(name: 'Hindi', canSpeak: true, canRead: true),
    ],
    communityAssignments: [
      AssignmentRecord(
        kind: 'Community',
        name: 'St. Anne Community',
        role: 'Community Accountant',
        fromDate: DateTime(2024, 6, 1),
      ),
    ],
    ministryAssignments: [
      AssignmentRecord(
        kind: 'Ministry',
        name: 'St. Joseph School',
        role: 'Administrator',
        fromDate: DateTime(2024, 6, 1),
      ),
    ],
    offices: [
      OfficeAppointment(
        office: 'Provincial Councillor',
        context: 'Indian Province',
        contextKind: OfficeContextKind.province,
        fromDate: DateTime(2022, 1, 1),
      ),
      OfficeAppointment(
        office: 'Principal',
        context: 'St. Joseph School',
        contextKind: OfficeContextKind.ministry,
        fromDate: DateTime(2018, 1, 1),
        toDate: DateTime(2021, 12, 31),
      ),
      OfficeAppointment(
        office: 'Community Superior',
        context: 'St. Anne Community',
        contextKind: OfficeContextKind.community,
        fromDate: DateTime(2014, 1, 1),
        toDate: DateTime(2017, 12, 31),
      ),
      OfficeAppointment(office: 'Delegate', fromDate: DateTime(2012, 1, 1)),
    ],
    leaveHistory: [
      LeaveRecord(
        type: 'Study Leave',
        fromDate: DateTime(2017, 7, 1),
        toDate: DateTime(2019, 5, 31),
        location: 'Rome, Italy',
        reason: 'Higher Studies',
      ),
    ],
    contacts: const [
      LabeledValue('Mobile', '+91 90000 00000'),
      LabeledValue('Official Email', 'joseph@example.org'),
    ],
    family: const [
      FamilyContact(
        name: 'Vimal Mishra',
        relationship: 'Brother',
        phone: '+91 91111 11111',
        email: 'vimal@example.org',
        isNextOfKin: true,
      ),
      FamilyContact(
        name: 'Roshan Mishra',
        relationship: 'Father',
        phone: '+91 92222 22222',
        isEmergency: true,
      ),
      FamilyContact(
        name: 'Anita Mishra',
        relationship: 'Sister',
        email: 'anita@example.org',
      ),
    ],
    documents: const [
      DocumentRecord(
        type: 'Passport',
        number: 'P1234567',
        verificationStatus: 'Verified',
      ),
    ],
  ),
);

void main() {
  testWidgets('renders canonical Religious ID without exposing UUID or Edit', (
    tester,
  ) async {
    await _pump(tester, const Size(1200, 900), _ValueRepository(_profile));

    expect(find.text('Bro. Joseph Vadakkel'), findsOneWidget);
    expect(find.text('St. Anne Community'), findsWidgets);
    expect(find.text('Community Accountant'), findsWidgets);
    expect(find.text('St. Joseph School'), findsWidgets);
    expect(find.text('Administrator'), findsWidgets);
    expect(find.text('M.Ed.'), findsOneWidget);
    expect(find.text('Religious ID'), findsOneWidget);
    expect(find.text('REL-0001'), findsOneWidget);
    expect(find.text('Origin & Home Details'), findsOneWidget);
    expect(find.text('Native Place'), findsOneWidget);
    expect(find.text('Kottayam'), findsWidgets);
    expect(find.text("St. Mary's Parish, Kottayam"), findsOneWidget);
    expect(find.text('Archdiocese of Changanassery'), findsOneWidget);
    expect(find.text('Kerala'), findsOneWidget);
    expect(find.text('Joining'), findsWidgets);
    expect(find.text('1 June 2000'), findsOneWidget);
    expect(find.text('1 June 2024 – Present'), findsWidgets);
    expect(find.text('Provincial Councillor'), findsWidgets);
    expect(find.text('member-uuid-1'), findsNothing);
    expect(find.byKey(const Key('profile-edit')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows rich and sparse qualification metadata without empties', (
    tester,
  ) async {
    await _pump(tester, const Size(1200, 1800), _ValueRepository(_profile));

    expect(find.text('M.Ed.'), findsOneWidget);
    expect(find.textContaining('Category: Postgraduate'), findsOneWidget);
    expect(
      find.textContaining('Specialization: Educational Leadership'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Institution: St. Xavier College'),
      findsOneWidget,
    );
    expect(
      find.textContaining('University / Board: St. Xavier University'),
      findsOneWidget,
    );
    expect(find.textContaining('Year: 2018'), findsOneWidget);
    expect(find.textContaining('Country: India'), findsOneWidget);
    expect(find.text('Class 10'), findsOneWidget);
    expect(find.textContaining('University / Board: null'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders structured language proficiency and capabilities', (
    tester,
  ) async {
    await _pump(tester, const Size(1200, 1800), _ValueRepository(_profile));

    expect(find.byKey(const Key('profile-languages')), findsOneWidget);
    expect(find.text('Languages'), findsOneWidget);
    expect(find.text('Malayalam'), findsOneWidget);
    expect(find.text('Native · Speak · Read · Write'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('Speak · Read'), findsOneWidget);
    expect(find.textContaining('true'), findsNothing);
  });

  testWidgets('language section has a precise empty state', (tester) async {
    const sparse = ReligiousProfile(
      memberId: 'sparse-language-id',
      displayName: 'Sparse Member',
      memberStatus: 'Active',
      sections: ReligiousProfileSections(),
    );
    await _pump(tester, const Size(390, 1200), const _ValueRepository(sparse));
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile-languages')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No language information recorded'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows historical leave and all structured office contexts', (
    tester,
  ) async {
    await _pump(tester, const Size(1200, 2200), _ValueRepository(_profile));

    expect(find.text('Leave & Sabbatical History'), findsOneWidget);
    expect(find.text('Study Leave'), findsWidgets);
    expect(find.textContaining('Rome, Italy'), findsWidgets);
    expect(find.textContaining('Higher Studies'), findsWidgets);
    expect(find.text('Principal'), findsWidgets);
    expect(find.text('St. Joseph School'), findsWidgets);
    expect(find.text('Community Superior'), findsWidgets);
    expect(find.text('St. Anne Community'), findsWidgets);
    expect(find.text('Provincial Councillor'), findsWidgets);
    expect(find.textContaining('Indian Province'), findsWidgets);
    expect(find.text('Delegate'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows current leave status without inventing dated history', (
    tester,
  ) async {
    const currentLeave = ReligiousProfile(
      memberId: 'leave-id',
      religiousId: 'REL-0045',
      displayName: 'Current Leave Member',
      memberStatus: 'On Leave',
      sections: ReligiousProfileSections(),
    );
    await _pump(
      tester,
      const Size(390, 1800),
      const _ValueRepository(currentLeave),
    );

    expect(find.text('Currently on Leave'), findsOneWidget);
    expect(find.text('No dated leave record is available.'), findsOneWidget);
    expect(find.text('Sabbatical'), findsNothing);
  });

  testWidgets('timeline respects year-only vocation precision', (tester) async {
    final yearOnly = ReligiousProfile(
      memberId: 'year-only-id',
      displayName: 'Year Precision Member',
      memberStatus: 'Active',
      sections: ReligiousProfileSections(
        vocationEvents: [
          VocationEvent(
            label: 'First Profession',
            date: DateTime(1990),
            datePrecision: TimelineDatePrecision.year,
          ),
        ],
      ),
    );
    await _pump(tester, const Size(1200, 900), _ValueRepository(yearOnly));

    expect(find.text('1990'), findsOneWidget);
    expect(find.textContaining('1 January 1990'), findsNothing);
  });

  testWidgets('timeline labels explicit formal transfers distinctly', (
    tester,
  ) async {
    final transferProfile = ReligiousProfile(
      memberId: 'transfer-member',
      displayName: 'Transfer Member',
      memberStatus: 'Active',
      sections: ReligiousProfileSections(
        transfers: [
          MemberTransferRecord(
            id: 'transfer-1',
            fromCommunityName: 'St. Antony Community',
            toCommunityName: 'St. Anne Community',
            effectiveDate: DateTime(2026, 8, 8),
          ),
        ],
      ),
    );
    await _pump(
      tester,
      const Size(390, 1000),
      _ValueRepository(transferProfile),
    );
    await tester.scrollUntilVisible(
      find.text('St. Antony Community → St. Anne Community'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Transfer'), findsWidgets);
    expect(
      find.text('St. Antony Community → St. Anne Community'),
      findsOneWidget,
    );
    expect(find.text('8 August 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a vertically scrollable mobile profile', (tester) async {
    await _pump(tester, const Size(390, 844), _ValueRepository(_profile));
    expect(find.byKey(const Key('religious-profile-scroll')), findsOneWidget);
    expect(find.byKey(const Key('profile-header')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile-documents')),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Passport'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses accessible mobile profile typography and touch targets', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 5000), _ValueRepository(_profile));

    expect(
      tester.widget<Text>(find.text('Bro. Joseph Vadakkel')).style?.fontSize,
      25,
    );
    expect(
      tester.widget<Text>(find.text('Contact Information')).style?.fontSize,
      21,
    );
    expect(
      tester.widget<Text>(find.text('Ecclesiastical Title')).style?.fontSize,
      15.5,
    );
    expect(
      tester
          .widgetList<Text>(find.text('St. Anne Community'))
          .any((text) => text.style?.fontSize == 16.5),
      isTrue,
    );
    expect(
      tester.getSize(find.byTooltip('Call Joseph Vadakkel')),
      const Size(48, 48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports enlarged system text without mobile overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      const Size(390, 10000),
      _ValueRepository(_profile),
      textScaler: const TextScaler.linear(1.6),
    );

    expect(find.text('Bro. Joseph Vadakkel'), findsOneWidget);
    expect(find.text('Contact Information'), findsOneWidget);
    expect(find.text('Origin & Home Details'), findsOneWidget);
    expect(find.text('Family Details'), findsOneWidget);
    expect(find.text('Life & Ministry Timeline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders member and prioritized family contact actions', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 5000), _ValueRepository(_profile));

    expect(find.byTooltip('Call Joseph Vadakkel'), findsOneWidget);
    expect(find.byTooltip('WhatsApp Joseph Vadakkel'), findsOneWidget);
    expect(find.byTooltip('Email Joseph Vadakkel'), findsOneWidget);

    expect(find.text('FAMILY'), findsOneWidget);
    expect(find.text('DOCUMENTS'), findsOneWidget);
    expect(find.text('Emergency Contact'), findsOneWidget);
    expect(find.text('Next of Kin'), findsOneWidget);
    expect(find.byTooltip('Call Roshan Mishra'), findsOneWidget);
    expect(find.byTooltip('WhatsApp Roshan Mishra'), findsOneWidget);
    expect(find.byTooltip('Email Roshan Mishra'), findsNothing);
    expect(find.byTooltip('Call Vimal Mishra'), findsOneWidget);
    expect(find.byTooltip('WhatsApp Vimal Mishra'), findsOneWidget);
    expect(find.byTooltip('Email Vimal Mishra'), findsOneWidget);
    final phoneCenter = tester.getCenter(find.text('+91 91111 11111'));
    final callCenter = tester.getCenter(find.byTooltip('Call Vimal Mishra'));
    final whatsAppCenter = tester.getCenter(
      find.byTooltip('WhatsApp Vimal Mishra'),
    );
    expect((phoneCenter.dy - callCenter.dy).abs(), lessThan(2));
    expect((phoneCenter.dy - whatsAppCenter.dy).abs(), lessThan(2));
    expect(find.byTooltip('Call Anita Mishra'), findsNothing);
    expect(find.byTooltip('WhatsApp Anita Mishra'), findsNothing);
    expect(find.byTooltip('Email Anita Mishra'), findsOneWidget);
    expect(find.text('Passport'), findsOneWidget);

    final text = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .toList();
    expect(
      text.indexOf('Roshan Mishra'),
      lessThan(text.indexOf('Vimal Mishra')),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'presents deceased parents respectfully without contact actions',
    (tester) async {
      final familyProfile = ReligiousProfile(
        memberId: 'family-status-id',
        displayName: 'Family Status Profile',
        memberStatus: 'Active',
        sections: ReligiousProfileSections(
          family: [
            FamilyContact(
              name: 'Joseph Mathew',
              relationship: 'Father',
              lifeStatus: FamilyLifeStatus.deceased,
              dateOfDeath: DateTime(2018, 3, 12),
              phone: '+91 90000 00001',
              whatsApp: '+91 90000 00001',
              email: 'joseph@example.org',
            ),
            const FamilyContact(
              name: 'Mary Mathew',
              relationship: 'Mother',
              lifeStatus: FamilyLifeStatus.deceased,
            ),
            const FamilyContact(
              name: 'Anna Mathew',
              relationship: 'Sister',
              lifeStatus: FamilyLifeStatus.living,
              phone: '+91 90000 00002',
              email: 'anna@example.org',
            ),
            const FamilyContact(name: 'Thomas Mathew', relationship: 'Brother'),
          ],
        ),
      );

      await _pump(
        tester,
        const Size(390, 5000),
        _ValueRepository(familyProfile),
      );

      expect(find.text('Father'), findsOneWidget);
      expect(find.text('Late Joseph Mathew'), findsOneWidget);
      expect(find.text('Died: 12 Mar 2018'), findsOneWidget);
      expect(find.text('Late Mary Mathew'), findsOneWidget);
      expect(find.text('Thomas Mathew'), findsOneWidget);
      expect(find.textContaining('Unknown'), findsNothing);
      expect(find.byTooltip('Call Joseph Mathew'), findsNothing);
      expect(find.byTooltip('WhatsApp Joseph Mathew'), findsNothing);
      expect(find.byTooltip('Email Joseph Mathew'), findsNothing);
      expect(find.byTooltip('Call Anna Mathew'), findsOneWidget);
      expect(find.byTooltip('WhatsApp Anna Mathew'), findsOneWidget);
      expect(find.byTooltip('Email Anna Mathew'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('orders mobile profile sections with assignments last', (
    tester,
  ) async {
    await _pump(tester, const Size(390, 5000), _ValueRepository(_profile));
    final textOrder = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(
      textOrder.indexOf('Qualifications'),
      lessThan(textOrder.indexOf('Responsibilities (Current)')),
    );
    expect(
      textOrder.indexOf('Responsibilities (Current)'),
      lessThan(textOrder.indexOf('Vocation & Formation Milestones')),
    );
    expect(
      textOrder.indexOf('Vocation & Formation Milestones'),
      lessThan(textOrder.indexOf('Life & Ministry Timeline')),
    );
    expect(
      textOrder.indexOf('Life & Ministry Timeline'),
      greaterThan(textOrder.indexOf('Documents')),
    );
  });

  testWidgets('Community Superior profile omits ministry entirely', (
    tester,
  ) async {
    final superior = ReligiousProfile(
      memberId: 'superior-id',
      displayName: "Michael D'Souza",
      title: 'Fr.',
      memberStatus: 'Active',
      community: 'Provincial House',
      communityRole: 'Community Superior',
      sections: const ReligiousProfileSections(),
    );
    await _pump(tester, const Size(1200, 900), _ValueRepository(superior));
    expect(find.text('Community Superior'), findsWidgets);
    expect(find.text('Current ministry / assignment'), findsNothing);
    expect(find.text('Ministry role'), findsNothing);
  });

  testWidgets('shows friendly empty section messages', (tester) async {
    final empty = ReligiousProfile(
      memberId: 'empty-id',
      displayName: 'Empty Profile',
      memberStatus: 'Retired',
      sections: const ReligiousProfileSections(),
    );
    await _pump(tester, const Size(1200, 1400), _ValueRepository(empty));
    expect(find.text('No qualification records available'), findsOneWidget);
    expect(find.text('No current responsibilities recorded'), findsOneWidget);
    expect(
      find.text('No dated life or ministry events available'),
      findsOneWidget,
    );
    expect(find.text('No contact information available'), findsOneWidget);
    expect(find.text('NULL'), findsNothing);
  });

  testWidgets('shows loading and retryable error states', (tester) async {
    final completer = Completer<ReligiousProfile>();
    await _pump(
      tester,
      const Size(900, 700),
      _FutureRepository(completer.future),
      settle: false,
    );
    expect(find.byKey(const Key('profile-loading')), findsOneWidget);
    completer.completeError(
      const ReligiousProfileException(ReligiousProfileFailureKind.network),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load this profile'), findsOneWidget);
    expect(find.byKey(const Key('profile-retry')), findsOneWidget);
  });

  testWidgets('does not duplicate a title already stored in display name', (
    tester,
  ) async {
    const titled = ReligiousProfile(
      memberId: 'titled-id',
      displayName: 'Bro. Jaison Kollamparambil',
      title: 'Bro.',
      memberStatus: 'Active',
      sections: ReligiousProfileSections(),
    );
    await _pump(tester, const Size(1200, 900), const _ValueRepository(titled));
    expect(find.text('Bro. Jaison Kollamparambil'), findsOneWidget);
    expect(find.textContaining('Bro. Bro.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles a long name and dense assignment history', (
    tester,
  ) async {
    final dense = ReligiousProfile(
      memberId: 'dense-id',
      displayName: 'Christopher Emmanuel Valiyaparambil Kollamparambil',
      title: 'Bro.',
      memberStatus: 'Higher Studies',
      canonicalStatus: 'Temporary Professed',
      community: 'Sacred Heart Community with a Long Display Name',
      sections: ReligiousProfileSections(
        communityAssignments: List.generate(
          12,
          (index) => AssignmentRecord(
            kind: 'Community',
            name: 'Community Assignment ${index + 1}',
            role: 'Member',
            fromDate: DateTime(2010 + index),
            toDate: index == 11 ? null : DateTime(2011 + index),
          ),
        ),
      ),
    );
    await _pump(tester, const Size(1200, 3000), _ValueRepository(dense));
    expect(find.textContaining('Christopher Emmanuel'), findsOneWidget);
    expect(find.text('Community Assignment 12'), findsOneWidget);
    expect(find.text('Community Assignment 1'), findsNothing);
    expect(find.text('View Full Timeline'), findsOneWidget);
    await tester.tap(find.text('View Full Timeline'));
    await tester.pumpAndSettle();
    expect(find.text('Community Assignment 1'), findsOneWidget);
    expect(find.text('Show Latest Only'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  ReligiousProfileRepository repository, {
  bool settle = true,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: ReligiousProfileScreen(
          memberId: 'member-uuid-1',
          repository: repository,
          onBack: () {},
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

class _ValueRepository implements ReligiousProfileRepository {
  const _ValueRepository(this.profile);
  final ReligiousProfile profile;
  @override
  Future<ReligiousProfile> fetchProfile(String memberId) async => profile;
}

class _FutureRepository implements ReligiousProfileRepository {
  const _FutureRepository(this.future);
  final Future<ReligiousProfile> future;
  @override
  Future<ReligiousProfile> fetchProfile(String memberId) => future;
}
