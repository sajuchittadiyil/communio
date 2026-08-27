import '../models/dashboard_models.dart';

abstract interface class DashboardRepository {
  Future<DashboardSnapshot> fetchDashboard();
}

class DashboardException implements Exception {
  const DashboardException({this.cause});
  final Object? cause;
}
