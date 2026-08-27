import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/typography.dart';
import '../data/community_administration_repository.dart';

enum CommunityAdministrationAction { calendarEvent, plannedEvent, minutes }

class CommunityAdministrationScreen extends StatefulWidget {
  const CommunityAdministrationScreen({
    required this.repository,
    required this.communityName,
    this.initialAction,
    this.onCalendar,
    super.key,
  });
  final CommunityAdministrationRepository repository;
  final String communityName;
  final CommunityAdministrationAction? initialAction;
  final VoidCallback? onCalendar;

  @override
  State<CommunityAdministrationScreen> createState() =>
      _CommunityAdministrationScreenState();
}

class _CommunityAdministrationScreenState
    extends State<CommunityAdministrationScreen> {
  late Future<(List<CommunityEventRecord>, List<CommunityMeetingRecord>)> _data;

  @override
  void initState() {
    super.initState();
    _refresh();
    if (widget.initialAction case final action?) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(action));
    }
  }

  void _refresh() => _data =
      Future.wait([
        widget.repository.fetchEvents(),
        widget.repository.fetchMeetings(),
      ]).then(
        (values) => (
          values[0] as List<CommunityEventRecord>,
          values[1] as List<CommunityMeetingRecord>,
        ),
      );

  Future<void> _open(
    CommunityAdministrationAction action, {
    CommunityEventRecord? event,
    CommunityMeetingRecord? meeting,
  }) async {
    final saved = action == CommunityAdministrationAction.minutes
        ? await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CommunityMeetingForm(
                repository: widget.repository,
                communityName: widget.communityName,
                meeting: meeting,
              ),
            ),
          )
        : await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CommunityEventForm(
                repository: widget.repository,
                communityName: widget.communityName,
                initialStatus:
                    action == CommunityAdministrationAction.plannedEvent
                    ? 'planned'
                    : 'confirmed',
                event: event,
              ),
            ),
          );
    if (saved == true && mounted) {
      setState(_refresh);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Community record saved.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Community Administration')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          widget.communityName,
          style: AppTypography.responsive(context).pageTitle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Manage your community calendar, plans and meeting records.',
          style: AppTypography.responsive(
            context,
          ).bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ActionTile(
          icon: Icons.event_available_outlined,
          title: 'Add Calendar Event',
          color: AppColors.info,
          onTap: () => _open(CommunityAdministrationAction.calendarEvent),
        ),
        _ActionTile(
          icon: Icons.edit_calendar_outlined,
          title: 'Plan Community Event',
          color: AppColors.purple,
          onTap: () => _open(CommunityAdministrationAction.plannedEvent),
        ),
        _ActionTile(
          icon: Icons.description_outlined,
          title: 'Meeting Minutes',
          color: AppColors.secondaryDark,
          onTap: () => _open(CommunityAdministrationAction.minutes),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'COMMUNITY RECORDS',
          style: AppTypography.responsive(context).labelLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FutureBuilder(
          future: _data,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final (events, meetings) = snapshot.data!;
            return Column(
              children: [
                for (final event in events)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: Text(event.title),
                      subtitle: Text(
                        '${_date(event.startsAt)} · ${_label(event.status)}'
                        '${event.venue == null ? '' : ' · ${event.venue}'}',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _open(
                        CommunityAdministrationAction.calendarEvent,
                        event: event,
                      ),
                    ),
                  ),
                for (final meeting in meetings)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(meeting.title),
                      subtitle: Text(_date(meeting.meetingDate)),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _open(
                        CommunityAdministrationAction.minutes,
                        meeting: meeting,
                      ),
                    ),
                  ),
                if (events.isEmpty && meetings.isEmpty)
                  const Text('No community administration records yet.'),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: ListTile(
        minTileHeight: 64,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ),
  );
}

class CommunityEventForm extends StatefulWidget {
  const CommunityEventForm({
    required this.repository,
    required this.communityName,
    required this.initialStatus,
    this.event,
    super.key,
  });
  final CommunityAdministrationRepository repository;
  final String communityName;
  final String initialStatus;
  final CommunityEventRecord? event;
  @override
  State<CommunityEventForm> createState() => _CommunityEventFormState();
}

class _CommunityEventFormState extends State<CommunityEventForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.event?.title);
  late final _venue = TextEditingController(text: widget.event?.venue);
  late final _description = TextEditingController(
    text: widget.event?.description,
  );
  late DateTime _start = widget.event?.startsAt ?? DateTime.now();
  late DateTime? _end = widget.event?.endsAt;
  late String _type = widget.event?.type ?? 'community_meeting';
  late String _status = widget.event?.status ?? widget.initialStatus;
  late bool _province = widget.event?.visibleToProvince ?? false;
  late String? _responsibleMemberId = widget.event?.responsibleMemberId;
  bool _saving = false;

  Future<void> _pickStart() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (value != null) setState(() => _start = value);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (value != null) {
      setState(
        () => _start = DateTime(
          _start.year,
          _start.month,
          _start.day,
          value.hour,
          value.minute,
        ),
      );
    }
  }

  Future<void> _pickEnd() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _end ?? _start,
      firstDate: _start,
      lastDate: DateTime(2040),
    );
    if (value != null) setState(() => _end = value);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.repository.saveEvent(
        CommunityEventRecord(
          id: widget.event?.id ?? '',
          title: _title.text.trim(),
          type: _type,
          startsAt: _start,
          endsAt: _end,
          venue: _venue.text.trim().isEmpty ? null : _venue.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          responsibleMemberId: _responsibleMemberId,
          status: _status,
          visibleToProvince: _province,
        ),
        create: widget.event == null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.event == null ? 'Community Event' : 'Edit Event'),
    ),
    body: SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          children: [
            TextFormField(
              controller: _title,
              decoration: _eventFieldDecoration('Event title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter an event title'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField(
              isExpanded: true,
              initialValue: _type,
              decoration: _eventFieldDecoration('Event type'),
              items: _eventTypes.entries
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.key,
                      child: Text(
                        item.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _type = value!,
            ),
            const SizedBox(height: AppSpacing.xs),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 62,
              title: const Text('Start date'),
              subtitle: Text(_date(_start)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickStart,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 62,
              title: const Text('Time (optional)'),
              subtitle: Text(TimeOfDay.fromDateTime(_start).format(context)),
              trailing: const Icon(Icons.schedule_outlined),
              onTap: _pickTime,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 62,
              title: const Text('End date (optional)'),
              subtitle: Text(_end == null ? 'Not set' : _date(_end!)),
              trailing: const Icon(Icons.event_busy_outlined),
              onTap: _pickEnd,
            ),
            TextFormField(
              controller: _venue,
              decoration: _eventFieldDecoration('Venue'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<CommunityResidentOption>>(
              future: widget.repository.fetchResidents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return InputDecorator(
                    decoration: _eventFieldDecoration(
                      'Responsible person (optional)',
                    ),
                    child: const Text(
                      'Loading residents…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: _responsibleMemberId,
                  decoration: _eventFieldDecoration(
                    'Responsible person (optional)',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text(
                        'Not assigned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final resident in snapshot.data!)
                      DropdownMenuItem(
                        value: resident.id,
                        child: Text(
                          resident.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => _responsibleMemberId = value,
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: _eventFieldDecoration('Short description'),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField(
              isExpanded: true,
              initialValue: _status,
              decoration: _eventFieldDecoration('Status'),
              items: const ['planned', 'confirmed', 'completed', 'cancelled']
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        _label(value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _status = value!,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Visible to Provincial Team',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: _province,
              onChanged: (value) => setState(() => _province = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save Event'),
            ),
            if (widget.event != null)
              TextButton(
                onPressed: _saving
                    ? null
                    : () async {
                        await widget.repository.deleteEvent(widget.event!.id);
                        if (context.mounted) Navigator.of(context).pop(true);
                      },
                child: const Text('Delete Event'),
              ),
          ],
        ),
      ),
    ),
  );
}

class CommunityMeetingForm extends StatefulWidget {
  const CommunityMeetingForm({
    required this.repository,
    required this.communityName,
    this.meeting,
    super.key,
  });
  final CommunityAdministrationRepository repository;
  final String communityName;
  final CommunityMeetingRecord? meeting;
  @override
  State<CommunityMeetingForm> createState() => _CommunityMeetingFormState();
}

class _CommunityMeetingFormState extends State<CommunityMeetingForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.meeting?.title);
  late final _summary = TextEditingController(text: widget.meeting?.summary);
  late final _decisions = TextEditingController(
    text: widget.meeting?.decisions,
  );
  late final _actions = TextEditingController(
    text: widget.meeting?.actionItems,
  );
  late DateTime _dateValue = widget.meeting?.meetingDate ?? DateTime.now();
  late bool _province = widget.meeting?.visibleToProvince ?? true;
  bool _saving = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.repository.saveMeeting(
        CommunityMeetingRecord(
          id: widget.meeting?.id ?? '',
          title: _title.text.trim(),
          meetingDate: _dateValue,
          summary: _summary.text.trim(),
          decisions: _decisions.text.trim(),
          actionItems: _actions.text.trim(),
          visibleToProvince: _province,
        ),
        create: widget.meeting == null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Community Meeting Minutes')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Meeting title'),
            validator: _required,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Meeting date'),
            subtitle: Text(_date(_dateValue)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final value = await showDatePicker(
                context: context,
                initialDate: _dateValue,
                firstDate: DateTime(2020),
                lastDate: DateTime(2040),
              );
              if (value != null) setState(() => _dateValue = value);
            },
          ),
          TextFormField(
            controller: _summary,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Summary'),
            validator: _required,
          ),
          TextFormField(
            controller: _decisions,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Decisions'),
          ),
          TextFormField(
            controller: _actions,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Action items'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Visible to Provincial Team'),
            value: _province,
            onChanged: (value) => setState(() => _province = value),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save Minutes'),
          ),
        ],
      ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
}

const _eventTypes = {
  'community_meeting': 'Community Meeting',
  'feast_celebration': 'Feast / Celebration',
  'recollection': 'Recollection',
  'retreat': 'Retreat',
  'community_programme': 'Community Programme',
  'visitor_guest_programme': 'Visitor / Guest Programme',
  'formation_spiritual_programme': 'Formation / Spiritual Programme',
  'other': 'Other',
};

InputDecoration _eventFieldDecoration(String label) => InputDecoration(
  labelText: label,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
);

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')} '
    '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][value.month - 1]} ${value.year}';
String _label(String value) => value
    .split('_')
    .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');
