/// KanbanColumn — one column of the kanban board, with its task list.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/screens/kanban_widgets/kanban_card.dart';
import 'package:todopod/screens/kanban_widgets/kanban_col.dart';

class KanbanColumn extends StatefulWidget {
  final KanbanCol col;
  final List<Task> tasks;
  final double height;
  final void Function(Task) onDropTask;
  final void Function(Task) onEditTask;
  final void Function(Task) onCompleteTask;
  final void Function(Task) onDeleteTask;

  const KanbanColumn({
    super.key,
    required this.col,
    required this.tasks,
    required this.height,
    required this.onDropTask,
    required this.onEditTask,
    required this.onCompleteTask,
    required this.onDeleteTask,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn> {
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
                    itemBuilder: (_, i) => KanbanCard(
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
