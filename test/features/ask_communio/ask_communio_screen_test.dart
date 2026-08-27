import 'package:communio/features/ask_communio/data/ask_communio_service.dart';
import 'package:communio/features/ask_communio/models/ask_communio_models.dart';
import 'package:communio/features/ask_communio/screens/ask_communio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('response maps grounded evidence and entity references', () {
    final response = AskCommunioResponse.fromJson({
      'answer': 'Fr. Thomas is the current Provincial.',
      'answer_type': 'record',
      'reliability': 'grounded',
      'generated_at': '2026-08-19T00:00:00Z',
      'sources': [
        {
          'label': 'Current appointment',
          'source_type': 'appointment',
          'record_id': 'A1',
        },
      ],
      'entities': [
        {'id': 'M1', 'type': 'member', 'label': 'Fr. Thomas'},
      ],
    });

    expect(response.reliability, 'grounded');
    expect(response.sources.single.sourceType, 'appointment');
    expect(response.entities.single.id, 'M1');
  });

  test('request serializes structured conversation context', () {
    const request = AskCommunioRequest(
      question: 'Where is he now?',
      context: AskCommunioContext(
        primaryEntityType: 'member',
        primaryEntityId: 'member-1',
        primaryEntityName: 'Joseph Varghese',
        focusEntityType: 'member',
        focusEntityId: 'member-1',
        focusEntityName: 'Joseph Varghese',
        entitySetType: 'member',
        entitySetSize: 1,
      ),
    );
    expect(request.toJson()['context'], {
      'primary_entity_type': 'member',
      'primary_entity_id': 'member-1',
      'primary_entity_name': 'Joseph Varghese',
      'focus_entity_type': 'member',
      'focus_entity_id': 'member-1',
      'focus_entity_name': 'Joseph Varghese',
      'entity_set_type': 'member',
      'entity_set_size': 1,
    });
  });

  testWidgets('suggestion submits and renders answer with evidence', (
    tester,
  ) async {
    final service = _Service();
    AskCommunioEntityReference? opened;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: AskCommunioScreen(
          service: service,
          onEntity: (entity) => opened = entity,
        ),
      ),
    );

    expect(
      find.text('Preserve the Past. Understand the Present.'),
      findsOneWidget,
    );
    expect(
      find.text('Who are the current Community Superiors?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Who are the current Community Superiors?'));
    await tester.pumpAndSettle();

    expect(service.lastQuestion, 'Who are the current Community Superiors?');
    expect(find.text('Two members are eligible.'), findsOneWidget);
    expect(find.text('Evidence from Communio'), findsOneWidget);
    expect(find.text('Eligibility evaluation'), findsOneWidget);
    await tester.tap(find.text('Fr. Example'));
    expect(opened?.id, 'member-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failure offers a retry action', (tester) async {
    final service = _Service(fail: true);
    await tester.pumpWidget(
      MaterialApp(home: AskCommunioScreen(service: service)),
    );
    await tester.enterText(
      find.byKey(const Key('ask-communio-question')),
      'Who is the current Provincial?',
    );
    await tester.tap(find.byTooltip('Ask Communio'));
    await tester.pumpAndSettle();

    expect(find.text('Service unavailable for test.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('large result sets expand without duplicating prose', (
    tester,
  ) async {
    final service = _Service(
      response: AskCommunioResponse(
        answer: '12 members are under 50 years of age.',
        answerType: 'list',
        reliability: 'grounded',
        generatedAt: DateTime.utc(2026, 8, 26),
        entities: List.generate(
          12,
          (index) => AskCommunioEntityReference(
            id: 'member-$index',
            type: 'member',
            label: 'Member $index',
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AskCommunioScreen(service: service, onEntity: (_) {}),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('ask-communio-question')),
      'who are under 50',
    );
    await tester.tap(find.byTooltip('Ask Communio'));
    await tester.pumpAndSettle();

    expect(find.text('Show all 12'), findsOneWidget);
    expect(find.text('Member 10'), findsNothing);
    await tester.ensureVisible(find.text('Show all 12'));
    await tester.tap(find.text('Show all 12'));
    await tester.pumpAndSettle();
    expect(find.text('Member 10'), findsOneWidget);
  });

  testWidgets('successful context survives an unsupported turn', (
    tester,
  ) async {
    final service = _ContextService();
    await tester.pumpWidget(
      MaterialApp(home: AskCommunioScreen(service: service)),
    );
    for (final question in [
      'who is the oldest',
      'write a homily',
      'where is he now',
    ]) {
      await tester.enterText(
        find.byKey(const Key('ask-communio-question')),
        question,
      );
      await tester.tap(find.byTooltip('Ask Communio'));
      await tester.pumpAndSettle();
    }
    expect(service.requests[0].context, isNull);
    expect(service.requests[1].context?.primaryEntityId, 'member-joseph');
    expect(service.requests[2].context?.primaryEntityId, 'member-joseph');
  });

  testWidgets('disposing the screen clears session context', (tester) async {
    final service = _ContextService();
    await tester.pumpWidget(
      MaterialApp(home: AskCommunioScreen(service: service)),
    );
    await tester.enterText(
      find.byKey(const Key('ask-communio-question')),
      'who is the oldest',
    );
    await tester.tap(find.byTooltip('Ask Communio'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpWidget(
      MaterialApp(home: AskCommunioScreen(service: service)),
    );
    await tester.enterText(
      find.byKey(const Key('ask-communio-question')),
      'where is Joseph Varghese',
    );
    await tester.tap(find.byTooltip('Ask Communio'));
    await tester.pumpAndSettle();
    expect(service.requests.last.context, isNull);
  });
}

class _Service implements AskCommunioService {
  _Service({this.fail = false, this.response});
  final bool fail;
  final AskCommunioResponse? response;
  String? lastQuestion;

  @override
  Future<AskCommunioResponse> ask(AskCommunioRequest request) async {
    lastQuestion = request.question;
    if (fail) throw const AskCommunioException('Service unavailable for test.');
    if (response != null) return response!;
    return AskCommunioResponse(
      answer: 'Two members are eligible.',
      answerType: 'list',
      reliability: 'grounded',
      generatedAt: DateTime.utc(2026, 8, 19),
      sources: const [
        AskCommunioSource(
          label: 'Eligibility evaluation',
          sourceType: 'eligibility',
        ),
      ],
      entities: const [
        AskCommunioEntityReference(
          id: 'member-1',
          type: 'member',
          label: 'Fr. Example',
        ),
      ],
    );
  }
}

class _ContextService implements AskCommunioService {
  final requests = <AskCommunioRequest>[];

  @override
  Future<AskCommunioResponse> ask(AskCommunioRequest request) async {
    requests.add(request);
    final unsupported = request.question == 'write a homily';
    return AskCommunioResponse(
      answer: unsupported ? 'I could not answer that.' : 'Grounded answer.',
      answerType: unsupported ? 'empty' : 'record',
      reliability: unsupported ? 'insufficient_evidence' : 'grounded',
      generatedAt: DateTime.utc(2026, 8, 27),
      context: unsupported
          ? null
          : const AskCommunioContext(
              primaryEntityType: 'member',
              primaryEntityId: 'member-joseph',
              primaryEntityName: 'Joseph Varghese',
            ),
    );
  }
}
