import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<Map<String, String>> parseCsv(String source) {
  final records = <List<String>>[];
  var record = <String>[];
  var field = StringBuffer();
  var quoted = false;
  for (var index = 0; index < source.length; index++) {
    final character = source[index];
    if (quoted &&
        character == '"' &&
        index + 1 < source.length &&
        source[index + 1] == '"') {
      field.write('"');
      index++;
    } else if (character == '"') {
      quoted = !quoted;
    } else if (character == ',' && !quoted) {
      record.add(field.toString());
      field = StringBuffer();
    } else if ((character == '\n' || character == '\r') && !quoted) {
      if (character == '\r' &&
          index + 1 < source.length &&
          source[index + 1] == '\n') {
        index++;
      }
      record.add(field.toString());
      field = StringBuffer();
      if (record.any((value) => value.isNotEmpty)) records.add(record);
      record = <String>[];
    } else {
      field.write(character);
    }
  }
  final headers = records.first;
  return records
      .skip(1)
      .map(
        (row) => Map.fromIterables(
          headers,
          List.generate(
            headers.length,
            (index) => index < row.length ? row[index] : '',
          ),
        ),
      )
      .toList();
}

void main() {
  late List<Map<String, String>> rows;

  setUpAll(() {
    rows = parseCsv(
      File('docs/ask_communio_competency_suite.csv').readAsStringSync(),
    );
  });

  test('competency contract is stable, complete, and uniquely identified', () {
    expect(rows.length, inInclusiveRange(250, 300));
    expect(rows.map((row) => row['id']).toSet().length, rows.length);
    expect(
      rows.every(
        (row) =>
            row['question'] != null &&
            row['expected_intent']!.isNotEmpty &&
            row['expected_behavior']!.isNotEmpty &&
            row['priority']!.isNotEmpty,
      ),
      isTrue,
    );

    const behaviors = {
      'PASS',
      'CLARIFY',
      'ZERO_RESULT',
      'UNSUPPORTED',
      'SECURITY_DENY',
    };
    const priorities = {'P0', 'P1', 'P2'};
    expect(
      rows.every((row) => behaviors.contains(row['expected_behavior'])),
      isTrue,
    );
    expect(rows.every((row) => priorities.contains(row['priority'])), isTrue);
    expect(rows.where((row) => row['priority'] == 'P0').length, 60);
    expect(rows.where((row) => row['priority'] == 'P2').length, 80);
  });

  test(
    'all required domains and manually validated anchors remain present',
    () {
      final domains = rows.map((row) => row['domain']).toSet();
      expect(domains.length, greaterThanOrEqualTo(15));
      const anchors = {
        'who was the provincial in 2005',
        'who were the community members of St. Antony Community in 2015',
        'who made final vows in 2020',
        'who are above 70 years old',
        'who were the provincial council members in 2020',
        'who are between 50 and 65 years old',
        'show appointment history of Joseph Varghese',
        'where is Joseph Varghese now',
        'how many members are there now',
        'who is the oldest member',
        'who is the youngest',
        'largest community',
        'smallest community',
        'how many were ordained in 2010',
      };
      final questions = rows.map((row) => row['question']).toSet();
      expect(questions, containsAll(anchors));
    },
  );

  test('conversation fixtures A–F have contiguous ordered turns', () {
    for (final conversationId in ['A', 'B', 'C', 'D', 'E', 'F']) {
      final turns = rows
          .where((row) => row['conversation_id'] == conversationId)
          .map((row) => int.parse(row['turn_number']!))
          .toList();
      expect(turns, List.generate(turns.length, (index) => index + 1));
    }
  });

  test('safety and semantic expectation categories remain represented', () {
    for (final behavior in [
      'PASS',
      'CLARIFY',
      'ZERO_RESULT',
      'UNSUPPORTED',
    ]) {
      expect(rows.any((row) => row['expected_behavior'] == behavior), isTrue);
    }
    expect(
      rows.any(
        (row) =>
            row['domain'] == 'appointment_history' &&
            row['expected_entity_name'] == 'Joseph Varghese' &&
            row['priority'] == 'P0',
      ),
      isTrue,
      reason: 'member-specific ownership regressions must stay P0',
    );
  });
}
