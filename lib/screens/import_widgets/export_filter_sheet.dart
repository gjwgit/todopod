/// ExportFilterSheet — modal sheet for filtering tasks during export.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/screens/import_widgets/export_filter_chip.dart';
import 'package:todopod/screens/import_widgets/export_filter_row.dart';

class ExportFilterSheet extends StatefulWidget {
  final List<Task> allTasks;
  final List<String> projects;
  final List<String> contexts;
  final DateTime todayDate;
  final String title;

  /// Verb shown on the action button, e.g. 'View' or 'Export'.
  final String actionVerb;

  const ExportFilterSheet({
    super.key,
    required this.allTasks,
    required this.projects,
    required this.contexts,
    required this.todayDate,
    required this.title,
    this.actionVerb = 'Export',
  });

  @override
  State<ExportFilterSheet> createState() => ExportFilterSheetState();
}

class ExportFilterSheetState extends State<ExportFilterSheet> {
  // Priority filter — null means all priorities.
  String? _priority;
  // Project / context — null means all.
  String? _project;
  String? _context;
  // Due filter.
  String? _due; // 'past' | 'today' | 'week' | null

  /// Builds a filename-safe label from active filters.
  /// e.g. "today", "priorityA_project_work", "past_context_home"
  String _buildFilterLabel() {
    final parts = <String>[];
    if (_due != null) parts.add(_due!);
    if (_priority != null) parts.add('priority${_priority!.toLowerCase()}');
    if (_project != null) parts.add('project_${_project!.toLowerCase()}');
    if (_context != null) parts.add('context_${_context!.toLowerCase()}');
    return parts.join('_');
  }

  List<Task> get _filtered {
    final today = widget.todayDate;
    final tomorrow = today.add(const Duration(days: 1));
    final week = today.add(const Duration(days: 7));

    return widget.allTasks.where((t) {
      if (_priority != null && t.priority != _priority) return false;
      if (_project != null && !t.projects.contains(_project)) {
        return false;
      }
      if (_context != null && !t.contexts.contains(_context)) {
        return false;
      }
      if (_due != null) {
        if (t.dueDate == null) return false;
        final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        switch (_due) {
          case 'past':
            if (!d.isBefore(today)) return false;
          case 'today':
            if (!d.isAtSameMomentAs(today)) return false;
          case 'tomorrow':
            if (!d.isAtSameMomentAs(tomorrow)) return false;
          case 'week':
            if (d.isBefore(today) || d.isAfter(week)) return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = _filtered.length;

    return ConstrainedBox(
      // Cap the sheet height so a long project/context list scrolls rather
      // than mis-measuring on first open (which previously showed a
      // collapsed sheet until tapped a second time).
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter — ${widget.title}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _priority = null;
                      _project = null;
                      _context = null;
                      _due = null;
                    }),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
              const Divider(),
              const Gap(8),

              // Priority
              ExportFilterRow(
                label: 'Priority',
                child: Wrap(
                  spacing: 6,
                  children: [
                    ExportFilterChip(
                      label: 'All',
                      selected: _priority == null,
                      onTap: () => setState(() => _priority = null),
                      cs: cs,
                    ),
                    for (final p in priorities)
                      ExportFilterChip(
                        label: priorityLabels[p] ?? p,
                        selected: _priority == p,
                        onTap: () => setState(
                          () => _priority = _priority == p ? null : p,
                        ),
                        cs: cs,
                      ),
                  ],
                ),
              ),
              const Gap(12),

              // Due
              ExportFilterRow(
                label: 'Due',
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final d in [
                      ('past', 'Past due'),
                      ('today', 'Today'),
                      ('tomorrow', 'Tomorrow'),
                      ('week', 'This week'),
                    ])
                      ExportFilterChip(
                        label: d.$2,
                        selected: _due == d.$1,
                        onTap: () =>
                            setState(() => _due = _due == d.$1 ? null : d.$1),
                        cs: cs,
                      ),
                  ],
                ),
              ),

              // Project
              if (widget.projects.isNotEmpty) ...[
                const Gap(12),
                ExportFilterRow(
                  label: 'Project',
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final p in widget.projects)
                        ExportFilterChip(
                          label: '+$p',
                          selected: _project == p,
                          onTap: () => setState(
                            () => _project = _project == p ? null : p,
                          ),
                          cs: cs,
                        ),
                    ],
                  ),
                ),
              ],

              // Context
              if (widget.contexts.isNotEmpty) ...[
                const Gap(12),
                ExportFilterRow(
                  label: 'Context',
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final c in widget.contexts)
                        ExportFilterChip(
                          label: '@$c',
                          selected: _context == c,
                          onTap: () => setState(
                            () => _context = _context == c ? null : c,
                          ),
                          cs: cs,
                        ),
                    ],
                  ),
                ),
              ],

              const Gap(20),

              // Action button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    count == 0
                        ? 'No tasks match'
                        : '${widget.actionVerb} $count '
                              'task${count == 1 ? '' : 's'} as PDF',
                  ),
                  onPressed: count == 0
                      ? null
                      : () => Navigator.pop(context, (
                          _filtered,
                          _buildFilterLabel(),
                        )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
