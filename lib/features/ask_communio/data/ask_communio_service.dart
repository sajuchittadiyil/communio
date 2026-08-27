import '../models/ask_communio_models.dart';

abstract interface class AskCommunioService {
  Future<AskCommunioResponse> ask(AskCommunioRequest request);
}

class AskCommunioException implements Exception {
  const AskCommunioException(this.message);

  final String message;

  @override
  String toString() => message;
}
