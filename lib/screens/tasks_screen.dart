/// TasksScreen — the main task list with sort, filter and search.
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
import 'package:provider/provider.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/pages/task_edit.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/widgets/task_tile.dart';

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
                      hintText: 'Search tasks...',
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
                const Gap(8),
                // Sort
                _SortButton(provider: provider, cs: cs),
                // Filter
                _FilterButton(provider: provider, cs: cs),
              ],
            ),
          ),
          // Active filter chips
          if (_hasFilters(provider))
            _FilterChips(provider: provider, cs: cs),
          const Divider(height: 1),
          // ── Task list ─────────────────────────────────────────────────
          if (provider.loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (tasks.isEmpty)
            Expanded(
              child: _EmptyState(
                hasFilters: _query.isNotEmpty || _hasFilters(provider),
                cs: cs,
                onAdd: () => _addTask(context, provider),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 52),
                itemBuilder: (_, i) => TaskTile(
                  task: tasks[i],
                  onTap: () => _editTask(context, tasks[i], provider),
                  onComplete: (_) => _complete(tasks[i], provider),
                ),
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
    messenger.showSnackBar(
      const SnackBar(content: Text('Task added')),
    );
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
}

// ── Sort button ───────────────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  final AppProvider provider;
  final ColorScheme cs;

  const _SortButton({required this.provider, required this.cs});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOrder>(
      tooltip: 'Sort',
      icon: const Icon(Icons.sort),
      onSelected: provider.setSortOrder,
      itemBuilder: (_) => [
        for (final order in SortOrder.values)
          PopupMenuItem(
            value: order,
            child: Row(
              children: [
                if (provider.sortOrder == order)
                  Icon(Icons.check, size: 16, color: cs.primary)
                else
                  const SizedBox(width: 16),
                const Gap(8),
                Text(_sortLabel(order)),
              ],
            ),
          ),
      ],
    );
  }

  String _sortLabel(SortOrder o) => switch (o) {
        SortOrder.priority => 'Priority',
        SortOrder.dueDate => 'Due Date',
        SortOrder.project => 'Project',
        SortOrder.context => 'Context',
        SortOrder.creationDate => 'Creation Date',
        SortOrder.added => 'Date Added',
      };
}

// ── Filter button ─────────────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final AppProvider provider;
  final ColorScheme cs;

  const _FilterButton({required this.provider, required this.cs});

  @override
  Widget build(BuildContext context) {
    final hasFilter = provider.filterProject != null ||
        provider.filterContext != null ||
        provider.filterPriority != null;

    return IconButton(
      icon: Badge(
        isLabelVisible: hasFilter,
        child: const Icon(Icons.filter_list),
      ),
      tooltip: 'Filter',
      onPressed: () => _showFilterSheet(context),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _FilterSheet(provider: provider),
    );
  }
}

// ── Filter sheet ──────────────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  final AppProvider provider;

  const _FilterSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filter Tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  provider.clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
          const Gap(12),
          // Priority filter
          const Text('Priority', style: TextStyle(fontWeight: FontWeight.w500)),
          const Gap(8),
          Wrap(
            spacing: 8,
            children: [
              for (final p in priorities)
                FilterChip(
                  label: Text('$p — ${priorityLabels[p]}'),
                  selected: provider.filterPriority == p,
                  onSelected: (sel) {
                    provider.setFilterPriority(sel ? p : null);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
          const Gap(12),
          // Project filter
          if (provider.allProjects.isNotEmpty) ...[
            const Text(
              'Project',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in provider.allProjects)
                  FilterChip(
                    label: Text('+$p'),
                    selected: provider.filterProject == p,
                    onSelected: (sel) {
                      provider.setFilterProject(sel ? p : null);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const Gap(12),
          ],
          // Context filter
          if (provider.allContexts.isNotEmpty) ...[
            const Text(
              'Context',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              children: [
                for (final c in provider.allContexts)
                  FilterChip(
                    label: Text('@$c'),
                    selected: provider.filterContext == c,
                    onSelected: (sel) {
                      provider.setFilterContext(sel ? c : null);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ],
          const Gap(16),
        ],
      ),
    );
  }
}

// ── Active filter chips ───────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final AppProvider provider;
  final ColorScheme cs;

  const _FilterChips({required this.provider, required this.cs});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Wrap(
          spacing: 8,
          children: [
            if (provider.filterPriority != null)
              Chip(
                label: Text(
                  '${provider.filterPriority} — '
                  '${priorityLabels[provider.filterPriority]}',
                ),
                onDeleted: () => provider.setFilterPriority(null),
              ),
            if (provider.filterProject != null)
              Chip(
                label: Text('+${provider.filterProject}'),
                onDeleted: () => provider.setFilterProject(null),
              ),
            if (provider.filterContext != null)
              Chip(
                label: Text('@${provider.filterContext}'),
                onDeleted: () => provider.setFilterContext(null),
              ),
          ],
        ),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final ColorScheme cs;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.hasFilters,
    required this.cs,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters
                  ? Icons.filter_list_off
                  : Icons.check_circle_outline,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const Gap(16),
            Text(
              hasFilters ? 'No tasks match your filters' : 'No tasks yet',
              style: const TextStyle(fontSize: 16),
            ),
            if (!hasFilters) ...[
              const Gap(24),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add your first task'),
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      );
}
