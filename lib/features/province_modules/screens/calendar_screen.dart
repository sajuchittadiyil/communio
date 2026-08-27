import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../../religious_directory/models/member_directory_entry.dart';
import '../data/province_repository.dart';
import '../models/province_models.dart';

enum CalendarViewMode { week, month }

DateTime calendarDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);
DateTime startOfCalendarWeek(DateTime value) {
  final date = calendarDate(value);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    required this.repository,
    required this.onMember,
    this.initialDate,
    super.key,
  });
  final ProvinceRepository repository;
  final ValueChanged<MemberDirectoryEntry> onMember;
  final DateTime? initialDate;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime selected = calendarDate(widget.initialDate ?? DateTime.now());
  CalendarViewMode mode = CalendarViewMode.week;
  late Future<List<CalendarEntry>> future = widget.repository
      .fetchCalendarEntries();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<CalendarEntry>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: FilledButton.icon(
            onPressed: () => setState(
              () => future = widget.repository.fetchCalendarEntries(),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry calendar'),
          ),
        );
      }
      final entries = snapshot.data ?? const <CalendarEntry>[];
      final agenda = mode == CalendarViewMode.week
          ? entries.where((entry) => entry.occursOn(selected)).toList()
          : eventsForCalendarMonth(entries, selected);
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<CalendarViewMode>(
              key: const Key('calendar-view-toggle'),
              segments: const [
                ButtonSegment(
                  value: CalendarViewMode.week,
                  label: Text('Week'),
                  icon: Icon(Icons.view_week_outlined),
                ),
                ButtonSegment(
                  value: CalendarViewMode.month,
                  label: Text('Month'),
                  icon: Icon(Icons.calendar_month_outlined),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (value) =>
                  setState(() => mode = value.single),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (mode == CalendarViewMode.week)
            _WeekView(
              selected: selected,
              entries: entries,
              onSelected: (date) => setState(() => selected = date),
              onMove: (days) =>
                  setState(() => selected = selected.add(Duration(days: days))),
              onToday: () =>
                  setState(() => selected = calendarDate(DateTime.now())),
            )
          else
            _MonthView(
              selected: selected,
              entries: entries,
              onSelected: (date) => setState(() => selected = date),
              onMove: (months) => setState(
                () => selected = DateTime(
                  selected.year,
                  selected.month + months,
                  1,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          _Panel(
            title: mode == CalendarViewMode.week
                ? (DateUtils.isSameDay(selected, DateTime.now())
                      ? 'TODAY'
                      : 'DAY AGENDA')
                : 'MONTH EVENTS',
            child: _Entries(
              entries: agenda,
              onMember: widget.onMember,
              emptyText: mode == CalendarViewMode.week
                  ? 'No important Province events scheduled for this date.'
                  : 'No important Province events scheduled for this month.',
            ),
          ),
        ],
      );
    },
  );
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.selected,
    required this.entries,
    required this.onSelected,
    required this.onMove,
    required this.onToday,
  });
  final DateTime selected;
  final List<CalendarEntry> entries;
  final ValueChanged<DateTime> onSelected;
  final ValueChanged<int> onMove;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final start = startOfCalendarWeek(selected);
    final end = start.add(const Duration(days: 6));
    return _Panel(
      title: 'THIS WEEK',
      child: Column(
        children: [
          _Navigation(
            label: calendarWeekRange(start, end),
            previousKey: const Key('previous-week'),
            nextKey: const Key('next-week'),
            onPrevious: () => onMove(-7),
            onNext: () => onMove(7),
            trailing: TextButton(
              onPressed: onToday,
              child: const Text('Today'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Column(
            children: List.generate(7, (index) {
              final day = start.add(Duration(days: index));
              return _WeekDayRow(
                date: day,
                entries: entries.where((entry) => entry.occursOn(day)).toList(),
                selected: DateUtils.isSameDay(day, selected),
                today: DateUtils.isSameDay(day, DateTime.now()),
                onTap: () => onSelected(day),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WeekDayRow extends StatelessWidget {
  const _WeekDayRow({
    required this.date,
    required this.entries,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final DateTime date;
  final List<CalendarEntry> entries;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${calendarWeekday(date.weekday)} ${date.day}',
    selected: selected,
    button: true,
    child: InkWell(
      key: Key('calendar-day-${date.year}-${date.month}-${date.day}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.07)
              : today
              ? AppColors.appBarSurface
              : AppColors.surface,
          border: Border.all(
            color: today
                ? AppColors.secondary
                : selected
                ? AppColors.primary
                : AppColors.cardBorder,
            width: today ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    calendarWeekday(date.weekday).substring(0, 3).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${date.day} ${shortCalendarMonth(date.month).toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (today) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'TODAY',
                      style: TextStyle(
                        color: AppColors.secondaryDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: entries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Text(
                        'No important events',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < entries.length;
                          index++
                        ) ...[
                          if (index > 0) const Divider(height: AppSpacing.lg),
                          _WeekEvent(entry: entries[index]),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WeekEvent extends StatelessWidget {
  const _WeekEvent({required this.entry});
  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = calendarCategoryColor(entry.category);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.xxs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            calendarShortCategory(entry),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (entry.location != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  entry.location!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.selected,
    required this.entries,
    required this.onSelected,
    required this.onMove,
  });
  final DateTime selected;
  final List<CalendarEntry> entries;
  final ValueChanged<DateTime> onSelected;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    final month = DateTime(selected.year, selected.month);
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final offset = month.weekday - DateTime.monday;
    return _Panel(
      title: 'MONTH OVERVIEW',
      child: Column(
        children: [
          _Navigation(
            label: '${calendarMonthName(month.month)} ${month.year}',
            previousKey: const Key('previous-month'),
            nextKey: const Key('next-month'),
            onPrevious: () => onMove(-1),
            onNext: () => onMove(1),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.5,
            ),
            itemCount: offset + days,
            itemBuilder: (_, index) {
              if (index < offset) return const SizedBox();
              final date = DateTime(
                month.year,
                month.month,
                index - offset + 1,
              );
              return _DayCell(
                date: date,
                entries: entries
                    .where((entry) => entry.occursOn(date))
                    .toList(),
                selected: DateUtils.isSameDay(date, selected),
                today: DateUtils.isSameDay(date, DateTime.now()),
                maxLabels: 1,
                compact: true,
                onTap: () => onSelected(date),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation({
    required this.label,
    required this.previousKey,
    required this.nextKey,
    required this.onPrevious,
    required this.onNext,
    this.trailing,
  });
  final String label;
  final Key previousKey;
  final Key nextKey;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        key: previousKey,
        tooltip: 'Previous',
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.responsive(
            context,
          ).titleMedium.copyWith(color: AppColors.primary),
        ),
      ),
      IconButton(
        key: nextKey,
        tooltip: 'Next',
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right),
      ),
      ?trailing,
    ],
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.entries,
    required this.selected,
    required this.today,
    required this.maxLabels,
    required this.onTap,
    this.compact = false,
  });
  final DateTime date;
  final List<CalendarEntry> entries;
  final bool selected;
  final bool today;
  final int maxLabels;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shown = entries.take(maxLabels).toList();
    return Semantics(
      label: '${calendarWeekday(date.weekday)} ${date.day}',
      selected: selected,
      button: true,
      child: InkWell(
        key: Key('calendar-day-${date.year}-${date.month}-${date.day}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 66 : 104),
          margin: const EdgeInsets.all(AppSpacing.xxs),
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : (today ? AppColors.appBarSurface : AppColors.surface),
            border: Border.all(
              color: today && !selected
                  ? AppColors.secondary
                  : AppColors.cardBorder,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact)
                Text(
                  calendarWeekday(date.weekday).substring(0, 3).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.textLight
                        : AppColors.textSecondary,
                  ),
                ),
              Text(
                '${date.day}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final entry in shown)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  padding: const EdgeInsets.all(AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.white
                        : calendarCategoryColor(
                            entry.category,
                          ).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    shortCalendarTitle(entry.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 7 : 8,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              if (entries.length > shown.length)
                Text(
                  '+${entries.length - shown.length} more',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    color: selected
                        ? AppColors.textLight
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTypography.responsive(
              context,
            ).titleSmall.copyWith(color: AppColors.primary, letterSpacing: 0.8),
          ),
          const Divider(),
          child,
        ],
      ),
    ),
  );
}

class _Entries extends StatelessWidget {
  const _Entries({
    required this.entries,
    required this.onMember,
    required this.emptyText,
  });
  final List<CalendarEntry> entries;
  final ValueChanged<MemberDirectoryEntry> onMember;
  final String emptyText;
  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(emptyText),
      );
    }
    return Column(
      children: sorted.map((entry) {
        final color = calendarCategoryColor(entry.category);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(calendarCategoryIcon(entry.category)),
          ),
          title: Text(entry.title),
          subtitle: Text(
            [
              formatCalendarRange(entry.date, entry.endDate),
              entry.category,
              if (entry.location != null) entry.location!,
            ].join(' · '),
          ),
          onTap: entry.category != 'Birthday' || entry.memberId == null
              ? null
              : () => onMember(
                  MemberDirectoryEntry(
                    id: entry.memberId!,
                    religiousId: '',
                    displayName: entry.title.replaceFirst('’s birthday', ''),
                    memberStatus: 'Active',
                  ),
                ),
        );
      }).toList(),
    );
  }
}

List<CalendarEntry> eventsForCalendarMonth(
  List<CalendarEntry> entries,
  DateTime month,
) {
  final first = DateTime(month.year, month.month);
  final last = DateTime(month.year, month.month + 1, 0);
  return entries
      .where(
        (entry) =>
            !entry.date.isAfter(last) &&
            !(entry.endDate ?? entry.date).isBefore(first),
      )
      .toList();
}

Color calendarCategoryColor(String category) => switch (category) {
  'Meeting / Governance' => AppColors.primary,
  'Travel' => AppColors.cyan,
  'Community' => AppColors.secondaryDark,
  'Ministry' => AppColors.success,
  'Birthday' => AppColors.purple,
  'Deadline / Renewal' => AppColors.warning,
  'Visitation' => AppColors.info,
  _ => AppColors.textSecondary,
};

IconData calendarCategoryIcon(String category) => switch (category) {
  'Meeting / Governance' => Icons.groups_outlined,
  'Travel' => Icons.flight_outlined,
  'Community' => Icons.church_outlined,
  'Ministry' => Icons.apartment_outlined,
  'Birthday' => Icons.cake_outlined,
  'Deadline / Renewal' => Icons.event_busy_outlined,
  'Visitation' => Icons.travel_explore_outlined,
  _ => Icons.event_outlined,
};

String calendarShortCategory(CalendarEntry entry) {
  final title = entry.title.toLowerCase();
  final type = entry.eventType?.toLowerCase();
  return switch (entry.category) {
    'Visitation' => 'Visit',
    'Travel' => 'Travel',
    'Meeting / Governance'
        when type == 'council' || title.contains('council') =>
      'Council',
    'Meeting / Governance' => 'Meeting',
    'Community' when type == 'community_feast' || title.contains('feast') =>
      'Feast',
    'Community' => 'Community',
    'Ministry' => 'Ministry',
    'Birthday' => 'Birthday',
    'Deadline / Renewal' when title.contains('deadline') => 'Deadline',
    'Deadline / Renewal' => 'Renewal',
    _ => 'Event',
  };
}

String shortCalendarTitle(String value) => value
    .replaceAll('Provincial ', '')
    .replaceAll('Meeting', 'Mtg')
    .replaceAll('Community', 'Comm.');
String calendarWeekRange(DateTime start, DateTime end) =>
    start.month == end.month
    ? '${start.day}–${end.day} ${calendarMonthName(start.month)} ${start.year}'
    : '${start.day} ${shortCalendarMonth(start.month)}–${end.day} ${shortCalendarMonth(end.month)} ${end.year}';
String formatCalendarRange(DateTime start, DateTime? end) =>
    end == null || DateUtils.isSameDay(start, end)
    ? formatCalendarDate(start)
    : '${formatCalendarDate(start)}–${formatCalendarDate(end)}';
String calendarWeekday(int weekday) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][weekday - 1];
String calendarMonthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];
String shortCalendarMonth(int month) =>
    calendarMonthName(month).substring(0, 3);
String formatCalendarDate(DateTime date) =>
    '${date.day} ${shortCalendarMonth(date.month)} ${date.year}';
