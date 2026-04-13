/// Import/Export screen widgets for TodoPod.
///
// Time-stamp: <Friday 2026-03-27 10:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';

class ImportActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onTap;

  const ImportActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: loading ? null : onTap,
      ),
    );
  }
}

// ── Export filter bottom sheet ────────────────────────────────────────────────

class ExportFilterSheet extends StatefulWidget {
  final List<Task> allTasks;
  final List<String> projects;
  final List<String> contexts;
  final DateTime todayDate;
  final String title;

  const ExportFilterSheet({
    super.key,
    required this.allTasks,
    required this.projects,
    required this.contexts,
    required this.todayDate,
    required this.title,
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

    return Padding(
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
                    onTap: () =>
                        setState(() => _priority = _priority == p ? null : p),
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
                      onTap: () =>
                          setState(() => _project = _project == p ? null : p),
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
                      onTap: () =>
                          setState(() => _context = _context == c ? null : c),
                      cs: cs,
                    ),
                ],
              ),
            ),
          ],

          const Gap(20),

          // Export button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                count == 0
                    ? 'No tasks match'
                    : 'Export $count task${count == 1 ? '' : 's'} as PDF',
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
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class ExportFilterRow extends StatelessWidget {
  final String label;
  final Widget child;
  const ExportFilterRow({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class ExportFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  const ExportFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
        ),
        backgroundColor: selected ? cs.primary : cs.surfaceContainerHighest,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ── Message banner ────────────────────────────────────────────────────────────

class ImportMessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final ColorScheme cs;

  const ImportMessageBanner({
    super.key,
    required this.message,
    required this.isError,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? cs.errorContainer : cs.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? cs.onErrorContainer : cs.onSecondaryContainer,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? cs.onErrorContainer : cs.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
