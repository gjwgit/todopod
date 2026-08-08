/// TasksScreen — the main task list with sort, filter and search.
///
// Time-stamp: <Wednesday 2026-05-27 11:42:53 +1000 Graham Williams>
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
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';

import 'package:todopod/models/sort_order.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/pages/task_edit.dart';
import 'package:todopod/screens/tasks_widgets/task_empty_state.dart';
import 'package:todopod/screens/tasks_widgets/task_filter_button.dart';
import 'package:todopod/screens/tasks_widgets/task_filter_chips.dart';
import 'package:todopod/screens/tasks_widgets/task_sort_button.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/services/task_actions.dart';
import 'package:todopod/widgets/app_snack_bar.dart';
import 'package:todopod/widgets/startup_overlay.dart';
import 'package:todopod/widgets/task_list_item.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
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

  /// Filters tasks by query. Supports:
  ///   context:xxx  — tasks with that context tag
  ///   project:yyy  — tasks with that project tag
  ///   due:today    — tasks due today
  ///   due:past     — tasks overdue
  ///   due:tomorrow — tasks due tomorrow
  ///   due:week     — tasks due within the next 7 days
  ///   anything else — searches description, contexts, projects

  List<Task> _filterTasks(List<Task> all, String query) {
    if (query.isEmpty) return all;
    final q = query.trim().toLowerCase();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tomorrowDate = todayDate.add(const Duration(days: 1));
    final weekDate = todayDate.add(const Duration(days: 7));

    if (q.startsWith('context:')) {
      final tag = q.substring('context:'.length).trim();
      return all
          .where((t) => t.contexts.any((c) => c.toLowerCase().contains(tag)))
          .toList();
    }
    if (q.startsWith('project:')) {
      final tag = q.substring('project:'.length).trim();
      return all
          .where((t) => t.projects.any((p) => p.toLowerCase().contains(tag)))
          .toList();
    }
    if (q == 'due:today') {
      return all.where((t) {
        if (t.dueDate == null) return false;
        final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return d.isAtSameMomentAs(todayDate);
      }).toList();
    }
    if (q == 'due:past') {
      return all.where((t) {
        if (t.dueDate == null) return false;
        final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return d.isBefore(todayDate);
      }).toList();
    }
    if (q == 'due:tomorrow') {
      return all.where((t) {
        if (t.dueDate == null) return false;
        final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return d.isAtSameMomentAs(tomorrowDate);
      }).toList();
    }
    if (q == 'due:week') {
      return all.where((t) {
        if (t.dueDate == null) return false;
        final d = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
        return !d.isBefore(todayDate) && !d.isAfter(weekDate);
      }).toList();
    }
    // Default: full-text search across description, contexts, projects.
    return all
        .where(
          (t) =>
              t.description.toLowerCase().contains(q) ||
              t.projects.any((p) => p.toLowerCase().contains(q)) ||
              t.contexts.any((c) => c.toLowerCase().contains(q)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;
    final phase = provider.startupPhase;

    if (provider.isStartingUp) {
      return StartupOverlay(phase: phase, child: const SizedBox.expand());
    }

    final allTasks = provider.tasks;
    final tasks = _filterTasks(allTasks, _query);

    // Tasks per priority in the VISIBLE list, so each section header can show
    // its own count. Counted from the filtered list, not all tasks, so the
    // number always matches what is on screen.

    final sectionCounts = <String?, int>{};
    for (final t in tasks) {
      sectionCounts[t.priority] = (sectionCounts[t.priority] ?? 0) + 1;
    }

    return Scaffold(
      body: Column(
        children: [
          // ── Toolbar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                // Search
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Search or add task...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_query.isNotEmpty)
                            MarkdownTooltip(
                              message:
                                  '**Clear search**\n\nRemove the search text and show all tasks.',
                              child: IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _search.clear();
                                  setState(() => _query = '');
                                },
                              ),
                            ),
                          MarkdownTooltip(
                            message:
                                '**Add task**\n\n'
                                'Create a new task, pre-filled with the '
                                'current search text as the title.',
                            child: IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () =>
                                  _addTaskFromSearch(context, provider),
                            ),
                          ),
                        ],
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                    onSubmitted: (_) => _addTaskFromSearch(context, provider),
                  ),
                ),
                const Gap(8),
                const MarkdownTooltip(
                  message: '''

**Search tips**

- Plain text — searches description, contexts and projects
- `context:xxx` — tasks tagged `@xxx`
- `project:yyy` — tasks tagged `+yyy`
- `due:today` — tasks due today
- `due:past` — overdue tasks
- `due:tomorrow` — tasks due tomorrow
- `due:week` — tasks due within 7 days

''',
                  child: Icon(Icons.help_outline, size: 18),
                ),
                const Gap(8),
                // Sort
                TaskSortButton(provider: provider, cs: cs),
                // Filter
                TaskFilterButton(provider: provider, cs: cs),
              ],
            ),
          ),
          if (_hasFilters(provider))
            TaskFilterChips(provider: provider, cs: cs),
          const Divider(height: 1),
          // ── Task list ─────────────────────────────────────────────────
          if (provider.busy)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (tasks.isEmpty)
            Expanded(
              child: TaskEmptyState(
                hasFilters: _query.isNotEmpty || _hasFilters(provider),
                cs: cs,
                onAdd: () => _addTask(context, provider),
              ),
            )
          else
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                onReorderItem: (oldIndex, newIndex) {
                  provider.reorderTask(oldIndex, newIndex, visibleTasks: tasks);
                  provider.saveTodoToPod();
                },
                itemCount: tasks.length,
                itemBuilder: (context, i) {
                  final task = tasks[i];
                  final showHeader =
                      provider.sortOrder == SortOrder.priority &&
                      (i == 0 || tasks[i - 1].priority != task.priority);

                  return ReorderableTaskItem(
                    key: ValueKey(task.id),
                    index: i,
                    task: task,
                    showHeader: showHeader,
                    isFirstHeader: showHeader && i == 0,
                    headerCount: sectionCounts[task.priority],
                    onTap: () => editTaskAction(
                      context: context,
                      provider: provider,
                      task: task,
                    ),
                    onComplete: (_) => completeTaskAction(
                      context: context,
                      provider: provider,
                      task: task,
                    ),
                    onDelete: () => _deleteTask(task, provider),
                    onEditField: (field) => editTaskAction(
                      context: context,
                      provider: provider,
                      task: task,
                      focusField: field,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  bool _hasFilters(AppProvider p) =>
      p.filterProject != null ||
      p.filterContext != null ||
      p.filterPriority != null;

  Future<void> _addTask(
    BuildContext context,
    AppProvider provider, {
    String? initialTitle,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskEdit(
        initialTitle: (initialTitle != null && initialTitle.isNotEmpty)
            ? initialTitle
            : null,
        // 20260729 gjw Confirm only when a task was actually saved. Previously
        // this fired even when the editor was cancelled.
        onSave: (task) async {
          provider.addTask(task);
          await provider.saveTodoToPod();
          if (!context.mounted) return;
          showPositiveSnackBar(context, 'Task added');
        },
      ),
    );
  }

  Future<void> _addTaskFromSearch(
    BuildContext context,
    AppProvider provider,
  ) async {
    final title = _search.text.trim();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskEdit(
        initialTitle: title,
        onSave: (task) async {
          provider.addTask(task);
          await provider.saveTodoToPod();
          // Clear search only after a task was actually saved.
          _search.clear();
          setState(() => _query = '');
          if (!context.mounted) return;
          showPositiveSnackBar(context, 'Task added');
        },
      ),
    );
  }

  void _deleteTask(Task task, AppProvider provider) {
    provider.deleteTask(task.id);
    provider.saveTodoToPod();
  }
}
