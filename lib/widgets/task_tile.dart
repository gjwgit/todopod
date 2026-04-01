/// TaskTile — a single task row with checkbox and tag chips.
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

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final ValueChanged<bool?> onComplete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDone = task.completed;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Checkbox(
              value: isDone,
              onChanged: isDone ? null : onComplete,
              shape: const CircleBorder(),
            ),
            const Gap(4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority + description row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.priority != null) ...[
                        _PriorityBadge(priority: task.priority!, cs: cs),
                        const Gap(8),
                      ],
                      Expanded(
                        child: Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 14,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: isDone ? cs.onSurfaceVariant : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Tags row
                  if (_hasTags(task)) ...[
                    const Gap(4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        for (final p in task.projects)
                          _TagChip(
                            label: '+$p',
                            color: cs.primaryContainer,
                            textColor: cs.onPrimaryContainer,
                          ),
                        for (final c in task.contexts)
                          _TagChip(
                            label: '@$c',
                            color: cs.secondaryContainer,
                            textColor: cs.onSecondaryContainer,
                          ),
                        if (task.dueDate != null)
                          _TagChip(
                            label: _fmtDue(task.dueDate!),
                            color: _dueDateColor(task.dueDate!, cs),
                            textColor: cs.onErrorContainer,
                            icon: Icons.event_outlined,
                          ),
                        if (task.duration != null)
                          _TagChip(
                            label: task.duration!,
                            color: cs.surfaceContainerHighest,
                            textColor: cs.onSurfaceVariant,
                            icon: Icons.timer_outlined,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasTags(Task t) =>
      t.projects.isNotEmpty ||
      t.contexts.isNotEmpty ||
      t.dueDate != null ||
      t.duration != null;

  String _fmtDue(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Color _dueDateColor(DateTime due, ColorScheme cs) {
    final today = DateTime.now();
    final diff = due.difference(DateTime(today.year, today.month, today.day));
    if (diff.isNegative) return cs.errorContainer;
    if (diff.inDays <= 1) return cs.errorContainer;
    return cs.tertiaryContainer;
  }
}

// ── Priority badge ────────────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  final String priority;
  final ColorScheme cs;

  const _PriorityBadge({required this.priority, required this.cs});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority, cs);
    final label = priorityLabels[priority] ?? priority;

    return Tooltip(
      message: '$priority — $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          priority,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String p, ColorScheme cs) =>
      priorityColors[p] ?? cs.primary;
}

// ── Tag chip ──────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const _TagChip({
    required this.label,
    required this.color,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: textColor),
          const Gap(2),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
