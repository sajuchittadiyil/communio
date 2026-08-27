import 'package:flutter/material.dart';

@immutable
class FocusItem {
  const FocusItem({
    required this.title,
    required this.primaryDetail,
    required this.icon,
    required this.accent,
    this.secondaryDetail,
    this.memberId,
    this.photoUrl,
    this.emphasized = false,
  });

  final String title;
  final String primaryDetail;
  final String? secondaryDetail;
  final String? memberId;
  final String? photoUrl;
  final bool emphasized;
  final IconData icon;
  final Color accent;
}

@immutable
class ScheduleItem {
  const ScheduleItem({
    required this.time,
    required this.title,
    required this.location,
    required this.category,
    required this.accent,
  });

  final String time;
  final String title;
  final String location;
  final String category;
  final Color accent;
}

@immutable
class OverviewMetric {
  const OverviewMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;
}

@immutable
class ProvinceUpdate {
  const ProvinceUpdate({
    required this.title,
    required this.detail,
    required this.date,
    required this.icon,
    this.memberId,
    this.photoUrl,
  });

  final String title;
  final String detail;
  final String date;
  final IconData icon;
  final String? memberId;
  final String? photoUrl;
}

@immutable
class PulseEvent {
  const PulseEvent({
    required this.id,
    required this.memberName,
    required this.type,
    required this.title,
    required this.timing,
    required this.priority,
    required this.icon,
    required this.accent,
    this.memberId,
    this.photoUrl,
    this.location,
    this.fromDate,
    this.toDate,
  });

  final String id;
  final String? memberId;
  final String? photoUrl;
  final String memberName;
  final String type;
  final String title;
  final String? location;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String timing;
  final String priority;
  final IconData icon;
  final Color accent;

  bool get isCurrent => timing.toUpperCase() == 'CURRENT';
  bool get isHighPriority => priority.toLowerCase() == 'high';
}

@immutable
class CelebrationItem {
  const CelebrationItem({
    required this.memberName,
    required this.kind,
    required this.date,
    required this.daysUntil,
    required this.icon,
    required this.accent,
    this.memberId,
    this.photoUrl,
    this.detail,
    this.mobile,
    this.whatsApp,
  });

  final String? memberId;
  final String? photoUrl;
  final String memberName;
  final String kind;
  final String? detail;
  final String? mobile;
  final String? whatsApp;
  final DateTime date;
  final int daysUntil;
  final IconData icon;
  final Color accent;
}

@immutable
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.metrics,
    this.attention = const [],
    this.celebrations = const [],
    this.movements = const [],
    this.upcomingEvents = const [],
    this.recentAppointments = const [],
    this.recentUpdates = const [],
  });

  final List<OverviewMetric> metrics;
  final List<PulseEvent> attention;
  final List<CelebrationItem> celebrations;
  final List<PulseEvent> movements;
  final List<PulseEvent> upcomingEvents;
  final List<ProvinceUpdate> recentAppointments;
  final List<ProvinceUpdate> recentUpdates;
}
