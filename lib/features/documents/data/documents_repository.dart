import '../models/province_document.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class DocumentsRepository {
  Future<List<ProvinceDocument>> fetchDocuments();
}

class DocumentsException implements Exception {
  const DocumentsException();
}

class DemoDocumentsRepository implements DocumentsRepository {
  const DemoDocumentsRepository();

  @override
  Future<List<ProvinceDocument>> fetchDocuments() async => demoDocuments;
}

class SupabaseDocumentsRepository implements DocumentsRepository {
  const SupabaseDocumentsRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<ProvinceDocument>> fetchDocuments() async {
    try {
      final results = await Future.wait([
        _client
            .from('province_documents')
            .select()
            .order('document_date', ascending: false),
        _client
            .from('community_meetings')
            .select('*,communities(name)')
            .order('meeting_date', ascending: false),
      ]);
      final documents = <ProvinceDocument>[
        ...results[0].map(_mapDocument),
        ...results[1].map(_mapMeeting),
      ]..sort((a, b) => b.documentDate.compareTo(a.documentDate));
      return documents;
    } catch (_) {
      throw const DocumentsException();
    }
  }

  ProvinceDocument _mapMeeting(Map<String, dynamic> row) {
    final community = row['communities'] as Map<String, dynamic>?;
    final date = DateTime.parse(row['meeting_date'].toString());
    return ProvinceDocument(
      id: 'community-meeting-${row['id']}',
      title: row['title']?.toString() ?? 'Community Meeting Minutes',
      category: DocumentCategory.community,
      documentType: 'Meeting Minutes',
      documentDate: date,
      description: [
        row['summary'],
        if (row['decisions'] != null) 'Decisions: ${row['decisions']}',
        if (row['action_items'] != null) 'Action items: ${row['action_items']}',
      ].whereType<Object>().join('\n\n'),
      relatedEntityType: 'community',
      relatedEntityId: row['community_id']?.toString(),
      relatedEntityName: community?['name']?.toString(),
      visibility: 'Community Leadership',
      uploadedBy: row['created_by_auth_user_id']?.toString(),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? date,
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
    );
  }

  ProvinceDocument _mapDocument(Map<String, dynamic> row) {
    final categoryCode = row['category_code']?.toString();
    final category = DocumentCategory.values.firstWhere(
      (value) => value.code == categoryCode,
      orElse: () => DocumentCategory.provincialAdministration,
    );
    final storagePath = row['storage_path']?.toString();
    return ProvinceDocument(
      id: row['id'].toString(),
      documentCode: row['document_code']?.toString(),
      title: row['title']?.toString() ?? 'Document',
      category: category,
      documentType: row['document_type']?.toString() ?? 'Document',
      documentDate:
          DateTime.tryParse(row['document_date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      description: row['description']?.toString() ?? '',
      relatedEntityType: row['related_entity_type']?.toString(),
      relatedEntityId: row['related_entity_id']?.toString(),
      relatedEntityName: row['related_entity_name']?.toString(),
      visibility: _visibilityLabel(row['visibility_code']?.toString()),
      fileName: row['file_name']?.toString(),
      storagePath: storagePath,
      fileExtension: row['file_extension']?.toString() ?? 'pdf',
      fileSizeBytes: row['file_size_bytes'] as int?,
      uploadedBy: row['uploaded_by']?.toString(),
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
    );
  }

  String _visibilityLabel(String? code) => switch (code) {
    'province_members' => 'Province Members',
    'council' => 'Council',
    'community_leadership' => 'Community Leadership',
    'restricted' => 'Restricted',
    _ => 'Provincial Team',
  };
}

final demoDocuments = <ProvinceDocument>[
  _doc(
    1,
    'Annual Province Report 2025-26',
    DocumentCategory.provincialAdministration,
    'Annual Report',
    DateTime(2026, 6, 30),
    'Province-wide review of membership, communities, ministries, formation, governance and priorities.',
    file: 'annual_province_report_2025_26.pdf',
  ),
  _doc(
    2,
    'Provincial Circular - August 2026',
    DocumentCategory.provincialAdministration,
    'Circular',
    DateTime(2026, 8, 18),
    'Message, appointments, meetings, visitation and formation reminders for the demo Province.',
    file: 'provincial_circular_august_2026.pdf',
  ),
  _doc(
    3,
    'Province Directory 2026',
    DocumentCategory.provincialAdministration,
    'Directory',
    DateTime(2026, 1, 15),
    'Demonstration directory index for Province communities, ministries and offices.',
  ),
  _doc(
    4,
    'Provincial Administration Review 2025-26',
    DocumentCategory.provincialAdministration,
    'Review',
    DateTime(2026, 7, 10),
    'Administrative review of coordination, reporting and institutional records.',
  ),
  _doc(
    5,
    'Provincial Chapter Acts 2024',
    DocumentCategory.governance,
    'Chapter Acts',
    DateTime(2024, 11, 30),
    'Fictional chapter acts retained as institutional governance memory.',
    visibility: 'Province Members',
  ),
  _doc(
    6,
    'Chapter Implementation Review 2025',
    DocumentCategory.governance,
    'Implementation Review',
    DateTime(2025, 12, 10),
    'Review of demonstration chapter commitments and implementation milestones.',
  ),
  _doc(
    7,
    'Provincial Council Decisions - July 2026',
    DocumentCategory.governance,
    'Council Decisions',
    DateTime(2026, 7, 28),
    'Decision register from the fictional July Provincial Council meeting.',
    visibility: 'Council',
  ),
  _doc(
    8,
    'Budakata Mission Community Annual Report 2025-26',
    DocumentCategory.community,
    'Community Report',
    DateTime(2026, 6, 25),
    'Annual account of community life, mission activities, opportunities and priorities.',
    entityType: 'community',
    entityId: 'COM013',
    entityName: 'Budakata Mission Community',
    file: 'budakata_community_report_2025_26.pdf',
  ),
  _doc(
    9,
    'Morning Star Community Annual Report 2025-26',
    DocumentCategory.community,
    'Community Report',
    DateTime(2026, 6, 22),
    'Demonstration annual report for Morning Star Community.',
    entityType: 'community',
    entityId: 'COM006',
    entityName: 'Morning Star Community',
  ),
  _doc(
    10,
    'Mary Immaculate Novitiate Community Report 2025-26',
    DocumentCategory.community,
    'Community Report',
    DateTime(2026, 6, 20),
    'Community context and activities supporting the Province novitiate.',
    entityType: 'community',
    entityName: 'Mary Immaculate Novitiate',
  ),
  _doc(
    11,
    'Budakata School Annual Report 2025-26',
    DocumentCategory.ministry,
    'Ministry Report',
    DateTime(2026, 6, 28),
    'Values-based education, student development and community engagement in the demo year.',
    entityType: 'ministry',
    entityId: 'MIN015',
    entityName: 'Budakata School',
    file: 'budakata_school_report_2025_26.pdf',
  ),
  _doc(
    12,
    'Sacred Heart Parish Pastoral Report 2025',
    DocumentCategory.ministry,
    'Pastoral Report',
    DateTime(2025, 12, 31),
    'Pastoral activities, sacramental life and community outreach summary.',
    entityType: 'ministry',
    entityName: 'Sacred Heart Parish',
  ),
  _doc(
    13,
    'St. Joseph Health Centre Activity Report 2025-26',
    DocumentCategory.ministry,
    'Activity Report',
    DateTime(2026, 6, 26),
    'Primary care, preventive health and outreach activity summary.',
    entityType: 'ministry',
    entityName: 'St. Joseph Health Centre',
  ),
  _doc(
    14,
    'Morning Star School Academic Report 2025-26',
    DocumentCategory.ministry,
    'Academic Report',
    DateTime(2026, 6, 24),
    'Academic programme and student-development demonstration report.',
    entityType: 'ministry',
    entityId: 'MIN007',
    entityName: 'Morning Star School',
  ),
  _doc(
    15,
    'Province Formation Annual Report 2025-26',
    DocumentCategory.formation,
    'Formation Report',
    DateTime(2026, 7, 5),
    'Overview of formation stages, staff accompaniment and priorities.',
    entityType: 'formation',
    entityName: 'Province Formation',
    file: 'province_formation_report_2025_26.pdf',
  ),
  _doc(
    16,
    'Novitiate Formation Report 2025-26',
    DocumentCategory.formation,
    'Formation Report',
    DateTime(2026, 6, 18),
    'Demonstration review of novitiate formation and accompaniment.',
    entityType: 'formation',
    entityName: 'Mary Immaculate Novitiate',
  ),
  _doc(
    17,
    'Scholasticate Formation Evaluation 2025-26',
    DocumentCategory.formation,
    'Evaluation',
    DateTime(2026, 6, 17),
    'Institutional formation evaluation for the scholasticate year.',
    entityType: 'formation',
    entityName: 'St. Antony Scholasticate',
  ),
  _doc(
    18,
    'Vocation Promotion Annual Report 2025-26',
    DocumentCategory.formation,
    'Annual Report',
    DateTime(2026, 6, 16),
    'Vocation accompaniment activities and demonstration priorities.',
    entityType: 'formation',
    entityName: 'Province Vocation Promotion',
  ),
  _doc(
    19,
    'Province Financial Summary 2025-26',
    DocumentCategory.finance,
    'Financial Summary',
    DateTime(2026, 7, 31),
    'Illustrative financial headings and demonstration figures; not audited statements.',
    visibility: 'Provincial Team',
    file: 'province_financial_summary_2025_26.pdf',
  ),
  _doc(
    20,
    'Ministry Audit Summary 2025-26',
    DocumentCategory.finance,
    'Audit Summary',
    DateTime(2026, 7, 20),
    'Fictional high-level ministry control observations; not an audit opinion.',
    visibility: 'Provincial Team',
  ),
  _doc(
    21,
    'Personnel & Appointment Circular - August 2026',
    DocumentCategory.personnel,
    'Personnel Circular',
    DateTime(2026, 8, 19),
    'Benign demonstration personnel movements and appointment communication.',
    visibility: 'Province Members',
    file: 'personnel_appointment_circular_august_2026.pdf',
  ),
  _doc(
    22,
    'Annual Personnel Movement Report 2025-26',
    DocumentCategory.personnel,
    'Personnel Report',
    DateTime(2026, 7, 8),
    'Summary of ordinary fictional assignment movements during the demo year.',
    visibility: 'Provincial Team',
  ),
  _doc(
    23,
    'Provincial Council Minutes - 20 August 2026',
    DocumentCategory.meetings,
    'Meeting Minutes',
    DateTime(2026, 8, 20),
    'Agenda, matters discussed, demo decisions and assigned action items.',
    visibility: 'Council',
    file: 'provincial_council_minutes_2026_08_20.pdf',
  ),
  _doc(
    24,
    'Education Commission Minutes - July 2026',
    DocumentCategory.meetings,
    'Meeting Minutes',
    DateTime(2026, 7, 14),
    'Demonstration education commission discussion and actions.',
  ),
  _doc(
    25,
    'Child Safeguarding Policy 2026',
    DocumentCategory.policies,
    'Policy',
    DateTime(2026, 8, 1),
    'General demonstration guidance on conduct, reporting, response, training and records.',
    visibility: 'Province Members',
    file: 'child_safeguarding_policy_2026.pdf',
  ),
  _doc(
    26,
    'Community Administration Guidelines',
    DocumentCategory.policies,
    'Guidelines',
    DateTime(2026, 5, 12),
    'Practical demonstration guidelines for local administration and recordkeeping.',
  ),
  _doc(
    27,
    'Province Property Register Summary 2026',
    DocumentCategory.propertyCompliance,
    'Register Summary',
    DateTime(2026, 4, 30),
    'Restricted demonstration summary of property and compliance records.',
    visibility: 'Restricted',
  ),
  _doc(
    28,
    'Province Strategic Plan 2026-2030',
    DocumentCategory.strategy,
    'Strategic Plan',
    DateTime(2026, 8, 10),
    'Mission vitality, formation, ministries, sustainability, governance and digital memory.',
    file: 'province_strategic_plan_2026_2030.pdf',
  ),
];

ProvinceDocument _doc(
  int number,
  String title,
  DocumentCategory category,
  String type,
  DateTime date,
  String description, {
  String? entityType,
  String? entityId,
  String? entityName,
  String visibility = 'Provincial Team',
  String? file,
}) => ProvinceDocument(
  id: 'DOC${number.toString().padLeft(3, '0')}',
  documentCode: 'DOC-${number.toString().padLeft(3, '0')}',
  title: title,
  category: category,
  documentType: type,
  documentDate: date,
  description: description,
  relatedEntityType: entityType,
  relatedEntityId: entityId,
  relatedEntityName: entityName,
  visibility: visibility,
  fileName: file,
  assetPath: file == null ? null : 'assets/demo_documents/$file',
  createdAt: date.add(const Duration(hours: 12)),
);
