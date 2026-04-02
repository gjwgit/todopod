/// TasksScreen helper widgets — sort, filter, and empty state.
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

import 'package:todopod/constants/app.dart';
import 'package:todopod/services/app_provider.dart';

// ── Sort button ──────────────────────────────────────────────────────────────

class TaskSortButton extends StatelessWidget {
  final AppProvider provider;
  final ColorScheme cs;

  const TaskSortButton({super.key, required this.provider, required this.cs});

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

// ── Filter button ────────────────────────────────────────────────────────────

class TaskFilterButton extends StatelessWidget {
  final AppProvider provider;
  final ColorScheme cs;

  const TaskFilterButton({super.key, required this.provider, required this.cs});

  @override
  Widget build(BuildContext context) {
    final hasFilter =
        provider.filterProject != null ||
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
      builder: (_) => TaskFilterSheet(provider: provider),
    );
  }
}

// ── Filter sheet ─────────────────────────────────────────────────────────────

class TaskFilterSheet extends StatelessWidget {
  final AppProvider provider;

  const TaskFilterSheet({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
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

// ── Active filter chips ──────────────────────────────────────────────────────

class TaskFilterChips extends StatelessWidget {
  final AppProvider provider;
  final ColorScheme cs;

  const TaskFilterChips({super.key, required this.provider, required this.cs});

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

// ── Empty state ──────────────────────────────────────────────────────────────

class TaskEmptyState extends StatelessWidget {
  final bool hasFilters;
  final ColorScheme cs;
  final VoidCallback onAdd;

  const TaskEmptyState({
    super.key,
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
          hasFilters ? Icons.filter_list_off : Icons.check_circle_outline,
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
