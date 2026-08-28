import '../models/governance_models.dart';

abstract interface class GovernanceRepository {
  Future<List<GovernanceBody>> fetchBodies();
}

class GovernanceDataException implements Exception {
  const GovernanceDataException();

  @override
  String toString() => 'Governance data could not be loaded.';
}
