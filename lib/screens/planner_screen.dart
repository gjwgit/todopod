/// PlannerScreen — calendar view of tasks by due date.
///
// Time-stamp: <2026-04-27>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/screens/planner_widgets/planner_tile.dart';
import 'package:todopod/screens/planner_widgets/section_header.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/services/task_actions.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Build a map of day → tasks for the calendar event markers.
  Map<DateTime, List<Task>> _buildEventMap(List<Task> tasks) {
    final map = <DateTime, List<Task>>{};
    for (final t in tasks) {
      if (t.dueDate == null) continue;
      final key = _dayKey(t.dueDate!);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Task> _tasksForDay(Map<DateTime, List<Task>> map, DateTime day) =>
      map[_dayKey(day)] ?? [];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AppProvider>();

    // Show a busy indicator during startup/loading so the calendar doesn't
    // render before tasks are available.
    if (provider.busy) {
      return const Center(child: CircularProgressIndicator());
    }

    final allTasks = provider.tasks;
    final eventMap = _buildEventMap(allTasks);
    final selectedTasks = _tasksForDay(eventMap, _selectedDay);
    final unscheduled = allTasks.where((t) => t.dueDate == null).toList();

    return Column(
      children: [
        // ── Today shortcut ─────────────────────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: TextButton.icon(
              onPressed: () {
                final today = DateTime.now();
                setState(() {
                  _selectedDay = today;
                  _focusedDay = today;
                });
              },
              icon: const Icon(Icons.today_outlined, size: 16),
              label: const Text('Today'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        ),
        // ── Calendar ───────────────────────────────────────────────────
        TableCalendar<Task>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
          eventLoader: (d) => _tasksForDay(eventMap, d),
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: cs.secondary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) => setState(() => _focusedDay = focused),
        ),
        const Divider(height: 1),

        // ── Tasks for selected day ─────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Selected day tasks
              SectionHeader(
                label: _dayLabel(_selectedDay),
                count: selectedTasks.length,
                cs: cs,
              ),
              if (selectedTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No tasks due on this day.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              else
                ...selectedTasks.map(
                  (t) => PlannerTile(
                    task: t,
                    onTap: () => editTaskAction(
                      context: context,
                      provider: provider,
                      task: t,
                    ),
                    onComplete: () => completeTaskAction(
                      context: context,
                      provider: provider,
                      task: t,
                    ),
                  ),
                ),

              const Gap(16),

              // Unscheduled tasks
              SectionHeader(
                label: 'Unscheduled',
                count: unscheduled.length,
                cs: cs,
              ),
              if (unscheduled.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'All tasks have a due date.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              else
                ...unscheduled.map(
                  (t) => PlannerTile(
                    task: t,
                    onTap: () => editTaskAction(
                      context: context,
                      provider: provider,
                      task: t,
                    ),
                    onComplete: () => completeTaskAction(
                      context: context,
                      provider: provider,
                      task: t,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    if (isSameDay(d, now)) return 'Today';
    if (isSameDay(d, now.add(const Duration(days: 1)))) return 'Tomorrow';
    if (isSameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday]} ${d.day} ${months[d.month]}';
  }
}

// ── Section header ────────────────────────────────────────────────────────────

// ── Planner tile ──────────────────────────────────────────────────────────────
