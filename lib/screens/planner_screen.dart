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

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/pages/task_edit.dart';
import 'package:todopod/services/app_provider.dart';

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
              _SectionHeader(
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
                  (t) => _PlannerTile(
                    task: t,
                    onTap: () => _editTask(context, provider, t),
                    onComplete: () => _completeTask(provider, t),
                  ),
                ),

              const Gap(16),

              // Unscheduled tasks
              _SectionHeader(
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
                  (t) => _PlannerTile(
                    task: t,
                    onTap: () => _editTask(context, provider, t),
                    onComplete: () => _completeTask(provider, t),
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

  Future<void> _editTask(
    BuildContext context,
    AppProvider provider,
    Task task,
  ) async {
    final updated = await showDialog<Task>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskEdit(task: task),
    );
    if (updated != null) {
      provider.updateTask(updated);
      await provider.saveAllToPod();
    }
  }

  void _completeTask(AppProvider provider, Task task) {
    provider.completeTask(task.id);
    provider.saveAllToPod();
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final ColorScheme cs;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: cs.primary,
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Planner tile ──────────────────────────────────────────────────────────────

class _PlannerTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const _PlannerTile({
    required this.task,
    required this.onTap,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final priorityColor = task.priority != null
        ? priorityColors[task.priority] ?? cs.primary
        : cs.outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Priority dot
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              // Description + tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.description,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (task.projects.isNotEmpty || task.contexts.isNotEmpty)
                      Text(
                        [
                          ...task.projects.map((p) => '+$p'),
                          ...task.contexts.map((c) => '@$c'),
                        ].join(' '),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Complete button
              IconButton(
                icon: const Icon(Icons.check_circle_outline, size: 20),
                onPressed: onComplete,
                color: cs.primary.withValues(alpha: 0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
