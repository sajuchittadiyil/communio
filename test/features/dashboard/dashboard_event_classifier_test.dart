import 'package:communio/features/dashboard/models/dashboard_event_classifier.dart';
import 'package:communio/features/dashboard/models/dashboard_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PulseEvent event({
    required String type,
    required String timing,
    String title = 'Event',
    String priority = 'normal',
    DateTime? fromDate,
  }) => PulseEvent(
    id: '$type-$timing',
    memberName: 'Member',
    type: type,
    title: title,
    timing: timing,
    priority: priority,
    fromDate: fromDate,
    icon: Icons.event_outlined,
    accent: Colors.blue,
  );

  test('celebrations are current only', () {
    final today = CelebrationItem(
      memberName: 'Today',
      kind: 'Birthday',
      date: DateTime(2026, 8, 17),
      daysUntil: 0,
      icon: Icons.cake_outlined,
      accent: Colors.purple,
    );
    final future = CelebrationItem(
      memberName: 'Future',
      kind: 'Feast Day',
      date: DateTime(2026, 8, 18),
      daysUntil: 1,
      icon: Icons.church_outlined,
      accent: Colors.amber,
    );
    expect(DashboardEventClassifier.isCurrentCelebration(today), isTrue);
    expect(DashboardEventClassifier.isCurrentCelebration(future), isFalse);
  });

  test('current movements exclude future travel and return', () {
    expect(
      DashboardEventClassifier.isCurrentMovement(
        event(type: 'training', timing: 'CURRENT'),
      ),
      isTrue,
    );
    expect(
      DashboardEventClassifier.isCurrentMovement(
        event(type: 'retreat', timing: 'CURRENT'),
      ),
      isTrue,
    );
    expect(
      DashboardEventClassifier.isCurrentMovement(
        event(type: 'travel', timing: 'UPCOMING'),
      ),
      isFalse,
    );
    expect(
      DashboardEventClassifier.isCurrentMovement(
        event(type: 'return', timing: 'UPCOMING'),
      ),
      isFalse,
    );
  });

  test('attention is current and excludes ordinary movements', () {
    expect(
      DashboardEventClassifier.isCurrentProvinceAttention(
        event(type: 'hospital', timing: 'CURRENT', priority: 'high'),
      ),
      isTrue,
    );
    expect(
      DashboardEventClassifier.isCurrentProvinceAttention(
        event(type: 'visit', timing: 'UPCOMING', priority: 'high'),
      ),
      isFalse,
    );
    expect(
      DashboardEventClassifier.isCurrentProvinceAttention(
        event(type: 'training', timing: 'CURRENT', priority: 'high'),
      ),
      isFalse,
    );
  });

  test('upcoming events contain governance but not ordinary movement', () {
    expect(
      DashboardEventClassifier.isUpcomingGovernanceEvent(
        event(
          type: 'meeting',
          timing: 'UPCOMING',
          title: 'Education Commission Meeting',
        ),
      ),
      isTrue,
    );
    expect(
      DashboardEventClassifier.isUpcomingGovernanceEvent(
        event(
          type: 'visit',
          timing: 'UPCOMING',
          title: 'Provincial Community Visitation',
        ),
      ),
      isTrue,
    );
    expect(
      DashboardEventClassifier.isUpcomingGovernanceEvent(
        event(
          type: 'travel',
          timing: 'UPCOMING',
          title: 'International Travel',
        ),
      ),
      isFalse,
    );
    expect(
      DashboardEventClassifier.isUpcomingGovernanceEvent(
        event(type: 'return', timing: 'UPCOMING'),
      ),
      isFalse,
    );
  });

  test('upcoming events exclude dates before the current local date', () {
    final today = DateTime(2026, 8, 19, 14);
    expect(
      DashboardEventClassifier.isUpcomingGovernanceEvent(
        event(
          type: 'council',
          timing: 'UPCOMING',
          fromDate: DateTime(2026, 8, 18, 23, 59),
        ),
        today: today,
      ),
      isFalse,
    );
    expect(
      DashboardEventClassifier.isUpcomingGovernanceEvent(
        event(
          type: 'council',
          timing: 'UPCOMING',
          fromDate: DateTime(2026, 8, 19),
        ),
        today: today,
      ),
      isTrue,
    );
  });
}
