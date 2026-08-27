import '../models/member_directory_entry.dart';

abstract interface class MemberDirectoryRepository {
  Future<List<MemberDirectoryEntry>> fetchMembers();
}

enum MemberDirectoryFailureKind {
  network,
  authentication,
  permission,
  schemaQuery,
  unexpected,
}

class MemberDirectoryException implements Exception {
  const MemberDirectoryException(this.kind, {this.cause});

  final MemberDirectoryFailureKind kind;
  final Object? cause;
}
