import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/organization_identity_models.dart';
import 'organization_identity_repository.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';

class SupabaseOrganizationIdentityRepository
    implements OrganizationIdentityRepository {
  const SupabaseOrganizationIdentityRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<OrganizationIdentitySnapshot> fetchIdentity() async {
    try {
      final congregationRows = await _client
          .from('congregations')
          .select()
          .eq('active', true)
          .order('created_at')
          .limit(1);
      if (congregationRows.isEmpty) {
        throw const OrganizationIdentityException();
      }
      final congregationRow = congregationRows.first;
      final congregationId = _text(congregationRow, 'id')!;
      final results = await Future.wait([
        _client
            .from('congregation_leadership')
            .select()
            .eq('congregation_id', congregationId)
            .eq('active', true)
            .order('display_order'),
        _client
            .from('provinces')
            .select()
            .eq('congregation_id', congregationId)
            .eq('active', true)
            .order('created_at')
            .limit(1),
      ]);
      final leadershipRows = List<Map<String, dynamic>>.from(
        await _client.rpc('get_provincial_leadership_safe'),
      );
      final counts = Map<String, dynamic>.from(
        await _client.rpc('get_provincial_profile_counts_safe'),
      );
      final provinceRows = results[1];
      if (provinceRows.isEmpty) throw const OrganizationIdentityException();
      final provinceRow = provinceRows.first;
      final provincialLeaders = _provinceLeaders(
        leadershipRows,
        contactRows: const [],
        memberRows: const [],
      );
      final personaIdentity = DemoPersonaPresenter.identity;

      return OrganizationIdentitySnapshot(
        congregation: CongregationProfile(
          id: congregationId,
          name:
              personaIdentity?.congregationName ??
              _text(congregationRow, 'name') ??
              'Congregation',
          abbreviation:
              personaIdentity?.abbreviation ??
              _text(congregationRow, 'abbreviation'),
          motto: personaIdentity?.motto ?? _text(congregationRow, 'motto'),
          charism: _text(congregationRow, 'charism'),
          founder:
              personaIdentity?.founderName ?? _text(congregationRow, 'founder'),
          founderImageUrl: _text(congregationRow, 'founder_image_url'),
          patronSaintName:
              personaIdentity?.patronSaintName ??
              _text(congregationRow, 'patron_saint_name'),
          patronSaintImageUrl: _text(congregationRow, 'patron_saint_image_url'),
          foundedYear: _integer(congregationRow, 'founded_year'),
          generalateCity: _text(congregationRow, 'generalate_city'),
          generalateAddress: _text(congregationRow, 'generalate_address'),
          country: _text(congregationRow, 'country'),
          email: _text(congregationRow, 'email'),
          phone: _text(congregationRow, 'phone'),
          website: _text(congregationRow, 'website'),
        ),
        leaders: results[0]
            .map((row) {
              final leaderId = _text(row, 'id')!;
              final leaderAlias = DemoPersonaPresenter.leader(leaderId);
              return CongregationLeader(
                id: leaderId,
                displayName:
                    leaderAlias?.displayName ??
                    (DemoPersonaPresenter.isSisters
                        ? 'Sister'
                        : _text(row, 'display_name') ?? 'Religious'),
                roleName: DemoPersonaPresenter.role(
                  _text(row, 'role_name') ?? 'General Councillor',
                ),
                displayOrder: _integer(row, 'display_order') ?? 0,
                title: leaderAlias?.title ?? _text(row, 'title'),
                postNominal:
                    leaderAlias?.postNominal ?? _text(row, 'post_nominal'),
                countryOfOrigin: _text(row, 'country_of_origin'),
                administrationCity: _text(row, 'administration_city'),
                email: _text(row, 'email'),
                phone: _text(row, 'phone'),
                photoUrl: DemoPersonaPresenter.isSisters
                    ? null
                    : _text(row, 'photo_url'),
              );
            })
            .toList(growable: false),
        province: ProvinceProfile(
          id: _text(provinceRow, 'id')!,
          congregationName:
              personaIdentity?.congregationName ??
              _text(congregationRow, 'name') ??
              'Congregation',
          name:
              personaIdentity?.provinceName ??
              _text(provinceRow, 'name') ??
              'Province',
          motto: personaIdentity?.motto ?? _text(provinceRow, 'motto'),
          headquarters: _text(provinceRow, 'headquarters'),
          address: _text(provinceRow, 'address'),
          country: _text(provinceRow, 'country'),
          email: _text(provinceRow, 'email'),
          phone: _text(provinceRow, 'phone'),
          website: _text(provinceRow, 'website'),
          establishedDate: DateTime.tryParse(
            _text(provinceRow, 'established_date') ?? '',
          ),
          activeMembers: _integer(counts, 'active_members') ?? 0,
          activeCommunities: _integer(counts, 'communities') ?? 0,
          activeMinistries: _integer(counts, 'ministries') ?? 0,
          activeFormationMembers: _integer(counts, 'formation_members'),
          currentProvincialOffices: _integer(
            counts,
            'current_provincial_offices',
          ),
        ),
        provincialLeaders: provincialLeaders,
      );
    } catch (error) {
      if (error is OrganizationIdentityException) rethrow;
      throw const OrganizationIdentityException();
    }
  }
}

List<ProvinceLeader> _provinceLeaders(
  List<Map<String, dynamic>> rows, {
  required List<Map<String, dynamic>> contactRows,
  required List<Map<String, dynamic>> memberRows,
}) {
  final members = <String, Map<String, dynamic>>{};
  for (final row in memberRows) {
    final id = _text(row, 'id');
    if (id != null) members[id] = row;
  }
  final contacts = <String, Map<String, String>>{};
  for (final row in contactRows) {
    final memberId = _text(row, 'member_id');
    final value = _text(row, 'contact_value');
    final type = _text(row, 'contact_type_code')?.toLowerCase();
    if (memberId == null || value == null || type == null) continue;
    contacts.putIfAbsent(memberId, () => {})[type] = value;
  }
  return rows
      .where((row) {
        final roleCode = _text(row, 'office_type_code') ?? '';
        return _isCoreProvincialRole(roleCode);
      })
      .map((row) {
        final memberId = _text(row, 'member_id') ?? '';
        final member = members[memberId] ?? const <String, dynamic>{};
        final memberContacts = contacts[memberId] ?? const <String, String>{};
        final roleCode = _text(row, 'office_type_code') ?? 'office';
        return ProvinceLeader(
          memberId: memberId,
          displayName: DemoPersonaPresenter.memberName(
            memberId,
            _text(row, 'display_name') ??
                _text(member, 'display_name') ??
                'Religious',
          ),
          roleCode: roleCode,
          roleName: DemoPersonaPresenter.role(_label(roleCode)),
          fromDate: DateTime.tryParse(_text(row, 'from_date') ?? ''),
          photoUrl: DemoPersonaPresenter.memberPhoto(
            memberId,
            _text(row, 'photo_url') ?? _text(member, 'photo_url'),
          ),
          phone: memberContacts['phone'] ?? memberContacts['mobile'],
          whatsApp: memberContacts['whatsapp'],
          email: memberContacts['email'],
        );
      })
      .toList();
}

bool _isCoreProvincialRole(String roleCode) {
  final value = roleCode.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  return value.trim() == 'provincial' ||
      value.contains('assistant provincial') ||
      value.contains('vice provincial') ||
      value.contains('provincial councillor') ||
      value.contains('provincial councilor') ||
      value.contains('provincial secretary') ||
      value.contains('provincial bursar');
}

String _label(String value) => value
    .split(RegExp(r'[_\s]+'))
    .where((part) => part.isNotEmpty)
    .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
    .join(' ');

String? _text(Map<String, dynamic> row, String key) {
  final value = row[key]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

int? _integer(Map<String, dynamic> row, String key) {
  final value = row[key];
  return value is int ? value : int.tryParse(value?.toString() ?? '');
}
