import 'package:communio/features/documents/data/documents_repository.dart';
import 'package:communio/features/documents/models/province_document.dart';
import 'package:communio/features/documents/screens/documents_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads documents and derives summary metrics', (tester) async {
    await _pump(tester);
    expect(find.text('DOCUMENTS'), findsOneWidget);
    expect(find.text('28 Documents'), findsWidgets);
    expect(find.text('12 Reports'), findsOneWidget);
    expect(find.text('2 Policies'), findsOneWidget);
    expect(find.text('2 Meeting Records'), findsOneWidget);
  });

  testWidgets('search covers related entity and shows empty state', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'Budakata School');
    await tester.pump();
    expect(find.text('Budakata School Annual Report 2025-26'), findsOneWidget);
    expect(find.text('Related to: Budakata School'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'no such institutional record',
    );
    await tester.pump();
    expect(find.text('No matching documents'), findsOneWidget);
    expect(find.text('Clear filters'), findsOneWidget);
  });

  testWidgets('primary and category filters are deterministic', (tester) async {
    await _pump(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Communities'));
    await tester.pump();
    expect(
      find.text('Budakata Mission Community Annual Report 2025-26'),
      findsOneWidget,
    );
    expect(find.text('Annual Province Report 2025-26'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<DocumentCategory?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finance').last);
    await tester.pumpAndSettle();
    expect(find.text('Province Financial Summary 2025-26'), findsOneWidget);
    expect(
      find.text('Budakata Mission Community Annual Report 2025-26'),
      findsNothing,
    );
  });

  test('Recent means newest document dates', () {
    final recent = filterDocuments(
      demoDocuments,
      quickFilter: DocumentQuickFilter.recent,
    );
    expect(recent, hasLength(8));
    expect(recent.first.title, 'Provincial Council Minutes - 20 August 2026');
    for (var index = 1; index < recent.length; index++) {
      expect(
        recent[index - 1].documentDate.isBefore(recent[index].documentDate),
        isFalse,
      );
    }
  });

  testWidgets('document card tap reports selected record', (tester) async {
    ProvinceDocument? opened;
    await _pump(tester, onOpen: (document) => opened = document);
    await tester.tap(find.text('Provincial Council Minutes - 20 August 2026'));
    expect(opened?.id, 'DOC023');
    expect(opened?.hasFile, isTrue);
  });

  testWidgets('detail distinguishes attached and metadata-only documents', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DocumentDetailScreen(document: demoDocuments.first)),
    );
    expect(find.text('Open Document'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: DocumentDetailScreen(document: demoDocuments[2])),
    );
    expect(find.text('Demo file unavailable'), findsOneWidget);
  });

  testWidgets('empty repository has a useful empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DocumentsScreen(repository: _EmptyRepository())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No documents available'), findsOneWidget);
  });

  testWidgets('Documents is overflow-safe on mobile widths', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final width in [360.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      await _pump(tester);
      expect(find.text('Search documents...'), findsOneWidget);
      expect(find.text('Institutional records and reports'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Institutional records and reports')).dy,
        greaterThan(0),
      );
      await tester.drag(
        find.byKey(const Key('document-quick-filters')),
        const Offset(-800, 0),
      );
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ChoiceChip, 'Governance').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('cards retain file-aware action labels', (tester) async {
    await _pump(tester);
    expect(find.text('View Document →'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Province Directory 2026');
    await tester.pump();
    expect(find.text('View Details →'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  ValueChanged<ProvinceDocument>? onOpen,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DocumentsScreen(
          repository: const DemoDocumentsRepository(),
          onOpenDocument: onOpen,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _EmptyRepository implements DocumentsRepository {
  const _EmptyRepository();
  @override
  Future<List<ProvinceDocument>> fetchDocuments() async => const [];
}
