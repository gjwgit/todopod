/// TaskTile — a single task row with checkbox and tag chips.
///
// Time-stamp: <Tuesday 2026-05-19 07:40:48 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/utils/defer_task.dart';
import 'package:todopod/utils/escalate_task.dart';
import 'package:todopod/widgets/priority_badge.dart';
import 'package:todopod/widgets/tag_chip.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final ValueChanged<bool?> onComplete;
  final ValueChanged<String>? onEditField;
  final VoidCallback? onDelete;
  final VoidCallback? onDefer;
  final VoidCallback? onEscalate;

  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
    required this.onComplete,
    this.onEditField,
    this.onDelete,
    this.onDefer,
    this.onEscalate,
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
            MarkdownTooltip(
              message: isDone
                  ? '''

**Task Done**

This task is already complete. Restore it from the Done screen if you need
it back on the active list.

'''
                  : '''

**Mark Done**

Complete this task. It moves to the Done list, and the confirmation offers
*Restore* if you change your mind.

''',
              child: Checkbox(
                value: isDone,
                onChanged: isDone ? null : onComplete,
                shape: const CircleBorder(),
              ),
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
                        PriorityBadge(priority: task.priority!, cs: cs),
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
                            color: isDone
                                ? cs.onSurfaceVariant
                                : _titleColor(task.dueDate, cs),
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
                          TagChip(
                            label: '+$p',
                            color: cs.primaryContainer,
                            textColor: cs.onPrimaryContainer,
                            onTap: onEditField != null
                                ? () => onEditField!('projects')
                                : null,
                          ),
                        for (final c in task.contexts)
                          TagChip(
                            label: '@$c',
                            color: cs.secondaryContainer,
                            textColor: cs.onSecondaryContainer,
                            onTap: onEditField != null
                                ? () => onEditField!('contexts')
                                : null,
                          ),
                        if (task.dueDate != null)
                          TagChip(
                            label: _fmtDue(task.dueDate!),
                            color: _dueDateColor(task.dueDate!, cs),
                            textColor: cs.onErrorContainer,
                            icon: Icons.event_outlined,
                          ),
                        if (task.duration != null)
                          TagChip(
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
            // Escalate to the previous Priority/Due-Date stage.
            if (onEscalate != null)
              MarkdownTooltip(
                message: _escalateTooltip(),
                child: IconButton(
                  icon: Icon(
                    Icons.priority_high_outlined,
                    size: 16,
                    color: cs.primary.withValues(
                      alpha: canEscalateTask(task) ? 0.6 : 0.3,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: canEscalateTask(task) ? onEscalate : null,
                ),
              ),
            // Defer to the next Priority/Due-Date stage.
            if (onDefer != null)
              MarkdownTooltip(
                message: _deferTooltip(),
                child: IconButton(
                  icon: Icon(
                    Icons.next_plan_outlined,
                    size: 16,
                    color: cs.primary.withValues(
                      alpha: canDeferTask(task) ? 0.6 : 0.3,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: canDeferTask(task) ? onDefer : null,
                ),
              ),
            // Delete button (replaces former notes-info icon).
            if (onDelete != null)
              MarkdownTooltip(
                message: _buildTooltip(),
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red.withValues(alpha: 0.6),
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildTooltip() {
    final hasNotes = task.notes != null && task.notes!.isNotEmpty;
    final deleteBlurb = '**Delete task**\n\nPermanently remove this task.';
    if (!hasNotes) return deleteBlurb;
    // Ensure lines starting with `+` are separated by a blank line so they
    // render as distinct paragraphs rather than a collapsed list in Markdown.
    final lines = task.notes!.split('\n');
    final buf = StringBuffer();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('+') && i > 0 && lines[i - 1].isNotEmpty) {
        buf.writeln();
      }
      buf.writeln(line);
    }
    return '$deleteBlurb\n\n---\n\n**Notes**\n\n${buf.toString().trimRight()}';
  }

  String _deferTooltip() {
    const title = '**Defer**';
    if (!canDeferTask(task)) {
      final why = task.priority == null
          ? "there's no priority set to advance from"
          : 'Parked (F) is already the last stage';
      return '$title\n\nNot available — $why.';
    }
    final blurb = switch (task.priority) {
      'A' =>
        'Moves this task to priority B (${priorityLabels['B']}), '
            'due today.',
      'B' =>
        'Moves this task to priority C (${priorityLabels['C']}), '
            'due tomorrow.',
      'C' =>
        'Moves this task to priority D (${priorityLabels['D']}), '
            'pushing its due date out by a week.',
      'D' =>
        'Moves this task to priority E (${priorityLabels['E']}), '
            'pushing its due date out by a week.',
      _ =>
        'Moves this task to priority F (${priorityLabels['F']}). '
            'Its due date is left unchanged.',
    };
    return '$title\n\n$blurb';
  }

  String _escalateTooltip() {
    const title = '**Escalate**';
    if (!canEscalateTask(task)) {
      final why = task.priority == null
          ? "there's no priority set to bring forward"
          : 'Now (A) is already the first stage';
      return '$title\n\nNot available — $why.';
    }
    final blurb = switch (task.priority) {
      'B' =>
        'Moves this task to priority A (${priorityLabels['A']}), '
            'due today.',
      'C' =>
        'Moves this task to priority B (${priorityLabels['B']}), '
            'due today.',
      'D' =>
        'Moves this task to priority C (${priorityLabels['C']}). '
            'Its due date is left unchanged.',
      'E' =>
        'Moves this task to priority D (${priorityLabels['D']}). '
            'Its due date is left unchanged.',
      _ =>
        'Moves this task to priority E (${priorityLabels['E']}). '
            'Its due date is left unchanged.',
    };
    return '$title\n\n$blurb';
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

  /// Returns a title colour based on the due date:
  /// - Past due → red (error colour)
  /// - Due today → green
  /// - No due date or future → default (null = theme default)

  Color? _titleColor(DateTime? due, ColorScheme cs) {
    if (due == null) return null;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dueDate = DateTime(due.year, due.month, due.day);
    if (dueDate.isBefore(todayDate)) return cs.error;
    if (dueDate.isAtSameMomentAs(todayDate)) return Colors.green;
    return null;
  }
}

// ── Priority badge ────────────────────────────────────────────────────────────

// ── Tag chip ──────────────────────────────────────────────────────────────────
