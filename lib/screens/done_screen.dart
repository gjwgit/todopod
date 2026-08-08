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

import 'package:emacs_text_field/emacs_text_field.dart'
    show attachPrimarySelection;
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/screens/done_widgets/done_tile.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/widgets/app_snack_bar.dart';

class DoneScreen extends StatefulWidget {
  const DoneScreen({super.key});

  @override
  State<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends State<DoneScreen> {
  final _search = TextEditingController();
  late final VoidCallback _removePrimarySearch;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _removePrimarySearch = attachPrimarySelection(_search);
  }

  @override
  void dispose() {
    _removePrimarySearch();
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (all.isNotEmpty) ...[
                  const Gap(8),
                  Tooltip(
                    message: 'Clear all completed tasks',
                    child: IconButton(
                      icon: Icon(Icons.delete_sweep_outlined, color: cs.error),
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
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Done task list ────────────────────────────────────────────
          if (provider.busy)
            const Expanded(child: Center(child: CircularProgressIndicator()))
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
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 52),
                itemBuilder: (_, i) => DoneTile(
                  task: tasks[i],
                  onTap: () => showDoneTaskDetail(context, tasks[i]),
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
    SolidWriteFailures.watch(
      provider.saveAllToPod(),
      during: 'restoring the task',
    );
    showPositiveSnackBar(
      context,
      '"${task.description}" moved back to active.',
      actionLabel: 'Undo',
      onAction: () {
        provider.completeTask(task.id);
        SolidWriteFailures.watch(
          provider.saveAllToPod(),
          during: 'marking the task done',
        );
      },
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
        SolidWriteFailures.watch(
          provider.saveDoneToPod(),
          during: 'deleting the task',
        );
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
        SolidWriteFailures.watch(
          provider.saveDoneToPod(),
          during: 'clearing completed tasks',
        );
      }
    });
  }
}
