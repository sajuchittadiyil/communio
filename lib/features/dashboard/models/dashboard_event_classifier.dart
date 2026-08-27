import 'dashboard_models.dart';

class DashboardEventClassifier {
  const DashboardEventClassifier._();

  static const _movementTypes = {
    'travel',
    'retreat',
    'training',
    'study',
    'home_leave',
    'visit',
  };

  static const _attentionTypes = {
    'hospital',
    'health',
    'welfare',
    'pastoral_concern',
    'member_concern',
    'community_attention',
    'institution_attention',
  };

  static const _governanceTypes = {
    'council',
    'commission',
    'chapter',
    'audit',
    'inspection',
    'compliance',
    'filing',
    'renewal',
    'deadline',
  };

  static const _governanceTerms = {
    'council',
    'commission',
    'committee',
    'canonical visitation',
    'provincial visitation',
    'community visitation',
    'chapter',
    'statutory',
    'fcra',
    'affiliation',
    'inspection',
    'audit',
    'compliance',
    'insurance',
    'policy renewal',
    'approval deadline',
  };

  static bool isCurrentCelebration(CelebrationItem item) => item.daysUntil == 0;

  static bool isCurrentMovement(PulseEvent event) =>
      event.isCurrent && _movementTypes.contains(event.type);

  static bool isProvinceAttention(PulseEvent event, {DateTime? today}) {
    final localToday = (today ?? DateTime.now()).toLocal();
    final day = DateTime(localToday.year, localToday.month, localToday.day);

    // Current hospitalisation / health / welfare concerns remain visible
    // for as long as the event is current.
    if (event.isCurrent && _attentionTypes.contains(event.type)) {
      return true;
    }

    // Current travel belongs in Province Attention as well as movement history.
    if (event.isCurrent && event.type == 'travel') {
      return true;
    }

    final eventDate = event.fromDate?.toLocal();
    if (eventDate == null) {
      return event.isCurrent &&
          event.isHighPriority &&
          !isCurrentMovement(event);
    }

    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final daysUntil = eventDay.difference(day).inDays;

    // "Two days prior" means today, tomorrow, or the day after tomorrow.
    final withinAttentionWindow = daysUntil >= 0 && daysUntil <= 2;
    if (!withinAttentionWindow) return false;

    final title = event.title.toLowerCase();
    final type = event.type.toLowerCase();

    final renewal = type == 'renewal' || title.contains('renewal');

    final provincialCouncil =
        title.contains('provincial council') ||
        (type == 'council' && title.contains('provincial'));

    final visitation =
        title.contains('provincial visitation') ||
        title.contains('community visitation') ||
        title.contains('canonical visitation') ||
        (type == 'visit' && title.contains('visitation'));

    return renewal || provincialCouncil || visitation;
  }

  // Backward-compatible method used by existing tests.
  static bool isCurrentProvinceAttention(PulseEvent event) =>
      isProvinceAttention(event);

  static bool isUpcomingGovernanceEvent(PulseEvent event, {DateTime? today}) {
    if (event.isCurrent) return false;
    final eventDate = event.fromDate?.toLocal();
    final localToday = (today ?? DateTime.now()).toLocal();
    if (eventDate != null &&
        DateTime(eventDate.year, eventDate.month, eventDate.day).isBefore(
          DateTime(localToday.year, localToday.month, localToday.day),
        )) {
      return false;
    }
    if (_governanceTypes.contains(event.type)) return true;
    final title = event.title.toLowerCase();
    return _governanceTerms.any(title.contains);
  }
}
