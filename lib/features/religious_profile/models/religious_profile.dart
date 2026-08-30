import '../../../core/utils/ecclesiastical_name.dart';

class ReligiousProfile {
  const ReligiousProfile({
    required this.memberId,
    required this.displayName,
    required this.memberStatus,
    required this.sections,
    this.title,
    this.photoUrl,
    this.canonicalStatus,
    this.dateOfBirth,
    this.nationality,
    this.bloodGroup,
    this.patronSaint,
    this.community,
    this.communityRole,
    this.ministry,
    this.ministryRole,
    this.ministryType,
    this.communityFromDate,
    this.ministryFromDate,
    this.origin,
    this.religiousId = '',
  });

  final String memberId;
  final String religiousId;
  final String displayName;
  final String? title;
  final String? photoUrl;
  final String memberStatus;
  final String? canonicalStatus;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? bloodGroup;
  final String? patronSaint;
  final String? community;
  final String? communityRole;
  final String? ministry;
  final String? ministryRole;
  final String? ministryType;
  final DateTime? communityFromDate;
  final DateTime? ministryFromDate;
  final MemberOriginDetails? origin;
  final ReligiousProfileSections sections;

  String get titledName =>
      composeEcclesiasticalName(displayName: displayName, title: title);

  String? get ministryAssignment => _joined(ministry, ministryRole);

  int? get age {
    final birth = dateOfBirth;
    if (birth == null) return null;
    final today = DateTime.now();
    var years = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      years--;
    }
    return years;
  }

  static String? _joined(String? first, String? second) {
    final values = [
      first,
      second,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    return values.isEmpty ? null : values.join(' · ');
  }
}

class MemberOriginDetails {
  const MemberOriginDetails({
    this.birthplace,
    this.nativePlace,
    this.homeParish,
    this.diocese,
    this.district,
    this.state,
    this.country,
  });

  final String? birthplace;
  final String? nativePlace;
  final String? homeParish;
  final String? diocese;
  final String? district;
  final String? state;
  final String? country;

  bool get isEmpty =>
      birthplace == null &&
      nativePlace == null &&
      homeParish == null &&
      diocese == null &&
      district == null &&
      state == null &&
      country == null;
}

class ReligiousProfileSections {
  const ReligiousProfileSections({
    this.vocationEvents = const [],
    this.qualifications = const [],
    this.languages = const [],
    this.transfers = const [],
    this.communityAssignments = const [],
    this.ministryAssignments = const [],
    this.offices = const [],
    this.leaveHistory = const [],
    this.homeContacts = const [],
    this.family = const [],
    this.contacts = const [],
    this.documents = const [],
    this.failures = const {},
  });

  final List<VocationEvent> vocationEvents;
  final List<QualificationRecord> qualifications;
  final List<MemberLanguage> languages;
  final List<MemberTransferRecord> transfers;
  final List<AssignmentRecord> communityAssignments;
  final List<AssignmentRecord> ministryAssignments;
  final List<OfficeAppointment> offices;
  final List<LeaveRecord> leaveHistory;
  final List<LabeledValue> homeContacts;
  final List<FamilyContact> family;
  final List<LabeledValue> contacts;
  final List<DocumentRecord> documents;
  final Set<ProfileSection> failures;
}

class MemberTransferRecord {
  const MemberTransferRecord({
    required this.id,
    required this.effectiveDate,
    this.fromCommunityId,
    this.fromCommunityName,
    this.toCommunityId,
    this.toCommunityName,
    this.transferTypeCode = 'TRANSFER',
  });

  final String id;
  final String? fromCommunityId;
  final String? fromCommunityName;
  final String? toCommunityId;
  final String? toCommunityName;
  final DateTime effectiveDate;
  final String transferTypeCode;

  String get movementLabel =>
      '${fromCommunityName ?? 'External origin'} → ${toCommunityName ?? 'External destination'}';
}

class MemberLanguage {
  const MemberLanguage({
    required this.name,
    this.code,
    this.proficiencyLevelCode,
    this.canSpeak,
    this.canRead,
    this.canWrite,
    this.isPrimary = false,
    this.isNative,
  });

  final String name;
  final String? code;
  final String? proficiencyLevelCode;
  final bool? canSpeak;
  final bool? canRead;
  final bool? canWrite;
  final bool isPrimary;
  final bool? isNative;

  String get proficiencyLabel => switch (proficiencyLevelCode) {
    final value? =>
      value
          .toLowerCase()
          .split('_')
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' '),
    null => '',
  };

  String get capabilityLabel => [
    if (proficiencyLabel.isNotEmpty) proficiencyLabel,
    if (canSpeak == true) 'Speak',
    if (canRead == true) 'Read',
    if (canWrite == true) 'Write',
  ].join(' · ');
}

enum ProfileSection {
  origin,
  vocation,
  qualifications,
  assignments,
  governance,
  leave,
  family,
  documents,
}

class VocationEvent {
  const VocationEvent({
    required this.label,
    this.sourceId,
    this.date,
    this.datePrecision = TimelineDatePrecision.day,
    this.place,
    this.notes,
  });
  final String label;
  final String? sourceId;
  final DateTime? date;
  final TimelineDatePrecision datePrecision;
  final String? place;
  final String? notes;
}

class QualificationRecord {
  const QualificationRecord({
    required this.qualification,
    this.specialization,
    this.category,
    this.level,
    this.institution,
    this.universityBoard,
    this.subject,
    this.teachingSubjects = const [],
    this.year,
    this.startYear,
    this.endYear,
    this.country,
    this.notes,
  });
  final String qualification;
  final String? specialization;
  final String? category;
  final String? level;
  final String? institution;
  final String? universityBoard;
  final String? subject;
  final List<String> teachingSubjects;
  final int? year;
  final int? startYear;
  final int? endYear;
  final String? country;
  final String? notes;
}

class AssignmentRecord {
  const AssignmentRecord({
    required this.kind,
    required this.name,
    this.sourceId,
    this.relatedEntityId,
    this.role,
    this.type,
    this.fromDate,
    this.toDate,
  });
  final String kind;
  final String name;
  final String? sourceId;
  final String? relatedEntityId;
  final String? role;
  final String? type;
  final DateTime? fromDate;
  final DateTime? toDate;
  bool get isCurrent => toDate == null;
}

class OfficeAppointment {
  const OfficeAppointment({
    required this.office,
    this.sourceId,
    this.context,
    this.contextKind,
    this.relatedEntityId,
    this.fromDate,
    this.toDate,
  });
  final String office;
  final String? sourceId;
  final String? context;
  final OfficeContextKind? contextKind;
  final String? relatedEntityId;
  final DateTime? fromDate;
  final DateTime? toDate;
  bool get isCurrent => toDate == null;
}

enum OfficeContextKind { ministry, community, province, congregation }

class LeaveRecord {
  const LeaveRecord({
    required this.type,
    this.sourceId,
    this.fromDate,
    this.toDate,
    this.location,
    this.reason,
    this.notes,
    this.timingStatus,
  });

  final String type;
  final String? sourceId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? location;
  final String? reason;
  final String? notes;
  final String? timingStatus;

  bool get isCurrent {
    if (timingStatus?.toLowerCase() == 'current') return true;
    final today = DateTime.now();
    final starts = fromDate == null || !fromDate!.isAfter(today);
    final ends = toDate == null || !toDate!.isBefore(today);
    return starts && ends && (fromDate != null || toDate != null);
  }
}

enum TimelineDatePrecision { day, month, year }

class FamilyContact {
  const FamilyContact({
    required this.name,
    this.relationship,
    this.lifeStatus = FamilyLifeStatus.unknown,
    this.dateOfBirth,
    this.dateOfDeath,
    this.deathYear,
    this.phone,
    this.whatsApp,
    this.email,
    this.notes,
    this.isPrimary = false,
    this.isNextOfKin = false,
    this.isEmergency = false,
  });
  final String name;
  final String? relationship;
  final FamilyLifeStatus lifeStatus;
  final DateTime? dateOfBirth;
  final DateTime? dateOfDeath;
  final int? deathYear;
  final String? phone;
  final String? whatsApp;
  final String? email;
  final String? notes;
  final bool isPrimary;
  final bool isNextOfKin;
  final bool isEmergency;

  bool get isParent =>
      relationship?.toLowerCase() == 'father' ||
      relationship?.toLowerCase() == 'mother';

  String get displayName =>
      lifeStatus == FamilyLifeStatus.deceased ? 'Late $name' : name;
}

enum FamilyLifeStatus { living, deceased, unknown }

class LabeledValue {
  const LabeledValue(this.label, this.value);
  final String label;
  final String value;
}

class DocumentRecord {
  const DocumentRecord({
    required this.type,
    this.number,
    this.issueDate,
    this.expiryDate,
    this.authority,
    this.verificationStatus,
  });
  final String type;
  final String? number;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? authority;
  final String? verificationStatus;

  bool get expiresSoon {
    final expiry = expiryDate;
    if (expiry == null) return false;
    final days = expiry.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 90;
  }
}
