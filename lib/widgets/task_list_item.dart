/// Task list item — reorderable task row with priority group headers.
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

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/widgets/priority_header.dart';
import 'package:todopod/widgets/task_tile.dart';

// ── Reorderable task item with optional group header ─────────────────────────

class ReorderableTaskItem extends StatelessWidget {
  final int index;
  final Task task;
  final bool showHeader;
  final bool isFirstHeader;
  final VoidCallback onTap;
  final ValueChanged<bool?> onComplete;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onEditField;

  const ReorderableTaskItem({
    super.key,
    required this.index,
    required this.task,
    required this.showHeader,
    this.isFirstHeader = false,
    required this.onTap,
    required this.onComplete,
    this.onDelete,
    this.onEditField,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          PriorityHeader(
            priority: task.priority,
            cs: cs,
            showDivider: !isFirstHeader,
          ),
        Dismissible(
          key: ValueKey('dismiss-${task.id}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(context),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: cs.error,
            child: Icon(Icons.delete_forever, color: cs.onError),
          ),
          onDismissed: (_) => onDelete?.call(),
          child: Row(
            children: [
              Expanded(
                child: TaskTile(
                  task: task,
                  onTap: onTap,
                  onComplete: onComplete,
                  onEditField: onEditField,
                  onDelete: onDelete == null
                      ? null
                      : () async {
                          if (await _confirmDelete(context)) {
                            onDelete!();
                          }
                        },
                ),
              ),
              MarkdownTooltip(
                message:
                    '**Delete task**\n\nSwipe left on the task to delete it.',
                child: ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      size: 20,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
          'This will permanently remove "${task.description}" '
          'without recording it in Done.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }
}

// ── Priority group header ────────────────────────────────────────────────────
