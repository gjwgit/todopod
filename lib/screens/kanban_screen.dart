/// KanbanScreen — board view of tasks grouped by priority.
///
// Time-stamp: <2026-04-27>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/pages/task_edit.dart';
import 'package:todopod/services/app_provider.dart';

// ── Column definitions ────────────────────────────────────────────────────────

class _KanbanCol {
  final String? priority; // null = No Priority
  final String label;
  final Color color;

  const _KanbanCol(this.priority, this.label, this.color);
}

const _cols = [
  _KanbanCol('A', 'Now', Color(0xFFC62828)),
  _KanbanCol('B', 'Today', Color(0xFFF57C00)),
  _KanbanCol('C', 'This Week', Color(0xFF00796B)),
  _KanbanCol('D', 'Next Week', Color(0xFF1976D2)),
  _KanbanCol('E', 'Later', Color(0xFF7B1FA2)),
  _KanbanCol('F', 'Parked', Color(0xFF546E7A)),
  _KanbanCol(null, 'No Priority', Color(0xFF9E9E9E)),
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
                return _KanbanColumn(
                  col: col,
                  tasks: colTasks,
                  height: availableHeight - 32,
                  onDropTask: (task) => _moveTo(context, provider, task, col),
                  onEditTask: (task) => _editTask(context, provider, task),
                  onCompleteTask: (task) =>
                      _completeTask(context, provider, task),
                  onDeleteTask: (task) => _deleteTask(context, provider, task),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _moveTo(
    BuildContext context,
    AppProvider provider,
    Task task,
    _KanbanCol col,
  ) {
    if (task.priority == col.priority) return;
    provider.updateTask(task.copyWith(priority: col.priority));
    provider.saveAllToPod();
  }

  Future<void> _editTask(
    BuildContext context,
    AppProvider provider,
    Task task,
  ) async {
    final updated = await showDialog<Task>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TaskEdit(task: task),
    );
    if (updated != null) {
      provider.updateTask(updated);
      await provider.saveAllToPod();
    }
  }

  void _completeTask(BuildContext context, AppProvider provider, Task task) {
    provider.completeTask(task.id);
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

class _KanbanColumn extends StatefulWidget {
  final _KanbanCol col;
  final List<Task> tasks;
  final double height;
  final void Function(Task) onDropTask;
  final void Function(Task) onEditTask;
  final void Function(Task) onCompleteTask;
  final void Function(Task) onDeleteTask;

  const _KanbanColumn({
    required this.col,
    required this.tasks,
    required this.height,
    required this.onDropTask,
    required this.onEditTask,
    required this.onCompleteTask,
    required this.onDeleteTask,
  });

  @override
  State<_KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<_KanbanColumn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final col = widget.col;
    final count = widget.tasks.length;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (d) => d.data.priority != col.priority,
      onAcceptWithDetails: (d) {
        setState(() => _hovering = false);
        widget.onDropTask(d.data);
      },
      onMove: (_) => setState(() => _hovering = true),
      onLeave: (_) => setState(() => _hovering = false),
      builder: (ctx, accepted, rejected) {
        return SizedBox(
          height: widget.height,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 220,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _hovering
                  ? col.color.withValues(alpha: 0.12)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovering ? col.color : cs.outlineVariant,
                width: _hovering ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: col.color.withValues(alpha: 0.15),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: col.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          col.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: col.color,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: col.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: col.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Cards — scrollable within the column's fixed height.
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.tasks.length,
                    itemBuilder: (_, i) => _KanbanCard(
                      task: widget.tasks[i],
                      col: col,
                      onEdit: widget.onEditTask,
                      onComplete: widget.onCompleteTask,
                      onDelete: widget.onDeleteTask,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Card widget ───────────────────────────────────────────────────────────────

class _KanbanCard extends StatelessWidget {
  final Task task;
  final _KanbanCol col;
  final void Function(Task) onEdit;
  final void Function(Task) onComplete;
  final void Function(Task) onDelete;

  const _KanbanCard({
    required this.task,
    required this.col,
    required this.onEdit,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDue = task.dueDate != null;
    final now = DateTime.now();
    final isOverdue =
        hasDue &&
        task.dueDate!.isBefore(DateTime(now.year, now.month, now.day));

    Widget card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: col.color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () => onEdit(task),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                task.description,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Projects + contexts
              if (task.projects.isNotEmpty || task.contexts.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    for (final p in task.projects)
                      _tag('+$p', cs.primaryContainer, cs.onPrimaryContainer),
                    for (final c in task.contexts)
                      _tag(
                        '@$c',
                        cs.secondaryContainer,
                        cs.onSecondaryContainer,
                      ),
                  ],
                ),
              ],
              // Due date
              if (hasDue) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 12,
                      color: isOverdue ? Colors.red : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _fmtDate(task.dueDate!),
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? Colors.red : cs.onSurfaceVariant,
                        fontWeight: isOverdue
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  MarkdownTooltip(
                    message: '**Delete**\n\nPermanently remove this task.',
                    child: InkWell(
                      onTap: () => onDelete(task),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  MarkdownTooltip(
                    message: '**Mark done**\n\nMark this task as completed.',
                    child: InkWell(
                      onTap: () => onComplete(task),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: col.color.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              task.description,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }

  Widget _tag(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, color: fg)),
  );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
