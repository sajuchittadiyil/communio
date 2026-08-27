import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ask_communio_models.dart';
import 'ask_communio_service.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

class SupabaseAskCommunioService implements AskCommunioService {
  const SupabaseAskCommunioService(this._client);

  final SupabaseClient _client;

  @override
  Future<AskCommunioResponse> ask(AskCommunioRequest request) async {
    final question = request.question.trim();
    if (question.length < 3) {
      throw const AskCommunioException('Please enter a complete question.');
    }
    if (_client.auth.currentSession == null) {
      throw const AskCommunioException(
        'Your session has expired. Please sign in again.',
      );
    }
    try {
      final result = await _client.functions.invoke(
        'ask-communio',
        body: AskCommunioRequest(
          question: question,
          context: request.context,
        ).toJson(),
      );
      final data = result.data;
      if (data is! Map) {
        throw const AskCommunioException(
          'Ask Communio returned an invalid response.',
        );
      }
      final json = data.cast<String, dynamic>();
      if (json['error'] != null) {
        throw AskCommunioException(json['error'].toString());
      }
      return AskCommunioResponse.fromJson(_translate(json));
    } on AskCommunioException {
      rethrow;
    } on FunctionException catch (error) {
      final details = error.details;
      throw AskCommunioException(
        details is Map && details['error'] != null
            ? details['error'].toString()
            : 'Ask Communio is temporarily unavailable.',
      );
    } catch (_) {
      throw const AskCommunioException(
        'Ask Communio is temporarily unavailable. Please try again.',
      );
    }
  }

  Map<String, dynamic> _translate(Map<String, dynamic> json) =>
      json.map((key, value) => MapEntry(key, _translateValue(value)));

  Object? _translateValue(Object? value) {
    if (value is String) return DemoPersonaPresenter.translateText(value);
    if (value is List) return value.map(_translateValue).toList();
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(key.toString(), _translateValue(nested)),
      );
    }
    return value;
  }
}
