class ProvincePerson {
  const ProvincePerson({
    required this.id,
    required this.name,
    this.role,
    this.photoUrl,
    this.phone,
    this.whatsApp,
    this.email,
    this.ministryAssignment,
    this.memberStatus,
  });
  final String id;
  final String name;
  final String? role;
  final String? photoUrl;
  final String? phone;
  final String? whatsApp;
  final String? email;
  final String? ministryAssignment;
  final String? memberStatus;
  ProvincePerson copyWith({String? role}) => ProvincePerson(
    id: id,
    name: name,
    role: role ?? this.role,
    photoUrl: photoUrl,
    phone: phone,
    whatsApp: whatsApp,
    email: email,
    ministryAssignment: ministryAssignment,
    memberStatus: memberStatus,
  );
}

class ProvinceAssignment {
  const ProvinceAssignment({
    required this.person,
    this.role,
    this.fromDate,
    this.toDate,
  });
  final ProvincePerson person;
  final String? role;
  final DateTime? fromDate;
  final DateTime? toDate;
  bool get current {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = fromDate == null
        ? null
        : DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
    final to = toDate == null
        ? null
        : DateTime(toDate!.year, toDate!.month, toDate!.day);
    final starts = from == null || !from.isAfter(today);
    final ends = to == null || !to.isBefore(today);
    return starts && ends;
  }
}

class CommunityRecord {
  const CommunityRecord({
    required this.id,
    required this.name,
    required this.residentCount,
    this.code,
    this.superior,
    this.accountant,
    this.superiorPerson,
    this.accountantPerson,
    this.establishedYear,
    this.phone,
    this.email,
    this.type,
    this.recordStatus,
    this.communityCategory,
    this.patronSaintName,
    this.feastMonth,
    this.feastDay,
    this.motto,
    this.missionStatement,
    this.visionStatement,
    this.apostolicFocus = const [],
    this.communityValues = const [],
    this.foundingStory,
    this.historySummary,
    this.coverImagePath,
    this.coverImageUrl,
    this.location,
    this.residents = const [],
    this.ministries = const [],
    this.ministryRecords = const [],
    this.currentMovements = const [],
    this.lifecycleEvents = const [],
    this.history = const [],
  });
  final String id;
  final String name;
  final String? code;
  final String? superior;
  final String? accountant;
  final ProvincePerson? superiorPerson;
  final ProvincePerson? accountantPerson;
  final int? establishedYear;
  final String? phone;
  final String? email;
  final String? type;
  final String? recordStatus;

  // Structured Community Profile identity.
  final String? communityCategory;
  final String? patronSaintName;
  final int? feastMonth;
  final int? feastDay;
  final String? motto;
  final String? missionStatement;
  final String? visionStatement;
  final List<String> apostolicFocus;
  final List<String> communityValues;
  final String? foundingStory;
  final String? historySummary;

  final String? coverImagePath;
  final String? coverImageUrl;
  final String? location;
  final int residentCount;
  final List<ProvincePerson> residents;
  final List<String> ministries;
  final List<MinistryRecord> ministryRecords;
  final List<CommunityMovement> currentMovements;
  final List<CommunityLifecycleEvent> lifecycleEvents;
  final List<ProvinceAssignment> history;
  String get status =>
      recordStatus ?? (residentCount > 0 ? 'Active' : 'No current residents');
}

class CommunityLifecycleEvent {
  const CommunityLifecycleEvent({
    required this.typeCode,
    required this.effectiveDate,
    this.datePrecisionCode = 'DAY',
  });

  final String typeCode;
  final DateTime effectiveDate;
  final String datePrecisionCode;

  String get typeLabel => switch (typeCode.toUpperCase()) {
    'OPENED' => 'Opened',
    'CLOSED' => 'Closed',
    'REOPENED' => 'Reopened',
    'STATUS_CHANGED' => 'Status changed',
    _ => typeCode,
  };
}

class CommunityMovement {
  const CommunityMovement({
    required this.person,
    required this.type,
    required this.title,
    this.location,
    this.toDate,
  });
  final ProvincePerson person;
  final String type;
  final String title;
  final String? location;
  final DateTime? toDate;
}

class MinistryRecord {
  const MinistryRecord({
    required this.id,
    required this.name,
    this.type,
    this.community,
    this.assignments = const [],
    this.status,
    this.location,
    this.headName,
    this.headPerson,
    this.headRole,
    this.totalReligious,
    this.totalStaff,
    this.totalStudents,
    this.totalBeneficiaries,
    this.affiliationAuthority,
    this.programsServices,
    this.yearEstablished,
    this.phone,
    this.email,
    this.website,
    this.notes,
    this.motto,
    this.missionStatement,
    this.visionStatement,
    this.patronSaintName,
    this.feastMonth,
    this.feastDay,
    this.apostolicFocus = const [],
    this.ministryValues = const [],
    this.foundingStory,
    this.historySummary,
    this.coverImagePath,
    this.coverImageUrl,
  });
  final String id;
  final String name;
  final String? type;
  final String? community;
  final List<ProvinceAssignment> assignments;
  final String? status;
  final String? location;
  final String? headName;
  final ProvincePerson? headPerson;
  final String? headRole;
  final int? totalReligious;
  final int? totalStaff;
  final int? totalStudents;
  final int? totalBeneficiaries;
  final String? affiliationAuthority;
  final String? programsServices;
  final int? yearEstablished;
  final String? phone;
  final String? email;
  final String? website;
  final String? notes;
  final String? motto;
  final String? missionStatement;
  final String? visionStatement;
  final String? patronSaintName;
  final int? feastMonth;
  final int? feastDay;
  final List<String> apostolicFocus;
  final List<String> ministryValues;
  final String? foundingStory;
  final String? historySummary;
  final String? coverImagePath;
  final String? coverImageUrl;
  List<ProvinceAssignment> get currentAssignments =>
      assignments.where((a) => a.current).toList();
}

class FormationMember {
  const FormationMember({
    required this.person,
    required this.stage,
    this.house,
    this.fromDate,
  });
  final ProvincePerson person;
  final String stage;
  final String? house;
  final DateTime? fromDate;
}

class OfficeHolder {
  const OfficeHolder({
    required this.person,
    required this.office,
    this.officeCode,
    this.fromDate,
    this.toDate,
  });
  final ProvincePerson person;
  final String office;
  final String? officeCode;
  final DateTime? fromDate;
  final DateTime? toDate;
}

class EligibilityRecord {
  const EligibilityRecord({
    required this.person,
    required this.role,
    required this.status,
    this.reason,
    this.indicators = const [],
  });
  final ProvincePerson person;
  final String role;
  final String status;
  final String? reason;
  final List<String> indicators;
}

class EligibilityRole {
  const EligibilityRole({
    required this.code,
    required this.name,
    required this.office,
  });
  final String code;
  final String name;
  final bool office;
}

class AppointmentCompliance {
  const AppointmentCompliance({
    required this.person,
    required this.role,
    required this.status,
    this.eligibilityStatus,
    this.reason,
    this.fromDate,
  });
  final ProvincePerson person;
  final String role;
  final String status;
  final String? eligibilityStatus;
  final String? reason;
  final DateTime? fromDate;
}

class CalendarEntry {
  const CalendarEntry({
    this.id,
    required this.title,
    required this.date,
    required this.category,
    this.endDate,
    this.eventType,
    this.memberId,
    this.relatedEntityType,
    this.relatedEntityId,
    this.location,
    this.priority,
    this.demo = false,
  });
  final String? id;
  final String title;
  final DateTime date;
  final DateTime? endDate;
  final String category;
  final String? eventType;
  final String? memberId;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final String? location;
  final String? priority;
  final bool demo;

  bool occursOn(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    final start = DateTime(date.year, date.month, date.day);
    final rawEnd = endDate ?? date;
    final end = DateTime(rawEnd.year, rawEnd.month, rawEnd.day);
    return !target.isBefore(start) && !target.isAfter(end);
  }
}
