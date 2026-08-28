import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/governance_models.dart';
import 'governance_repository.dart';

class SupabaseGovernanceRepository implements GovernanceRepository {
  const SupabaseGovernanceRepository(this._client) : _loader = null;

  const SupabaseGovernanceRepository.forTesting(
    Future<dynamic> Function() loader,
  ) : _client = null,
      _loader = loader;

  final SupabaseClient? _client;
  final Future<dynamic> Function()? _loader;

  @override
  Future<List<GovernanceBody>> fetchBodies() async {
    try {
      final response =
          await (_loader?.call() ??
              _client!.rpc('get_provincial_governance_bodies_safe'));
      final rows = response is List ? response : const [];
      final bodies = rows
          .whereType<Map>()
          .map((row) => GovernanceBody.fromMap(row.cast()))
          .toList();
      bodies.sort((first, second) {
        final order = first.displayOrder.compareTo(second.displayOrder);
        return order != 0 ? order : first.name.compareTo(second.name);
      });
      return bodies;
    } catch (_) {
      throw const GovernanceDataException();
    }
  }
}
