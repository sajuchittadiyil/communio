import 'package:communio/features/access/data/community_administration_repository.dart';
import 'package:communio/features/access/screens/community_administration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Superior administration exposes scoped actions and records', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityAdministrationScreen(
          repository: const _Repository(),
          communityName: 'Sacred Heart Community',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sacred Heart Community'), findsOneWidget);
    expect(find.text('Add Calendar Event'), findsOneWidget);
    expect(find.text('Plan Community Event'), findsOneWidget);
    expect(find.text('Meeting Minutes'), findsOneWidget);
    expect(find.text('Monthly Recollection'), findsOneWidget);
    expect(find.text('August Minutes'), findsOneWidget);
  });

  testWidgets('planned action opens an event form defaulted to Planned', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityAdministrationScreen(
          repository: const _Repository(),
          communityName: 'Sacred Heart Community',
          initialAction: CommunityAdministrationAction.plannedEvent,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Community Event'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Planned'), findsOneWidget);
    expect(find.text('Visible to Provincial Team'), findsOneWidget);
  });

  testWidgets('event form dropdowns do not overflow at narrow mobile widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final width in [375.0, 430.0]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 812);
      await tester.pumpWidget(
        MaterialApp(
          home: CommunityEventForm(
            repository: const _Repository(),
            communityName: 'Sacred Heart Community',
            initialStatus: 'confirmed',
            event: CommunityEventRecord(
              id: 'event',
              title: 'Community Council Meeting',
              type: 'community_meeting',
              startsAt: DateTime(2026, 8, 23, 18),
              status: 'confirmed',
              responsibleMemberId: 'long-resident',
              visibleToProvince: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'width $width');
      expect(find.text('Visible to Provincial Team'), findsOneWidget);
    }
  });
}

class _Repository implements CommunityAdministrationRepository {
  const _Repository();
  @override
  Future<List<CommunityEventRecord>> fetchEvents() async => [
    CommunityEventRecord(
      id: 'event',
      title: 'Monthly Recollection',
      type: 'recollection',
      startsAt: DateTime(2026, 8, 29),
      status: 'planned',
      visibleToProvince: true,
    ),
  ];
  @override
  Future<List<CommunityMeetingRecord>> fetchMeetings() async => [
    CommunityMeetingRecord(
      id: 'meeting',
      title: 'August Minutes',
      meetingDate: DateTime(2026, 8, 23),
      summary: 'Demo summary',
      visibleToProvince: true,
    ),
  ];
  @override
  Future<List<CommunityResidentOption>> fetchResidents() async => const [
    (
      id: 'long-resident',
      name: 'Brother Bartholomew Long Community Responsibility Name',
    ),
  ];
  @override
  Future<void> saveEvent(
    CommunityEventRecord event, {
    required bool create,
  }) async {}
  @override
  Future<void> saveMeeting(
    CommunityMeetingRecord meeting, {
    required bool create,
  }) async {}
  @override
  Future<void> deleteEvent(String id) async {}
}
