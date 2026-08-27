import 'package:flutter/foundation.dart';

import '../data/religious_profile_repository.dart';
import '../models/religious_profile.dart';

enum ReligiousProfileStatus { loading, ready, error }

class ReligiousProfileController extends ChangeNotifier {
  ReligiousProfileController(this._repository, this.memberId);

  final ReligiousProfileRepository _repository;
  final String memberId;

  ReligiousProfileStatus status = ReligiousProfileStatus.loading;
  ReligiousProfile? profile;
  ReligiousProfileFailureKind? failureKind;

  Future<void> load() async {
    status = ReligiousProfileStatus.loading;
    failureKind = null;
    notifyListeners();
    try {
      profile = await _repository.fetchProfile(memberId);
      status = ReligiousProfileStatus.ready;
    } on ReligiousProfileException catch (error) {
      failureKind = error.kind;
      status = ReligiousProfileStatus.error;
    } catch (_) {
      failureKind = ReligiousProfileFailureKind.unexpected;
      status = ReligiousProfileStatus.error;
    }
    notifyListeners();
  }
}
