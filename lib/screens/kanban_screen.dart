/// KanbanScreen — board view of tasks grouped by priority.
///
// Time-stamp: <2026-04-27>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:solidui/solidui.dart' show ensurePodWritable;

import 'package:todopod/models/task.dart';
import 'package:todopod/screens/kanban_widgets/kanban_col.dart';
import 'package:todopod/screens/kanban_widgets/kanban_column.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/services/pod_write_guard.dart';
import 'package:todopod/services/task_actions.dart';

// ── Column definitions ────────────────────────────────────────────────────────

const _cols = [
  KanbanCol('A', 'Now', Color(0xFFC62828)),
  KanbanCol('B', 'Today', Color(0xFFF57C00)),
  KanbanCol('C', 'This Week', Color(0xFF00796B)),
  KanbanCol('D', 'Next Week', Color(0xFF1976D2)),
  KanbanCol('E', 'Later', Color(0xFF7B1FA2)),
  KanbanCol('F', 'Parked', Color(0xFF546E7A)),
  KanbanCol(null, 'No Priority', Color(0xFF9E9E9E)),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tasks = provider.tasks;
    final scrollCtrl = ScrollController();

    return LayoutBuilder(
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
              children: _cols.map((col) {
                final colTasks = tasks
                    .where((t) => t.priority == col.priority)
                    .toList();
                return KanbanColumn(
                  col: col,
                  tasks: colTasks,
                  height: availableHeight - 32,
                  onDropTask: (task) => _moveTo(context, provider, task, col),
                  onEditTask: (task) => editTaskAction(
                    context: context,
                    provider: provider,
                    task: task,
                  ),
                  onCompleteTask: (task) => completeTaskAction(
                    context: context,
                    provider: provider,
                    task: task,
                  ),
                  onDeleteTask: (task) => _deleteTask(context, provider, task),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _moveTo(
    BuildContext context,
    AppProvider provider,
    Task task,
    KanbanCol col,
  ) async {
    if (task.priority == col.priority) return;
    if (!await ensurePodWritable(
      context,
      actionDescription: 'moving this task',
    )) {
      return;
    }
    provider.updateTask(task.copyWith(priority: col.priority));
    if (!context.mounted) return;
    await saveAllAndReport(context, provider);
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
    if (confirmed != true) return;
    if (!context.mounted) return;
    if (!await ensurePodWritable(
      context,
      actionDescription: 'deleting this task',
    )) {
      return;
    }
    provider.deleteTask(task.id);
    if (!context.mounted) return;
    await saveAllAndReport(context, provider);
  }
}

// ── Column widget ─────────────────────────────────────────────────────────────

// ── Card widget ───────────────────────────────────────────────────────────────
