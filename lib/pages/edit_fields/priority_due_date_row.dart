/// PriorityDueDateRow — extracted from task_edit_form_fields.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/widgets/tag_autocomplete.dart';

class PriorityDueDateRow extends StatelessWidget {
  final String? priority;
  final DateTime? dueDate;
  final TextEditingController durationController;
  final ValueChanged<String?> onPriorityChanged;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;

  const PriorityDueDateRow({
    super.key,
    required this.priority,
    required this.dueDate,
    required this.durationController,
    required this.onPriorityChanged,
    required this.onPickDueDate,
    required this.onClearDueDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              editSectionLabel(
                context,
                'Priority',
                tooltip:
                    '**Priority**\n\n'
                    'Task importance level from A (Critical) to F (Later).\n\n'
                    'Tasks are grouped by priority when sorted. '
                    'Drag a task between groups to change its priority.',
              ),
              const Gap(8),
              DropdownButtonFormField<String?>(
                initialValue: priority,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(child: Text('None')),
                  ...priorities.map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text('$p — ${priorityLabels[p]}'),
                    ),
                  ),
                ],
                isExpanded: true,
                onChanged: onPriorityChanged,
              ),
            ],
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              editSectionLabel(
                context,
                'Due Date',
                tooltip:
                    '**Due Date**\n\n'
                    'When the task should be completed by.\n\n'
                    'Overdue tasks show a red date chip in the task list. '
                    'Tasks due today or tomorrow show amber.',
              ),
              const Gap(8),
              InkWell(
                onTap: onPickDueDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: Icon(Icons.event_outlined, size: 18),
                  ),
                  child: Text(
                    dueDate != null
                        ? '${dueDate!.day.toString().padLeft(2, '0')}/'
                              '${dueDate!.month.toString().padLeft(2, '0')}/'
                              '${dueDate!.year}'
                        : 'No due date',
                    style: TextStyle(
                      color: dueDate != null ? null : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (dueDate != null)
                TextButton(
                  onPressed: onClearDueDate,
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              editSectionLabel(
                context,
                'Duration',
                tooltip:
                    '**Duration**\n\n'
                    'Estimated time to complete the task.\n\n'
                    'Free-text — common formats include '
                    '*30m*, *1h*, *2h30m*, *15min*.',
              ),
              const Gap(8),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  hintText: '30m, 1h, 2h30m',
                  prefixText: '= ',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
