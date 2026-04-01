/// DoneScreen — view and manage completed tasks.
///
// Time-stamp: <Friday 2026-03-27 12:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/widgets/task_tile.dart';

class DoneScreen extends StatefulWidget {
  const DoneScreen({super.key});

  @override
  State<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends State<DoneScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    final all = provider.doneTasks;
    final tasks = _query.isEmpty
        ? all
        : all.where((t) {
            final q = _query.toLowerCase();
            return t.description.toLowerCase().contains(q) ||
                t.projects.any((p) => p.toLowerCase().contains(q)) ||
                t.contexts.any((c) => c.toLowerCase().contains(q));
          }).toList();

    return Scaffold(
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Search done tasks...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (all.isNotEmpty) ...[
                  const Gap(8),
                  Tooltip(
                    message: 'Clear all completed tasks',
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_sweep_outlined,
                        color: cs.error,
                      ),
                      onPressed: () => _confirmClearAll(context, provider),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Text(
                  '${tasks.length} completed task${tasks.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Done task list ────────────────────────────────────────────
          if (provider.loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (tasks.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                    const Gap(16),
                    Text(
                      _query.isNotEmpty
                          ? 'No completed tasks match your search'
                          : 'No completed tasks yet',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 52),
                itemBuilder: (_, i) => _DoneTile(
                  task: tasks[i],
                  onUncomplete: () => _uncomplete(tasks[i], provider),
                  onDelete: () => _delete(tasks[i], provider),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _uncomplete(Task task, AppProvider provider) {
    provider.uncompleteTask(task.id);
    provider.saveAllToPod();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${task.description}" moved back to active.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            provider.completeTask(task.id);
            provider.saveAllToPod();
          },
        ),
      ),
    );
  }

  void _delete(Task task, AppProvider provider) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'Permanently delete "${task.description}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        provider.deleteDoneTask(task.id);
        provider.saveDoneToPod();
      }
    });
  }

  void _confirmClearAll(BuildContext context, AppProvider provider) {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all completed tasks?'),
        content: const Text(
          'This will permanently delete all completed tasks. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        provider.clearDone();
        provider.saveDoneToPod();
      }
    });
  }
}

// ── Done task tile ────────────────────────────────────────────────────────────

class _DoneTile extends StatelessWidget {
  final Task task;
  final VoidCallback onUncomplete;
  final VoidCallback onDelete;

  const _DoneTile({
    required this.task,
    required this.onUncomplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checked checkbox — tapping undoes completion.
          Tooltip(
            message: 'Mark as active again',
            child: Checkbox(
              value: true,
              onChanged: (_) => onUncomplete(),
              shape: const CircleBorder(),
              activeColor: cs.primary,
            ),
          ),
          const Gap(4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion date
                if (task.completionDate != null)
                  Text(
                    'Completed ${_fmtDate(task.completionDate!)}',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                const Gap(2),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                // Tags
                if (_hasTags(task)) ...[
                  const Gap(4),
                  Wrap(
                    spacing: 4,
                    children: [
                      for (final p in task.projects)
                        _SmallChip(label: '+$p', cs: cs),
                      for (final c in task.contexts)
                        _SmallChip(label: '@$c', cs: cs),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Delete button
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
            tooltip: 'Delete permanently',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  bool _hasTags(Task t) =>
      t.projects.isNotEmpty || t.contexts.isNotEmpty;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

class _SmallChip extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _SmallChip({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant,
          ),
        ),
      );
}
