/// TasksScreen — the main task list with sort, filter and search.
///
// Time-stamp: <Wednesday 2026-04-01 12:40:18 +1100 Graham Williams>
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
import 'package:todopod/pages/task_edit.dart';
import 'package:todopod/screens/tasks_screen_widgets.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/widgets/task_list_item.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
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

    final allTasks = provider.tasks;
    final tasks = _query.isEmpty
        ? allTasks
        : allTasks.where((t) {
            final q = _query.toLowerCase();
            return t.description.toLowerCase().contains(q) ||
                t.projects.any((p) => p.toLowerCase().contains(q)) ||
                t.contexts.any((c) => c.toLowerCase().contains(q));
          }).toList();

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
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 20),
                            tooltip: 'Create task from search text',
                            onPressed: () =>
                                _addTaskFromSearch(context, provider),
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
          if (provider.loading)
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
                onReorder: (oldIndex, newIndex) {
                  provider.reorderTask(oldIndex, newIndex);
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
                    onTap: () => _editTask(context, task, provider),
                    onComplete: (_) => _complete(task, provider),
                    onDelete: () => _deleteTask(task, provider),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context, provider),
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ),
    );
  }

  bool _hasFilters(AppProvider p) =>
      p.filterProject != null ||
      p.filterContext != null ||
      p.filterPriority != null;

  Future<void> _addTask(BuildContext context, AppProvider provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final task = await showDialog<Task>(
      context: context,
      builder: (_) => const TaskEdit(),
    );
    if (task != null) {
      provider.addTask(task);
      await provider.saveTodoToPod();
    }
    if (!context.mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Task added')));
  }

  Future<void> _addTaskFromSearch(
    BuildContext context,
    AppProvider provider,
  ) async {
    final title = _search.text.trim();
    _search.clear();
    setState(() => _query = '');

    final messenger = ScaffoldMessenger.of(context);
    final task = await showDialog<Task>(
      context: context,
      builder: (_) => TaskEdit(initialTitle: title),
    );
    if (task != null) {
      provider.addTask(task);
      await provider.saveTodoToPod();
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Task added')));
    }
  }

  Future<void> _editTask(
    BuildContext context,
    Task task,
    AppProvider provider,
  ) async {
    final updated = await showDialog<Task>(
      context: context,
      builder: (_) => TaskEdit(task: task),
    );
    if (updated != null) {
      provider.updateTask(updated);
      await provider.saveTodoToPod();
    }
  }

  void _complete(Task task, AppProvider provider) {
    provider.completeTask(task.id);
    provider.saveAllToPod();
  }

  void _deleteTask(Task task, AppProvider provider) {
    provider.deleteTask(task.id);
    provider.saveTodoToPod();
  }
}
