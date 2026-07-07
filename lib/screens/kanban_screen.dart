/// KanbanScreen — board view of tasks grouped by priority or context.
///
// Time-stamp: <2026-06-12>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/screens/kanban_widgets/kanban_col.dart';
import 'package:todopod/screens/kanban_widgets/kanban_column.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/services/task_actions.dart';

// ── Column definitions ────────────────────────────────────────────────────────

const _priorityCols = [
  KanbanCol('A', 'Now', Color(0xFFC62828)),
  KanbanCol('B', 'Today', Color(0xFFF57C00)),
  KanbanCol('C', 'This Week', Color(0xFF00796B)),
  KanbanCol('D', 'Next Week', Color(0xFF1976D2)),
  KanbanCol('E', 'Later', Color(0xFF7B1FA2)),
  KanbanCol('F', 'Parked', Color(0xFF546E7A)),
  KanbanCol(null, 'No Priority', Color(0xFF9E9E9E)),
];

/// Palette cycled through when building context columns dynamically.
const _contextPalette = [
  Color(0xFF00796B),
  Color(0xFF1976D2),
  Color(0xFF7B1FA2),
  Color(0xFFC62828),
  Color(0xFFF57C00),
  Color(0xFF546E7A),
  Color(0xFF2E7D32),
  Color(0xFF5D4037),
];

/// How the board groups tasks into columns.
enum KanbanGroupBy { priority, context }

/// Direction to sort tasks within a column by due date.
enum KanbanSort { oldestFirst, oldestLast }

// ── Screen ────────────────────────────────────────────────────────────────────

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  KanbanGroupBy _groupBy = KanbanGroupBy.priority;
  KanbanSort _sort = KanbanSort.oldestFirst;

  /// Build the context columns from the contexts present across [tasks],
  /// sorted alphabetically, plus a trailing "No Context" column.
  List<KanbanCol> _contextCols(List<Task> tasks) {
    final names = <String>{};
    for (final t in tasks) {
      names.addAll(t.contexts);
    }
    final sorted = names.toList()..sort();
    final cols = <KanbanCol>[];
    for (var i = 0; i < sorted.length; i++) {
      cols.add(
        KanbanCol(
          sorted[i],
          '@${sorted[i]}',
          _contextPalette[i % _contextPalette.length],
        ),
      );
    }
    cols.add(const KanbanCol(null, 'No Context', Color(0xFF9E9E9E)));
    return cols;
  }

  /// Tasks belonging in [col] for the current grouping, sorted by due date
  /// in the selected direction with no-due-date tasks always last.
  List<Task> _tasksFor(KanbanCol col, List<Task> tasks) {
    final List<Task> matched;
    if (_groupBy == KanbanGroupBy.priority) {
      matched = tasks.where((t) => t.priority == col.priority).toList();
    } else if (col.priority == null) {
      // Context grouping, "No Context" column.
      matched = tasks.where((t) => t.contexts.isEmpty).toList();
    } else {
      matched = tasks.where((t) => t.contexts.contains(col.priority)).toList();
    }
    _sortByDueDate(matched);
    return matched;
  }

  /// Sort [tasks] by due date according to [_sort]. Tasks with no due date
  /// are always placed at the end, whichever direction is chosen.
  void _sortByDueDate(List<Task> tasks) {
    final oldestFirst = _sort == KanbanSort.oldestFirst;
    tasks.sort((a, b) {
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1; // no date → end
      if (bd == null) return -1; // no date → end
      return oldestFirst ? ad.compareTo(bd) : bd.compareTo(ad);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tasks = provider.tasks;
    final scrollCtrl = ScrollController();

    final cols = _groupBy == KanbanGroupBy.priority
        ? _priorityCols
        : _contextCols(tasks);

    return Column(
      children: [
        // Grouping + sort selectors.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Group by',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<KanbanGroupBy>(
                    segments: const [
                      ButtonSegment(
                        value: KanbanGroupBy.priority,
                        label: Text('Priority'),
                        icon: Icon(Icons.flag_outlined),
                      ),
                      ButtonSegment(
                        value: KanbanGroupBy.context,
                        label: Text('Context'),
                        icon: Icon(Icons.alternate_email),
                      ),
                    ],
                    selected: {_groupBy},
                    onSelectionChanged: (s) =>
                        setState(() => _groupBy = s.first),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort by',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<KanbanSort>(
                    segments: const [
                      ButtonSegment(
                        value: KanbanSort.oldestFirst,
                        label: Text('Oldest first'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment(
                        value: KanbanSort.oldestLast,
                        label: Text('Oldest last'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                    ],
                    selected: {_sort},
                    onSelectionChanged: (s) => setState(() => _sort = s.first),
                  ),
                ],
              ),
              // Create a new task.
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Task'),
                onPressed: () =>
                    addTaskAction(context: context, provider: provider),
              ),
            ],
          ),
        ),
        if (provider.busy)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                return Scrollbar(
                  controller: scrollCtrl,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cols.map((col) {
                        return KanbanColumn(
                          col: col,
                          tasks: _tasksFor(col, tasks),
                          height: availableHeight - 32,
                          onDropTask: (task) =>
                              _moveTo(context, provider, task, col),
                          onEditTask: (task) => editTaskAction(
                            context: context,
                            provider: provider,
                            task: task,
                          ),
                          onCompleteTask: (task) => completeTaskAction(
                            provider: provider,
                            task: task,
                          ),
                          onDeleteTask: (task) =>
                              _deleteTask(context, provider, task),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _moveTo(
    BuildContext context,
    AppProvider provider,
    Task task,
    KanbanCol col,
  ) {
    if (_groupBy == KanbanGroupBy.priority) {
      if (task.priority == col.priority) return;
      provider.updateTask(task.copyWith(priority: col.priority));
      provider.saveAllToPod();
      return;
    }

    // Context grouping: dropping onto a context column sets that single
    // context (replacing existing contexts); dropping onto "No Context"
    // clears all contexts.
    final target = col.priority; // holds the context name, or null
    if (target == null) {
      if (task.contexts.isEmpty) return;
      provider.updateTask(task.copyWith(contexts: const []));
    } else {
      if (task.contexts.length == 1 && task.contexts.first == target) return;
      provider.updateTask(task.copyWith(contexts: [target]));
    }
    provider.saveAllToPod();
  }

  Future<void> _deleteTask(
    BuildContext context,
    AppProvider provider,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.description}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      provider.deleteTask(task.id);
      provider.saveAllToPod();
    }
  }
}

// ── Column widget ─────────────────────────────────────────────────────────────

// ── Card widget ───────────────────────────────────────────────────────────────
