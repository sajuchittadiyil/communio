import '../models/province_models.dart';

abstract interface class ProvinceRepository {
  Future<List<CommunityRecord>> fetchCommunities();
  Future<List<MinistryRecord>> fetchMinistries();
  Future<List<FormationMember>> fetchFormation();
  Future<List<OfficeHolder>> fetchOfficeHolders();
  Future<List<EligibilityRole>> fetchEligibilityRoles();
  Future<List<EligibilityRecord>> fetchEligibility(
    String roleCode, {
    required bool office,
  });
  Future<List<AppointmentCompliance>> fetchAppointmentCompliance();
  Future<List<CalendarEntry>> fetchCalendarEntries();
}

abstract interface class GovernanceHistoryRepository {
  Future<List<OfficeHolder>> fetchPastProvincials();
}

class ProvinceDataException implements Exception {
  const ProvinceDataException();
}
