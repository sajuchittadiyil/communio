import '../models/religious_profile.dart';

enum MemberTimelineCategory {
  vocation,
  transfer,
  community,
  ministry,
  office,
  leave,
}

class MemberTimelineEvent {
  const MemberTimelineEvent({
    required this.id,
    required this.sourceType,
    required this.category,
    required this.title,
    required this.isCurrent,
    this.sourceId,
    this.context,
    this.startDate,
    this.endDate,
    this.startPrecision = TimelineDatePrecision.day,
    this.endPrecision = TimelineDatePrecision.day,
    this.location,
    this.notes,
    this.relatedEntityType,
    this.relatedEntityId,
  });

  final String id;
  final String? sourceId;
  final String sourceType;
  final MemberTimelineCategory category;
  final String title;
  final String? context;
  final DateTime? startDate;
  final DateTime? endDate;
  final TimelineDatePrecision startPrecision;
  final TimelineDatePrecision endPrecision;
  final String? location;
  final String? notes;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool isCurrent;

  DateTime get sortDate => startDate ?? endDate ?? DateTime(1);
}

class MemberTimelineMapper {
  const MemberTimelineMapper._();

  static List<MemberTimelineEvent> fromProfile(ReligiousProfile profile) {
    final events = <MemberTimelineEvent>[
      for (final event in profile.sections.vocationEvents)
        MemberTimelineEvent(
          id: _id('vocation', event.sourceId, event.label, event.date),
          sourceId: event.sourceId,
          sourceType: 'member_vocation_events',
          category: MemberTimelineCategory.vocation,
          title: event.label,
          startDate: event.date,
          startPrecision: event.datePrecision,
          location: event.place,
          notes: event.notes,
          isCurrent: false,
        ),
      for (final assignment in profile.sections.communityAssignments)
        _assignmentEvent(
          assignment,
          category: MemberTimelineCategory.community,
          sourceType: 'member_community_assignments',
          fallbackTitle: 'Community Assignment',
          entityType: 'community',
        ),
      for (final transfer in profile.sections.transfers)
        MemberTimelineEvent(
          id: transfer.id,
          sourceId: transfer.id,
          sourceType: 'member_transfers',
          category: MemberTimelineCategory.transfer,
          title: 'Transfer',
          context: transfer.movementLabel,
          startDate: transfer.effectiveDate,
          relatedEntityType: 'community_transfer',
          relatedEntityId: transfer.toCommunityId ?? transfer.fromCommunityId,
          isCurrent: false,
        ),
      for (final assignment in profile.sections.ministryAssignments)
        _assignmentEvent(
          assignment,
          category: MemberTimelineCategory.ministry,
          sourceType: 'member_ministry_assignments',
          fallbackTitle: assignment.type ?? 'Ministry Assignment',
          entityType: 'ministry',
        ),
      for (final office in profile.sections.offices)
        MemberTimelineEvent(
          id: _id('office', office.sourceId, office.office, office.fromDate),
          sourceId: office.sourceId,
          sourceType: 'member_office_appointments',
          category: MemberTimelineCategory.office,
          title: office.office,
          context: office.context,
          startDate: office.fromDate,
          endDate: office.toDate,
          relatedEntityType: office.contextKind?.name,
          relatedEntityId: office.relatedEntityId,
          isCurrent: _isCurrentRange(office.fromDate, office.toDate),
        ),
      for (final leave in profile.sections.leaveHistory)
        MemberTimelineEvent(
          id: _id('leave', leave.sourceId, leave.type, leave.fromDate),
          sourceId: leave.sourceId,
          sourceType: 'v_demo_member_attention_events',
          category: MemberTimelineCategory.leave,
          title: leave.type,
          context: leave.reason,
          startDate: leave.fromDate,
          endDate: leave.toDate,
          location: leave.location,
          notes: leave.notes,
          isCurrent: leave.isCurrent,
        ),
    ];

    final deduplicated = events.where((event) {
      if (event.category != MemberTimelineCategory.ministry &&
          event.category != MemberTimelineCategory.community) {
        return true;
      }
      return !events.any(
        (candidate) =>
            _isCertainOfficeDuplicate(assignment: event, office: candidate),
      );
    }).toList();
    deduplicated.sort((a, b) {
      final date = b.sortDate.compareTo(a.sortDate);
      if (date != 0) return date;
      return a.category.index.compareTo(b.category.index);
    });
    return deduplicated;
  }

  static MemberTimelineEvent _assignmentEvent(
    AssignmentRecord assignment, {
    required MemberTimelineCategory category,
    required String sourceType,
    required String fallbackTitle,
    required String entityType,
  }) => MemberTimelineEvent(
    id: _id(
      sourceType,
      assignment.sourceId,
      assignment.name,
      assignment.fromDate,
    ),
    sourceId: assignment.sourceId,
    sourceType: sourceType,
    category: category,
    title: assignment.role ?? fallbackTitle,
    context: assignment.name,
    startDate: assignment.fromDate,
    endDate: assignment.toDate,
    relatedEntityType: entityType,
    relatedEntityId: assignment.relatedEntityId,
    isCurrent: _isCurrentRange(assignment.fromDate, assignment.toDate),
  );

  static bool _isCertainOfficeDuplicate({
    required MemberTimelineEvent assignment,
    required MemberTimelineEvent office,
  }) =>
      office.category == MemberTimelineCategory.office &&
      assignment.relatedEntityId != null &&
      assignment.relatedEntityId == office.relatedEntityId &&
      assignment.relatedEntityType == office.relatedEntityType &&
      _normalized(assignment.title) == _normalized(office.title) &&
      assignment.startDate == office.startDate &&
      assignment.endDate == office.endDate;

  static bool _isCurrentRange(DateTime? from, DateTime? to) {
    if (to != null) return false;
    if (from == null) return false;
    return !from.isAfter(DateTime.now());
  }

  static String _id(
    String source,
    String? sourceId,
    String title,
    DateTime? date,
  ) =>
      sourceId ??
      '$source|${_normalized(title)}|${date?.toIso8601String() ?? ''}';

  static String _normalized(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}
