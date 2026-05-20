/// KanbanCard — extracted from kanban_screen.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/screens/kanban_widgets/kanban_col.dart';

class KanbanCard extends StatelessWidget {
  final Task task;
  final KanbanCol col;
  final void Function(Task) onEdit;
  final void Function(Task) onComplete;
  final void Function(Task) onDelete;

  const KanbanCard({
    super.key,
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
