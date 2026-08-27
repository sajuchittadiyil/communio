import '../models/religious_profile.dart';

abstract interface class ReligiousProfileRepository {
  Future<ReligiousProfile> fetchProfile(String memberId);
}

class ReligiousProfileException implements Exception {
  const ReligiousProfileException(this.kind, {this.cause});
  final ReligiousProfileFailureKind kind;
  final Object? cause;
}

enum ReligiousProfileFailureKind {
  notFound,
  network,
  authentication,
  permission,
  unexpected,
}
