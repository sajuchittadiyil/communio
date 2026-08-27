class AskCommunioRequest {
  const AskCommunioRequest({required this.question, this.context});

  final String question;
  final AskCommunioContext? context;

  Map<String, dynamic> toJson() => {
    'question': question.trim(),
    if (context != null) 'context': context!.toJson(),
  };
}

class AskCommunioContext {
  const AskCommunioContext({
    this.lastIntent,
    this.primaryEntityType,
    this.primaryEntityId,
    this.primaryEntityName,
    this.secondaryEntityType,
    this.secondaryEntityId,
    this.secondaryEntityName,
    this.lastYear,
    this.lastResultCount,
    this.ambiguousEntityType,
    this.focusEntityType,
    this.focusEntityId,
    this.focusEntityName,
    this.lastAnswerEntityType,
    this.lastAnswerEntityId,
    this.lastAnswerEntityName,
    this.entitySetType,
    this.entitySetSize,
  });

  factory AskCommunioContext.fromJson(Map<String, dynamic> json) =>
      AskCommunioContext(
        lastIntent: json['last_intent']?.toString(),
        primaryEntityType: json['primary_entity_type']?.toString(),
        primaryEntityId: json['primary_entity_id']?.toString(),
        primaryEntityName: json['primary_entity_name']?.toString(),
        secondaryEntityType: json['secondary_entity_type']?.toString(),
        secondaryEntityId: json['secondary_entity_id']?.toString(),
        secondaryEntityName: json['secondary_entity_name']?.toString(),
        lastYear: int.tryParse(json['last_year']?.toString() ?? ''),
        lastResultCount: int.tryParse(
          json['last_result_count']?.toString() ?? '',
        ),
        ambiguousEntityType: json['ambiguous_entity_type']?.toString(),
        focusEntityType: json['focus_entity_type']?.toString(),
        focusEntityId: json['focus_entity_id']?.toString(),
        focusEntityName: json['focus_entity_name']?.toString(),
        lastAnswerEntityType: json['last_answer_entity_type']?.toString(),
        lastAnswerEntityId: json['last_answer_entity_id']?.toString(),
        lastAnswerEntityName: json['last_answer_entity_name']?.toString(),
        entitySetType: json['entity_set_type']?.toString(),
        entitySetSize: int.tryParse(json['entity_set_size']?.toString() ?? ''),
      );

  final String? lastIntent;
  final String? primaryEntityType;
  final String? primaryEntityId;
  final String? primaryEntityName;
  final String? secondaryEntityType;
  final String? secondaryEntityId;
  final String? secondaryEntityName;
  final int? lastYear;
  final int? lastResultCount;
  final String? ambiguousEntityType;
  final String? focusEntityType;
  final String? focusEntityId;
  final String? focusEntityName;
  final String? lastAnswerEntityType;
  final String? lastAnswerEntityId;
  final String? lastAnswerEntityName;
  final String? entitySetType;
  final int? entitySetSize;

  Map<String, dynamic> toJson() => {
    if (lastIntent != null) 'last_intent': lastIntent,
    if (primaryEntityType != null) 'primary_entity_type': primaryEntityType,
    if (primaryEntityId != null) 'primary_entity_id': primaryEntityId,
    if (primaryEntityName != null) 'primary_entity_name': primaryEntityName,
    if (secondaryEntityType != null)
      'secondary_entity_type': secondaryEntityType,
    if (secondaryEntityId != null) 'secondary_entity_id': secondaryEntityId,
    if (secondaryEntityName != null)
      'secondary_entity_name': secondaryEntityName,
    if (lastYear != null) 'last_year': lastYear,
    if (lastResultCount != null) 'last_result_count': lastResultCount,
    if (ambiguousEntityType != null)
      'ambiguous_entity_type': ambiguousEntityType,
    if (focusEntityType != null) 'focus_entity_type': focusEntityType,
    if (focusEntityId != null) 'focus_entity_id': focusEntityId,
    if (focusEntityName != null) 'focus_entity_name': focusEntityName,
    if (lastAnswerEntityType != null)
      'last_answer_entity_type': lastAnswerEntityType,
    if (lastAnswerEntityId != null) 'last_answer_entity_id': lastAnswerEntityId,
    if (lastAnswerEntityName != null)
      'last_answer_entity_name': lastAnswerEntityName,
    if (entitySetType != null) 'entity_set_type': entitySetType,
    if (entitySetSize != null) 'entity_set_size': entitySetSize,
  };
}

class AskCommunioResponse {
  const AskCommunioResponse({
    required this.answer,
    required this.answerType,
    required this.reliability,
    required this.generatedAt,
    this.items = const [],
    this.sources = const [],
    this.entities = const [],
    this.warning,
    this.context,
  });

  factory AskCommunioResponse.fromJson(Map<String, dynamic> json) =>
      AskCommunioResponse(
        answer: json['answer']?.toString() ?? '',
        answerType: json['answer_type']?.toString() ?? 'text',
        reliability: json['reliability']?.toString() ?? 'unknown',
        generatedAt:
            DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
            DateTime.now().toUtc(),
        items: _maps(json['items']),
        sources: _maps(
          json['sources'],
        ).map(AskCommunioSource.fromJson).toList(growable: false),
        entities: _maps(
          json['entities'],
        ).map(AskCommunioEntityReference.fromJson).toList(growable: false),
        warning: json['warning']?.toString(),
        context: json['context'] is Map
            ? AskCommunioContext.fromJson(
                Map<String, dynamic>.from(json['context'] as Map),
              )
            : null,
      );

  final String answer;
  final String answerType;
  final String reliability;
  final DateTime generatedAt;
  final List<Map<String, dynamic>> items;
  final List<AskCommunioSource> sources;
  final List<AskCommunioEntityReference> entities;
  final String? warning;
  final AskCommunioContext? context;
}

class AskCommunioSource {
  const AskCommunioSource({
    required this.label,
    required this.sourceType,
    this.recordId,
    this.detail,
  });

  factory AskCommunioSource.fromJson(Map<String, dynamic> json) =>
      AskCommunioSource(
        label: json['label']?.toString() ?? 'Communio record',
        sourceType: json['source_type']?.toString() ?? 'record',
        recordId: json['record_id']?.toString(),
        detail: json['detail']?.toString(),
      );

  final String label;
  final String sourceType;
  final String? recordId;
  final String? detail;
}

class AskCommunioEntityReference {
  const AskCommunioEntityReference({
    required this.id,
    required this.type,
    required this.label,
  });

  factory AskCommunioEntityReference.fromJson(Map<String, dynamic> json) =>
      AskCommunioEntityReference(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'record',
        label: json['label']?.toString() ?? 'View record',
      );

  final String id;
  final String type;
  final String label;
}

class SuggestedQuestion {
  const SuggestedQuestion(this.question, this.iconName);

  final String question;
  final String iconName;
}

List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value.whereType<Map>().map((row) => row.cast<String, dynamic>()).toList()
    : const [];
