import 'package:flutter/foundation.dart';

import '../data/dashboard_repository.dart';
import '../models/dashboard_models.dart';

enum DashboardStatus { loading, ready, error }

class DashboardController extends ChangeNotifier {
  DashboardController(this._repository);
  final DashboardRepository _repository;
  DashboardStatus status = DashboardStatus.loading;
  DashboardSnapshot? snapshot;

  Future<void> load() async {
    status = DashboardStatus.loading;
    notifyListeners();
    try {
      snapshot = await _repository.fetchDashboard();
      status = DashboardStatus.ready;
    } catch (_) {
      status = DashboardStatus.error;
    }
    notifyListeners();
  }
}
