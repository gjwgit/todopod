/// DoneScreen helper widgets — tile, detail viewer, and shared utilities.
///
// Time-stamp: <Friday 2026-03-27 12:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/screens/done_widgets/small_chip.dart';

// ── Done task detail viewer (read-only) ──────────────────────────────────────

/// Show a read-only dialog with the full details of a completed [task],
/// including completed/created/due dates, priority, duration, projects,
/// contexts, and notes (rendered as markdown). Nothing here is editable.
void showDoneTaskDetail(BuildContext context, Task task) {
  final cs = Theme.of(context).colorScheme;

  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      task.description,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.completionDate != null)
                      _detailRow(cs, 'Done', fmtDate(task.completionDate!)),
                    if (task.creationDate != null)
                      _detailRow(cs, 'Created', fmtDate(task.creationDate!)),
                    if (task.dueDate != null)
                      _detailRow(cs, 'Due', fmtDate(task.dueDate!)),
                    if (task.priority != null)
                      _detailRow(cs, 'Priority', task.priorityLabel),
                    if (task.duration != null)
                      _detailRow(cs, 'Duration', task.duration!),
                    if (task.projects.isNotEmpty)
                      _detailRow(
                        cs,
                        'Projects',
                        task.projects.map((p) => '+$p').join(', '),
                      ),
                    if (task.contexts.isNotEmpty)
                      _detailRow(
                        cs,
                        'Contexts',
                        task.contexts.map((c) => '@$c').join(', '),
                      ),
                    if (task.notes != null && task.notes!.isNotEmpty) ...[
                      const Gap(12),
                      Text(
                        'Notes',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      MarkdownBody(data: task.notes!, shrinkWrap: true),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _detailRow(ColorScheme cs, String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 80,
        child: Text(
          label,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
    ],
  ),
);

// ── Date formatter ───────────────────────────────────────────────────────────

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.year}';

// ── Done task tile ───────────────────────────────────────────────────────────

class DoneTile extends StatelessWidget {
  final Task task;
  final VoidCallback onUncomplete;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const DoneTile({
    super.key,
    required this.task,
    required this.onUncomplete,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownTooltip(
              message: '''

**Restore Task**

Mark this task as active again. It moves back to the Tasks list with its
priority, dates and tags intact.

''',
              child: Checkbox(
                value: true,
                onChanged: (_) => onUncomplete(),
                shape: const CircleBorder(),
                activeColor: cs.primary,
              ),
            ),
            const Gap(4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.completionDate != null)
                    Text(
                      'Completed ${fmtDate(task.completionDate!)}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  const Gap(2),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (_hasTags(task)) ...[
                    const Gap(4),
                    Wrap(
                      spacing: 4,
                      children: [
                        for (final p in task.projects)
                          SmallChip(label: '+$p', cs: cs),
                        for (final c in task.contexts)
                          SmallChip(label: '@$c', cs: cs),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            MarkdownTooltip(
              message: '''

**Delete Permanently**

Remove this task from the Done list. This cannot be undone, so use *Restore*
instead if you only want it back on the active list.

''',
              child: IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasTags(Task t) => t.projects.isNotEmpty || t.contexts.isNotEmpty;
}

// ── Small chip ───────────────────────────────────────────────────────────────
