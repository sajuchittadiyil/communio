import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/ecclesiastical_name.dart';
import '../../demo_persona/data/demo_persona_presenter.dart';
import '../../../core/utils/responsibility_labels.dart';
import '../models/province_models.dart';
import 'calendar_entry_mapper.dart';
import 'province_repository.dart';
import 'storage_image_url.dart';

class SupabaseProvinceRepository
    implements ProvinceRepository, GovernanceHistoryRepository {
  const SupabaseProvinceRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<CommunityRecord>> fetchCommunities() async {
    try {
      if (_provincialSafeModules) return await _fetchCommunitiesSafe();
      final results = await Future.wait([
        _client.rpc('get_provincial_communities_safe'),
        _client.from('v_demo_member_directory').select(),
        _client.from('member_community_assignments').select(),
        _client.from('v_demo_ministry_operational').select(),
        _client.from('v_demo_member_public_contacts').select(),
        _client.from('member_ministry_assignments').select(),
        _client.from('v_demo_member_attention_events').select(),
        _client.from('communities').select(),
        _client.from('ministries').select(),
        _client.from('members').select('id,religious_id,photo_url'),
      ]);
      final memberPhotos = _memberPhotoLookup(results[9]);
      final contactRows = results[4];
      final ministryNames = {
        for (final r in results[3])
          _text(r, ['ministry_id'])!: _text(r, ['ministry_name']) ?? 'Ministry',
      };
      final currentMinistries = <String, String>{};
      for (final assignment in results[5]) {
        if (_text(assignment, ['to_date']) != null) continue;
        final memberId = _text(assignment, ['member_id']);
        final ministry = ministryNames[_text(assignment, ['ministry_id'])];
        if (memberId != null && ministry != null) {
          final role = _label(_text(assignment, ['responsibility_code']));
          currentMinistries[memberId] = role == null
              ? ministry
              : '$role · $ministry';
        }
      }
      final members = {
        for (final r in results[1])
          _text(r, ['member_id'])!: _person(
            r,
            memberPhotos: memberPhotos,
            contacts: _contactsFor(contactRows, _text(r, ['member_id'])),
            ministryAssignment: currentMinistries[_text(r, ['member_id'])],
            memberStatus: _label(
              _text(r, ['canonical_status_code', 'member_status_code']),
            ),
          ),
      };
      final namedMembers = _membersByUnambiguousName(members.values);
      final communityDetails = {
        for (final r in results[7]) _text(r, ['id']): r,
      };
      return results[0].map((row) {
        final id = _text(row, ['community_id']) ?? '';
        final detail = communityDetails[id] ?? const <String, dynamic>{};
        final history =
            results[2].where((a) => _text(a, ['community_id']) == id).map((a) {
              final member = members[_text(a, ['member_id'])];
              return ProvinceAssignment(
                person:
                    member ?? const ProvincePerson(id: '', name: 'Religious'),
                role:
                    communityResponsibilityLabel(
                      _text(a, ['responsibility_code']),
                    ) ??
                    _label(_text(a, ['responsibility_code'])),
                fromDate: _date(a, ['from_date']),
                toDate: _date(a, ['to_date']),
              );
            }).toList()..sort(
              (a, b) => (b.fromDate ?? DateTime(1)).compareTo(
                a.fromDate ?? DateTime(1),
              ),
            );
        final residents = history
            .where((a) => a.current)
            .map((a) => a.person.copyWith(role: a.role))
            .toList();
        final superiorId = _rawText(row, ['superior_member_id']);
        final accountantId = _rawText(row, ['accountant_member_id']);
        final superiorName = _rawText(row, [
          'superior_display_name',
          'superior',
        ]);
        final accountantName = _rawText(row, [
          'accountant_display_name',
          'accountant_or_bursar',
        ]);
        final superiorPerson =
            (superiorId == null ? null : members[superiorId]) ??
            selectCurrentLeader(history, const [
              'Community Superior',
              'Superior',
            ]) ??
            (superiorId == null
                ? _memberNamed(superiorName, namedMembers)
                : null);
        final accountantPerson =
            (accountantId == null ? null : members[accountantId]) ??
            selectCurrentLeader(history, const [
              'Community Accountant',
              'Community Bursar',
              'Accountant',
              'Bursar',
            ]) ??
            (accountantId == null
                ? _memberNamed(accountantName, namedMembers)
                : null);
        final ministryIds = results[3]
            .where((ministry) => _text(ministry, ['community_id']) == id)
            .map((ministry) => _text(ministry, ['ministry_id']))
            .whereType<String>()
            .toSet();
        final ministryRecords = results[3]
            .where((ministry) => _text(ministry, ['community_id']) == id)
            .map(
              (ministry) => mapOperationalMinistry(
                ministry,
                results[5],
                members,
                namedMembers,
                detail: results[8]
                    .where(
                      (detail) =>
                          _text(detail, ['id', 'ministry_id']) ==
                          _text(ministry, ['ministry_id', 'id']),
                    )
                    .firstOrNull,
                publicUrl: _publicCoverUrl,
              ),
            )
            .toList();
        final residentIds = residents.map((person) => person.id).toSet();
        final movements = results[6]
            .where(
              (event) =>
                  residentIds.contains(_text(event, ['member_id'])) &&
                  _text(event, ['timing_status'])?.toUpperCase() == 'CURRENT' &&
                  const {
                    'travel',
                    'retreat',
                    'training',
                    'study',
                    'home_leave',
                    'visit',
                  }.contains(_text(event, ['event_type'])?.toLowerCase()),
            )
            .map(
              (event) => CommunityMovement(
                person: members[_text(event, ['member_id'])]!,
                type: _text(event, ['event_type']) ?? 'movement',
                title: _text(event, ['title']) ?? 'Currently away',
                location: _text(event, ['location']),
                toDate: _date(event, ['to_date']),
              ),
            )
            .toList();
        return CommunityRecord(
          id: id,
          code: _text(row, ['community_code']),
          name: _text(row, ['community_name']) ?? 'Community',
          superior:
              superiorPerson?.name ??
              (superiorId != null && DemoPersonaPresenter.isSisters
                  ? 'Sister'
                  : superiorName),
          accountant:
              accountantPerson?.name ??
              (accountantId != null && DemoPersonaPresenter.isSisters
                  ? 'Sister'
                  : accountantName),
          superiorPerson: superiorPerson,
          accountantPerson: accountantPerson,
          establishedYear: _year(detail, [
            'opened_on',
            'foundation_date',
            'established_on',
            'establishment_year',
          ]),
          phone: _text(detail, [
            'phone',
            'community_phone',
            'office_phone',
            'landline',
          ]),
          email: _text(detail, ['email', 'official_email']),
          type: _label(
            _text(detail, ['community_type_code', 'type_code', 'type']),
          ),
          recordStatus: _label(
            _text(detail, ['record_status_code', 'status_code', 'status']),
          ),

          // Structured Community Profile identity.
          communityCategory: _text(detail, ['community_category']),
          patronSaintName: _text(detail, ['patron_saint_name']),
          feastMonth: _integer(detail, ['feast_month']),
          feastDay: _integer(detail, ['feast_day']),
          motto: _text(detail, ['motto']),
          missionStatement: _text(detail, ['mission_statement']),
          visionStatement: _text(detail, ['vision_statement']),
          apostolicFocus: _stringList(detail['apostolic_focus']),
          communityValues: _stringList(detail['community_values']),
          foundingStory: _text(detail, ['founding_story']),
          historySummary: _text(detail, ['history_summary']),

          coverImagePath:
              _text(row, ['cover_image_path']) ??
              _text(detail, ['cover_image_path']),
          coverImageUrl: _publicCoverUrl(
            'community-covers',
            _text(row, ['cover_image_path']) ??
                _text(detail, ['cover_image_path']),
          ),
          location: _joinDistinct(detail, [
            'address',
            'location_city',
            'district',
            'state',
          ]),
          residentCount: _integer(row, ['member_count']),
          residents: residents,
          ministries: ministryIds
              .map((id) => ministryNames[id])
              .whereType<String>()
              .toList(),
          ministryRecords: ministryRecords,
          currentMovements: movements,
          history: history,
        );
      }).toList()..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {
      throw const ProvinceDataException();
    }
  }

  @override
  Future<List<MinistryRecord>> fetchMinistries() async {
    try {
      if (_provincialSafeModules) return await _fetchMinistriesSafe();
      final results = await Future.wait([
        _client.rpc('get_provincial_ministries_safe'),
        _client.from('member_ministry_assignments').select(),
        _client.from('v_demo_member_directory').select(),
        _client.from('v_demo_member_public_contacts').select(),
        _client.from('ministries').select(),
        _client
            .from('members')
            .select('id,religious_id,display_name,photo_url'),
      ]);
      final memberPhotos = _memberPhotoLookup(results[5]);
      final members = <String, ProvincePerson>{};
      void indexMember(Map<String, dynamic> row) {
        final person = _person(
          row,
          memberPhotos: memberPhotos,
          contacts: _contactsFor(results[3], _text(row, ['member_id', 'id'])),
        );
        for (final identifier in [
          _text(row, ['member_id', 'id']),
          _text(row, ['religious_id']),
        ]) {
          final key = _memberIdentifier(identifier);
          if (key != null) members[key] = person;
        }
      }

      for (final row in results[5]) {
        indexMember(row);
      }
      for (final row in results[2]) {
        indexMember(row);
      }
      final namedMembers = _membersByUnambiguousName(members.values.toSet());
      return results[0].map((row) {
        final id = _text(row, ['ministry_id', 'id']) ?? '';
        final headId = _rawText(row, ['head_member_id']);
        final headPerson = headId == null
            ? null
            : members[_memberIdentifier(headId)];
        final detail =
            results[4]
                .where(
                  (candidate) => _text(candidate, ['id', 'ministry_id']) == id,
                )
                .firstOrNull ??
            const <String, dynamic>{};
        final coverImagePath =
            _text(row, ['cover_image_path']) ??
            _text(detail, ['cover_image_path']);
        final assignments =
            results[1].where((a) => _text(a, ['ministry_id']) == id).map((a) {
              final rawMemberId = _text(a, ['member_id', 'religious_id']);
              final member = members[_memberIdentifier(rawMemberId)];
              return ProvinceAssignment(
                person:
                    member ??
                    ProvincePerson(
                      id: rawMemberId ?? '',
                      name: rawMemberId == null
                          ? 'Religious'
                          : 'Religious ($rawMemberId)',
                    ),
                role: _label(_text(a, ['responsibility_code'])),
                fromDate: _date(a, ['from_date']),
                toDate: _date(a, ['to_date']),
              );
            }).toList()..sort(
              (a, b) => (b.fromDate ?? DateTime(1)).compareTo(
                a.fromDate ?? DateTime(1),
              ),
            );
        return MinistryRecord(
          id: id,
          name: _text(row, ['ministry_name', 'name']) ?? 'Ministry',
          type: _text(row, ['ministry_type']),
          community: _text(row, ['community_name', 'associated_community']),
          assignments: assignments,
          status: _text(row, ['operational_status']),
          location: _joinDistinct(row, ['location_city', 'district', 'state']),
          headName:
              headPerson?.name ??
              (headId != null && DemoPersonaPresenter.isSisters
                  ? 'Sister'
                  : _text(row, ['head_display_name'])),
          headPerson:
              headPerson ??
              (headId == null
                  ? _memberNamed(
                      _text(row, ['head_display_name']),
                      namedMembers,
                    )
                  : null),
          headRole: _text(row, ['head_role']),
          totalReligious: assignments
              .where((assignment) => assignment.current)
              .length,
          totalStaff: _integerOrNull(row, ['total_staff']),
          totalStudents: _integerOrNull(row, ['total_students']),
          totalBeneficiaries: _integerOrNull(row, ['total_beneficiaries']),
          affiliationAuthority: _text(row, ['affiliation_authority']),
          programsServices: _text(row, ['programs_services']),
          yearEstablished: _integerOrNull(row, ['year_established']),
          phone: _text(row, ['contact_phone']),
          email: _text(row, ['email']),
          website: _text(row, ['website']),
          notes: _text(row, ['notes']),
          motto: _text(detail, ['motto']),
          missionStatement: _text(detail, ['mission_statement']),
          visionStatement: _text(detail, ['vision_statement']),
          patronSaintName: _text(detail, ['patron_saint_name', 'dedication']),
          feastMonth: _integerOrNull(detail, ['feast_month']),
          feastDay: _integerOrNull(detail, ['feast_day']),
          apostolicFocus: _stringList(detail['apostolic_focus']),
          ministryValues: _stringList(detail['ministry_values']),
          foundingStory: _text(detail, ['founding_story']),
          historySummary: _text(detail, ['history_summary']),
          coverImagePath: coverImagePath,
          coverImageUrl: _publicCoverUrl('ministry-covers', coverImagePath),
        );
      }).toList()..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {
      throw const ProvinceDataException();
    }
  }

  @override
  Future<List<FormationMember>> fetchFormation() async {
    try {
      if (_provincialSafeModules) return await _fetchFormationSafe();
      final results = await Future.wait([
        _client.from('v_demo_formation_pipeline').select(),
        _client.from('v_demo_member_directory').select(),
        _client.from('members').select('id,religious_id,photo_url'),
      ]);
      final memberPhotos = _memberPhotoLookup(results[2]);
      final members = {
        for (final row in results[1]) _text(row, ['member_id']): row,
      };
      return results[0].map((r) {
        final detail =
            members[_text(r, ['member_id'])] ?? const <String, dynamic>{};
        return FormationMember(
          person: _person({...detail, ...r}, memberPhotos: memberPhotos),
          stage: _label(_text(r, ['canonical_status_code'])) ?? 'Formation',
          house: _text(r, ['formation_house']),
          fromDate: _date(r, ['from_date']),
        );
      }).toList();
    } catch (_) {
      throw const ProvinceDataException();
    }
  }

  @override
  Future<List<OfficeHolder>> fetchOfficeHolders() async {
    try {
      if (_provincialSafeModules) {
        return await _fetchLeadershipSafe(currentOnly: true);
      }
      final results = await Future.wait([
        _client.from('v_demo_current_office_holders').select(),
        _client.from('v_demo_member_public_contacts').select(),
        _client.from('v_demo_member_directory').select(),
        _client.from('members').select('id,religious_id,photo_url'),
      ]);
      final memberPhotos = _memberPhotoLookup(results[3]);
      final members = {
        for (final row in results[2]) _text(row, ['member_id']): row,
      };
      return results[0].map((r) {
        final detail =
            members[_text(r, ['member_id'])] ?? const <String, dynamic>{};
        return OfficeHolder(
          person: _person(
            {...detail, ...r},
            memberPhotos: memberPhotos,
            contacts: _contactsFor(results[1], _text(r, ['member_id'])),
          ),
          office: _label(_text(r, ['office_type_code'])) ?? 'Office',
          officeCode: _text(r, ['office_type_code']),
          fromDate: _date(r, ['from_date']),
        );
      }).toList();
    } catch (_) {
      throw const ProvinceDataException();
    }
  }

  @override
  Future<List<OfficeHolder>> fetchPastProvincials() async {
    try {
      if (_provincialSafeModules) {
        return await _fetchLeadershipSafe(
          currentOnly: false,
          provincialsOnly: true,
        );
      }
      final results = await Future.wait([
        _client.from('member_office_appointments').select(),
        _client.from('office_types').select(),
        _client.from('v_demo_member_directory').select(),
        _client.from('v_demo_member_public_contacts').select(),
        _client
            .from('members')
            .select('id,religious_id,display_name,photo_url'),
      ]);
      final officeTypes = {
        for (final row in results[1]) _text(row, ['id']): row,
      };
      final memberPhotos = _memberPhotoLookup(results[4]);
      final members = <String, Map<String, dynamic>>{};
      for (final row in results[4]) {
        final id = _text(row, ['id']);
        if (id != null) members[id] = row;
      }
      for (final row in results[2]) {
        final id = _text(row, ['member_id', 'id']);
        if (id != null) members[id] = row;
      }
      final records = <OfficeHolder>[];
      for (final row in results[0]) {
        final officeType =
            officeTypes[_text(row, ['office_type_id'])] ??
            const <String, dynamic>{};
        final officeCode =
            _text(officeType, ['code', 'office_type_code']) ??
            _text(row, ['office_type_code', 'office_code']);
        if (officeCode?.trim().toLowerCase() != 'provincial') continue;
        final toDate = _date(row, ['to_date', 'end_date']);
        if (toDate == null) continue;
        final memberId = _text(row, ['member_id']);
        final detail = members[memberId] ?? const <String, dynamic>{};
        records.add(
          OfficeHolder(
            person: _person(
              {...detail, ...row},
              memberPhotos: memberPhotos,
              contacts: _contactsFor(results[3], memberId),
            ),
            office: 'Provincial',
            officeCode: 'provincial',
            fromDate: _date(row, ['from_date', 'start_date']),
            toDate: toDate,
          ),
        );
      }
      return records..sort(
        (a, b) => (b.toDate ?? DateTime(1)).compareTo(a.toDate ?? DateTime(1)),
      );
    } catch (_) {
      throw const ProvinceDataException();
    }
  }

  @override
  Future<List<EligibilityRole>> fetchEligibilityRoles() async {
    try {
      final results = await Future.wait([
        _client
            .from('v_office_eligibility')
            .select('office_type_code,office_name')
            .range(0, 999),
        _client
            .from('v_office_eligibility')
            .select('office_type_code,office_name')
            .range(1000, 1999),
        _client
            .from('v_responsibility_eligibility')
            .select('responsibility_code,responsibility_name')
            .range(0, 999),
        _client
            .from('v_responsibility_eligibility')
            .select('responsibility_code,responsibility_name')
            .range(1000, 1999),
      ]);
      final roles = <String, EligibilityRole>{};
      for (final row in [...results[0], ...results[1]]) {
        final code = _text(row, ['office_type_code']);
        if (code != null) {
          roles['office:$code'] = EligibilityRole(
            code: code,
            name: _text(row, ['office_name']) ?? _label(code)!,
            office: true,
          );
        }
      }
      for (final row in [...results[2], ...results[3]]) {
        final code = _text(row, ['responsibility_code']);
        if (code != null) {
          roles['responsibility:$code'] = EligibilityRole(
            code: code,
            name: _text(row, ['responsibility_name']) ?? _label(code)!,
            office: false,
          );
        }
      }
      return roles.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {
      throw const ProvinceDataException();
    }
  }

  @override
  Future<List<EligibilityRecord>> fetchEligibility(
    String roleCode, {
    required bool office,
  }) async {
    try {
      final view = office
          ? 'v_office_eligibility'
          : 'v_responsibility_eligibility';
      final field = office ? 'office_type_code' : 'responsibility_code';
      final results = await Future.wait([
        _client.from(view).select().eq(field, roleCode),
        _client.from('v_demo_member_directory').select(),
        _client.from('members').select('id,religious_id,photo_url'),
      ]);
      final memberPhotos = _memberPhotoLookup(results[2]);
      final members = {
        for (final row in results[1]) _text(row, ['member_id']): row,
      };
      return results[0].map((row) {
        final memberId = _text(row, ['member_id']) ?? '';
        final detail =
            members[_text(row, ['member_id'])] ?? const <String, dynamic>{};
        final indicators = <String>[
          if (_text(row, ['ministry_experience_years']) case final years?)
            'Ministry experience: $years years',
          if (_text(row, ['teaching_master_subjects']) case final subjects?)
            'Teaching master’s: $subjects',
        ];
        return EligibilityRecord(
          person: ProvincePerson(
            id: memberId,
            name: _text(row, ['display_name']) ?? 'Religious',
            role: DemoPersonaPresenter.memberTitle(
              memberId,
              _ecclesiasticalTitle(
                    _text(detail, ['ecclesiastical_title_code']),
                  ) ??
                  '',
            ),
            photoUrl: _photoFor({...detail, ...row}, memberPhotos),
          ),
          role: office
              ? (_text(row, ['office_name']) ?? _label(roleCode)!)
              : (_text(row, ['responsibility_name']) ?? _label(roleCode)!),
          status: _text(row, ['eligibility_status']) ?? 'NOT EVALUATED',
          reason: _text(row, ['eligibility_reason']),
          indicators: [
            if (_text(detail, ['community_name']) case final community?)
              'Community: $community',
            ...indicators,
          ],
        );
      }).toList()..sort((a, b) => a.person.name.compareTo(b.person.name));
    } catch (_) {
      throw const ProvinceDataException();
    }
  }

  @override
  Future<List<AppointmentCompliance>> fetchAppointmentCompliance() async {
    try {
      final results = await Future.wait([
        _client.from('v_current_office_compliance').select(),
        _client.from('v_current_appointment_compliance').select(),
        _client.from('members').select('id,religious_id,photo_url'),
      ]);
      final ids = {
        for (final row in results[2])
          _normalizeReligiousId(_text(row, ['religious_id'])): _text(row, [
            'id',
          ]),
      };
      final photos = _memberPhotoLookup(results[2]);
      return [...results[0], ...results[1]]
          .map(
            (row) => AppointmentCompliance(
              person: ProvincePerson(
                id:
                    ids[_normalizeReligiousId(_text(row, ['religious_id']))] ??
                    '',
                name: _text(row, ['display_name']) ?? 'Religious',
                photoUrl: _photoFor(row, photos),
              ),
              role:
                  _text(row, ['office_name']) ??
                  _label(_text(row, ['responsibility_code'])) ??
                  'Appointment',
              status: _text(row, ['compliance_status']) ?? 'NOT EVALUATED',
              eligibilityStatus: _text(row, ['eligibility_status']),
              reason: _text(row, ['eligibility_reason']),
              fromDate: _date(row, ['from_date']),
            ),
          )
          .toList();
    } catch (_) {
      throw const ProvinceDataException();
    }
  }

  @override
  Future<List<CalendarEntry>> fetchCalendarEntries() async {
    try {
      final officeRows = await _client
          .from('v_demo_current_office_holders')
          .select();
      final teamIds = CalendarEntryMapper.leadershipMemberIds(officeRows);
      final results = await Future.wait([
        _client.from('v_demo_member_attention_events').select(),
        _client.from('communities').select(),
        if (teamIds.isEmpty)
          Future.value(<Map<String, dynamic>>[])
        else
          _client
              .from('v_demo_member_directory')
              .select('member_id,display_name,date_of_birth')
              .inFilter('member_id', teamIds.toList()),
        _client
            .from('community_events')
            .select('*,communities(name)')
            .neq('status', 'cancelled'),
      ]);
      final entries = CalendarEntryMapper.map(
        officeRows: officeRows,
        attentionRows: results[0],
        communityRows: results[1],
        memberRows: results[2],
        calendarYear: DateTime.now().year,
      );
      entries.addAll(
        results[3].map(
          (row) => CalendarEntry(
            id: _text(row, ['id']),
            title: _text(row, ['title']) ?? 'Community event',
            date: DateTime.parse(row['starts_at'].toString()).toLocal(),
            endDate: DateTime.tryParse(
              row['ends_at']?.toString() ?? '',
            )?.toLocal(),
            category: 'Community',
            eventType: _text(row, ['event_type']),
            relatedEntityType: 'community',
            relatedEntityId: _text(row, ['community_id']),
            location: _text(row, ['venue']),
            priority: _text(row, ['status']),
          ),
        ),
      );
      entries.sort((a, b) => a.date.compareTo(b.date));
      return entries;
    } catch (_) {
      throw const ProvinceDataException();
    }
  }

  // Kept as a runtime switch so the former readers remain available as a
  // rollback path without participating in the active Provincial flow.
  bool get _provincialSafeModules => true;

  Future<List<CommunityRecord>> _fetchCommunitiesSafe() async {
    final results = await Future.wait<dynamic>([
      Future<dynamic>.value(_client.rpc('get_provincial_communities_safe')),
      Future<dynamic>.value(
        _client
            .from('v_community_lifecycle')
            .select()
            .order('effective_date')
            .order('event_type_code'),
      ),
    ]);
    final rows = List<Map<String, dynamic>>.from(results[0]);
    final lifecycleRows = List<Map<String, dynamic>>.from(results[1]);
    if (kDebugMode) {
      debugPrint('[ProvincialCommunitiesRPC] rows=${rows.length}');
    }
    return rows.map((row) {
      final residentRows = List<Map<String, dynamic>>.from(
        row['residents'] as List? ?? const [],
      );
      final residents = residentRows.map((item) {
        final ministry = [
          _label(_text(item, ['ministry_role'])),
          _text(item, ['ministry_name']),
        ].whereType<String>().join(' · ');
        return _person(
          item,
          ministryAssignment: ministry.isEmpty ? null : ministry,
          memberStatus: _label(
            _text(item, ['canonical_status', 'member_status']),
          ),
        ).copyWith(role: _label(_text(item, ['community_role'])));
      }).toList();
      final history =
          List<Map<String, dynamic>>.from(
                row['community_history'] as List? ?? const [],
              )
              .map(
                (item) => ProvinceAssignment(
                  person: _person(item),
                  role: communityResponsibilityLabel(
                    _text(item, ['responsibility_code']),
                  ),
                  fromDate: _date(item, ['from_date']),
                  toDate: _date(item, ['to_date']),
                ),
              )
              .toList();
      ProvincePerson? leader(String idKey, String nameKey, String titleKey) {
        final id = _rawText(row, [idKey]);
        if (id == null) return null;
        return _person({
          'member_id': id,
          'display_name': _rawText(row, [nameKey]),
          'ecclesiastical_title_code': _rawText(row, [titleKey]),
        });
      }

      final superior = leader(
        'superior_member_id',
        'superior_display_name',
        'superior_title_code',
      );
      final accountant = leader(
        'accountant_member_id',
        'accountant_display_name',
        'accountant_title_code',
      );
      final linked = List<Map<String, dynamic>>.from(
        row['linked_ministries'] as List? ?? const [],
      );
      final cover = _text(row, ['cover_image_path']);
      return CommunityRecord(
        id: _text(row, ['community_id', 'id']) ?? '',
        code: _text(row, ['community_code', 'code']),
        name: _text(row, ['community_name', 'name']) ?? 'Community',
        residentCount: _integer(row, ['resident_count']),
        superior: superior?.name,
        accountant: accountant?.name,
        superiorPerson: superior,
        accountantPerson: accountant,
        establishedYear: _year(row, ['opened_on']),
        type: _label(_text(row, ['community_type'])),
        communityCategory: _text(row, ['community_category']),
        patronSaintName: _text(row, ['patron_saint_name']),
        feastMonth: _integerOrNull(row, ['feast_month']),
        feastDay: _integerOrNull(row, ['feast_day']),
        motto: _text(row, ['motto']),
        missionStatement: _text(row, ['mission_statement']),
        visionStatement: _text(row, ['vision_statement']),
        apostolicFocus: _stringList(row['apostolic_focus']),
        communityValues: _stringList(row['community_values']),
        foundingStory: _text(row, ['founding_story']),
        historySummary: _text(row, ['history_summary']),
        coverImagePath: cover,
        coverImageUrl: _publicCoverUrl('community-covers', cover),
        location: _joinDistinct(row, ['city', 'district', 'state', 'country']),
        residents: residents,
        ministries: linked
            .map((item) => _text(item, ['ministry_name']))
            .whereType<String>()
            .toList(),
        ministryRecords: linked
            .map(
              (item) => MinistryRecord(
                id: _text(item, ['ministry_id']) ?? '',
                name: _text(item, ['ministry_name']) ?? 'Ministry',
                type: _text(item, ['ministry_type']),
                community: _text(item, ['associated_community']),
                status: _text(item, ['operational_status']),
                location: _joinDistinct(item, [
                  'location_city',
                  'district',
                  'state',
                ]),
                totalReligious: _integerOrNull(item, [
                  'total_religious_working',
                ]),
              ),
            )
            .toList(),
        lifecycleEvents: lifecycleRows
            .where(
              (item) =>
                  _text(item, ['community_id']) ==
                  _text(row, ['community_id', 'id']),
            )
            .map(_communityLifecycleEvent)
            .toList(),
        history: history,
      );
    }).toList();
  }

  CommunityLifecycleEvent _communityLifecycleEvent(Map<String, dynamic> row) =>
      CommunityLifecycleEvent(
        typeCode: _text(row, ['event_type_code']) ?? 'STATUS_CHANGED',
        effectiveDate: _date(row, ['effective_date']) ?? DateTime(1),
        datePrecisionCode: _text(row, ['date_precision_code']) ?? 'DAY',
      );

  Future<List<MinistryRecord>> _fetchMinistriesSafe() async {
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc('get_provincial_ministries_safe'),
    );
    if (kDebugMode) {
      debugPrint('[ProvincialMinistriesRPC] rows=${rows.length}');
    }
    return rows.map((row) {
      final assignments =
          List<Map<String, dynamic>>.from(
                row['assignments'] as List? ?? const [],
              )
              .map(
                (item) => ProvinceAssignment(
                  person: _person(item),
                  role: _label(_text(item, ['responsibility_code'])),
                  fromDate: _date(item, ['from_date']),
                  toDate: _date(item, ['to_date']),
                ),
              )
              .toList();
      final headId = _rawText(row, ['head_member_id']);
      final head = headId == null
          ? null
          : _person({
              'member_id': headId,
              'display_name': _rawText(row, ['head_display_name']),
              'ecclesiastical_title_code': _rawText(row, ['head_title_code']),
            });
      final cover = _text(row, ['cover_image_path']);
      return MinistryRecord(
        id: _text(row, ['ministry_id']) ?? '',
        name: _text(row, ['ministry_name', 'name']) ?? 'Ministry',
        type: _text(row, ['ministry_type']),
        community: _text(row, ['associated_community', 'community_name']),
        assignments: assignments,
        status: _text(row, ['operational_status']),
        location: _joinDistinct(row, ['location_city', 'district', 'state']),
        headName: head?.name,
        headPerson: head,
        headRole: _label(_text(row, ['head_role'])),
        totalReligious: _integerOrNull(row, ['total_religious_working']),
        totalStaff: _integerOrNull(row, ['total_staff']),
        totalStudents: _integerOrNull(row, ['total_students']),
        totalBeneficiaries: _integerOrNull(row, ['total_beneficiaries']),
        affiliationAuthority: _text(row, ['affiliation_authority']),
        programsServices: _text(row, ['programs_services']),
        yearEstablished: _integerOrNull(row, ['year_established']),
        phone: _text(row, ['contact_phone']),
        email: _text(row, ['email']),
        website: _text(row, ['website']),
        notes: _text(row, ['notes']),
        motto: _text(row, ['motto']),
        missionStatement: _text(row, ['mission_statement']),
        visionStatement: _text(row, ['vision_statement']),
        patronSaintName: _text(row, ['patron_saint_name']),
        feastMonth: _integerOrNull(row, ['feast_month']),
        feastDay: _integerOrNull(row, ['feast_day']),
        apostolicFocus: _stringList(row['apostolic_focus']),
        ministryValues: _stringList(row['ministry_values']),
        foundingStory: _text(row, ['founding_story']),
        historySummary: _text(row, ['history_summary']),
        coverImagePath: cover,
        coverImageUrl: _publicCoverUrl('ministry-covers', cover),
      );
    }).toList();
  }

  Future<List<FormationMember>> _fetchFormationSafe() async {
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc('get_provincial_formation_safe'),
    );
    if (kDebugMode) {
      debugPrint('[ProvincialFormationRPC] rows=${rows.length}');
    }
    return rows
        .map(
          (row) => FormationMember(
            person: _person(row),
            stage: _label(_text(row, ['canonical_status_code'])) ?? 'Formation',
            house: _text(row, ['formation_house']),
            fromDate: _date(row, ['from_date']),
          ),
        )
        .toList();
  }

  Future<List<OfficeHolder>> _fetchLeadershipSafe({
    required bool currentOnly,
    bool provincialsOnly = false,
  }) async {
    final rows = List<Map<String, dynamic>>.from(
      await _client.rpc('get_provincial_leadership_safe'),
    );
    final filtered = rows.where((row) {
      if (currentOnly && row['current'] != true) return false;
      if (provincialsOnly &&
          _text(row, ['office_type_code'])?.toLowerCase() != 'provincial') {
        return false;
      }
      return true;
    }).toList();
    if (kDebugMode && currentOnly) {
      debugPrint('[ProvincialLeadershipRPC] current=${filtered.length}');
    }
    return filtered
        .map(
          (row) => OfficeHolder(
            person: _person({
              ...row,
              'ecclesiastical_title_code': row['canonical_title'],
            }),
            office:
                _text(row, ['office_name']) ??
                _label(_text(row, ['office_type_code'])) ??
                'Office',
            officeCode: _text(row, ['office_type_code']),
            fromDate: _date(row, ['from_date']),
            toDate: _date(row, ['to_date']),
          ),
        )
        .toList();
  }

  static ProvincePerson _person(
    Map<String, dynamic> row, {
    Map<String, String?> memberPhotos = const {},
    _MemberContacts contacts = const _MemberContacts(),
    String? ministryAssignment,
    String? memberStatus,
  }) {
    final memberId = _text(row, ['member_id', 'id']) ?? '';
    final presentedPerson = DemoPersonaPresenter.presentPerson(
      memberId: memberId,
      canonicalDisplayName:
          _rawText(row, ['display_name', 'full_name']) ?? 'Religious',
      canonicalTitle: _ecclesiasticalTitle(
        _rawText(row, ['ecclesiastical_title_code']),
      ),
      canonicalPhotoUrl: _photoFor(row, memberPhotos),
    );
    return ProvincePerson(
      id: memberId,
      name: composeEcclesiasticalName(
        displayName: presentedPerson.displayName,
        title: presentedPerson.title,
      ),
      photoUrl: presentedPerson.photoUrl,
      phone: contacts.phone,
      whatsApp: contacts.whatsApp,
      email: contacts.email,
      ministryAssignment: ministryAssignment,
      memberStatus: memberStatus,
    );
  }

  @visibleForTesting
  static MinistryRecord mapOperationalMinistry(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> assignmentRows,
    Map<String, ProvincePerson> members,
    Map<String, ProvincePerson?> namedMembers, {
    Map<String, dynamic>? detail,
    required String? Function(String bucket, String? path) publicUrl,
  }) {
    final id = _text(row, ['ministry_id', 'id']) ?? '';
    final assignments = assignmentRows
        .where((assignment) => _text(assignment, ['ministry_id']) == id)
        .map(
          (assignment) => ProvinceAssignment(
            person:
                members[_text(assignment, ['member_id'])] ??
                const ProvincePerson(id: '', name: 'Religious'),
            role: _label(_text(assignment, ['responsibility_code'])),
            fromDate: _date(assignment, ['from_date']),
            toDate: _date(assignment, ['to_date']),
          ),
        )
        .toList();
    final coverImagePath =
        _text(row, ['cover_image_path']) ??
        (detail == null ? null : _text(detail, ['cover_image_path']));
    final headAssignment = assignmentRows
        .where(
          (assignment) =>
              _text(assignment, ['ministry_id']) == id &&
              _date(assignment, ['to_date']) == null &&
              const {
                'principal',
                'parish_priest',
                'pastor',
                'director',
                'head',
                'novice_master',
                'formation_director',
                'vocation_promoter',
              }.contains(
                _rawText(assignment, ['responsibility_code'])?.toLowerCase(),
              ),
        )
        .firstOrNull;
    final headId =
        _rawText(row, ['head_member_id']) ??
        (headAssignment == null
            ? null
            : _rawText(headAssignment, ['member_id']));
    final headPerson = headId == null
        ? _memberNamed(_text(row, ['head_display_name']), namedMembers)
        : members[headId];
    return MinistryRecord(
      id: id,
      name: _text(row, ['ministry_name', 'name']) ?? 'Ministry',
      type: _text(row, ['ministry_type']),
      community: _text(row, ['associated_community']),
      assignments: assignments,
      status: _text(row, ['operational_status']),
      location: _joinDistinct(row, ['location_city', 'district', 'state']),
      headName:
          headPerson?.name ??
          (headId != null && DemoPersonaPresenter.isSisters
              ? 'Sister'
              : _text(row, ['head_display_name'])),
      headPerson: headPerson,
      headRole: _text(row, ['head_role']),
      totalReligious: _integerOrNull(row, ['total_religious_working']),
      totalStaff: _integerOrNull(row, ['total_staff']),
      totalStudents: _integerOrNull(row, ['total_students']),
      totalBeneficiaries: _integerOrNull(row, ['total_beneficiaries']),
      yearEstablished: _integerOrNull(row, ['year_established']),
      phone: _text(row, ['contact_phone']),
      email: _text(row, ['email']),
      website: _text(row, ['website']),
      coverImagePath: coverImagePath,
      coverImageUrl: publicUrl('ministry-covers', coverImagePath),
    );
  }

  String? _publicCoverUrl(String bucket, String? path) {
    return publicStorageImageUrl(_client, bucket, path);
  }

  @visibleForTesting
  static ProvincePerson? selectCurrentLeader(
    List<ProvinceAssignment> assignments,
    List<String> roles,
  ) {
    final normalized = roles.map((role) => role.toLowerCase()).toSet();
    for (final assignment in assignments.where((a) => a.current)) {
      if (normalized.contains(assignment.role?.toLowerCase())) {
        return assignment.person;
      }
    }
    return null;
  }

  static String? _ecclesiasticalTitle(String? code) =>
      switch (code?.toLowerCase()) {
        'fr' || 'father' || 'priest' => 'Fr.',
        'bro' || 'brother' => 'Bro.',
        'dcn' || 'deacon' => 'Dcn.',
        _ => null,
      };

  static _MemberContacts _contactsFor(
    List<Map<String, dynamic>> rows,
    String? memberId,
  ) {
    if (memberId == null) return const _MemberContacts();
    final match = rows
        .where((row) => _text(row, ['member_id']) == memberId)
        .firstOrNull;
    if (match == null) return const _MemberContacts();
    return _MemberContacts(
      phone: _text(match, ['mobile']),
      whatsApp: _text(match, ['whatsapp']),
      email: _text(match, ['official_email']),
    );
  }

  static String? _text(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        final memberId = _structuredMemberId(row, key);
        if (key.contains('photo')) {
          return DemoPersonaPresenter.memberPhoto(memberId, value);
        }
        if (memberId != null &&
            (key.contains('name') || key.contains('title'))) {
          return DemoPersonaPresenter.memberName(memberId, value);
        }
        return value;
      }
    }
    return null;
  }

  static String? _rawText(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _structuredMemberId(Map<String, dynamic> row, String field) {
    Object? value;
    if (field.contains('superior')) {
      value = row['current_superior_member_id'] ?? row['superior_member_id'];
    } else if (field.contains('accountant') || field.contains('bursar')) {
      value =
          row['current_accountant_member_id'] ?? row['accountant_member_id'];
    } else if (field.contains('head')) {
      value = row['head_member_id'];
    } else {
      value = row['member_id'];
    }
    final id = value?.toString().trim();
    return id == null || id.isEmpty ? null : id;
  }

  static Map<String, String?> _memberPhotoLookup(
    List<Map<String, dynamic>> rows,
  ) {
    final photos = <String, String?>{};
    for (final row in rows) {
      final photo = _text(row, ['photo_url']);
      final memberId = _normalizeMemberId(_text(row, ['id', 'member_id']));
      final religiousId = _normalizeReligiousId(_text(row, ['religious_id']));
      if (memberId != null) photos['member:$memberId'] = photo;
      if (religiousId != null) photos['religious:$religiousId'] = photo;
    }
    return photos;
  }

  static String? _photoFor(
    Map<String, dynamic> row,
    Map<String, String?> memberPhotos,
  ) {
    final memberId = _normalizeMemberId(_text(row, ['member_id', 'id']));
    if (memberId != null && memberPhotos.containsKey('member:$memberId')) {
      return memberPhotos['member:$memberId'];
    }
    final religiousId = _normalizeReligiousId(_text(row, ['religious_id']));
    if (religiousId != null &&
        memberPhotos.containsKey('religious:$religiousId')) {
      return memberPhotos['religious:$religiousId'];
    }
    return _text(row, ['photo_url']);
  }

  static String? _normalizeReligiousId(String? value) {
    final normalized = value?.trim().toUpperCase().replaceAll(
      RegExp('[^A-Z0-9]'),
      '',
    );
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String? _normalizeMemberId(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String? _memberIdentifier(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static Map<String, ProvincePerson?> _membersByUnambiguousName(
    Iterable<ProvincePerson> members,
  ) {
    final matches = <String, ProvincePerson?>{};
    for (final member in members) {
      for (final entry in {
        'full:${_normalizePersonName(member.name, stripTitle: false)}',
        'bare:${_normalizePersonName(member.name, stripTitle: true)}',
      }) {
        if (entry.endsWith(':null')) continue;
        matches[entry] = matches.containsKey(entry) ? null : member;
      }
    }
    return matches;
  }

  static ProvincePerson? _memberNamed(
    String? name,
    Map<String, ProvincePerson?> members,
  ) {
    final full = _normalizePersonName(name, stripTitle: false);
    if (full == null) return null;
    final exact = members['full:$full'];
    if (exact != null) return exact;
    final bare = _normalizePersonName(name, stripTitle: true);
    return bare == null ? null : members['bare:$bare'];
  }

  static String? _normalizePersonName(
    String? value, {
    required bool stripTitle,
  }) {
    var normalized = value?.trim().toLowerCase();
    if (stripTitle) {
      normalized = normalized?.replaceFirst(
        RegExp(r'^(fr|bro|br|dcn|rev)\.?\s+'),
        '',
      );
    }
    normalized = normalized?.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static int _integer(Map<String, dynamic> row, List<String> keys) =>
      int.tryParse(_text(row, keys) ?? '') ?? 0;
  static int? _integerOrNull(Map<String, dynamic> row, List<String> keys) =>
      int.tryParse(_text(row, keys) ?? '');
  static int? _year(Map<String, dynamic> row, List<String> keys) {
    final value = _text(row, keys);
    if (value == null) return null;
    return int.tryParse(value) ?? DateTime.tryParse(value)?.year;
  }

  static String? _joinDistinct(Map<String, dynamic> row, List<String> keys) {
    final values = keys
        .map((key) => _text(row, [key]))
        .whereType<String>()
        .toSet();
    return values.isEmpty ? null : values.join(', ');
  }

  static DateTime? _date(Map<String, dynamic> row, List<String> keys) =>
      DateTime.tryParse(_text(row, keys) ?? '');
  static String? _label(String? value) => value
      ?.split(RegExp(r'[_\-\s]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
      .join(' ');

  static List<String> _stringList(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      return value
          .map((item) => item?.toString().trim())
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }
}

class _MemberContacts {
  const _MemberContacts({this.phone, this.whatsApp, this.email});
  final String? phone;
  final String? whatsApp;
  final String? email;
}
