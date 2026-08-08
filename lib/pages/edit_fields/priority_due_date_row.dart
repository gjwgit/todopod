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

/// Below this available width, Priority and Duration no longer have room to
/// sit alongside Due Date, so Due Date drops to its own row.
const _narrowBreakpoint = 420.0;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _narrowBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _priorityField(context)),
                  const Gap(12),
                  Expanded(child: _durationField(context)),
                ],
              ),
              const Gap(16),
              _dueDateLabel(context),
              const Gap(8),
              _dueDateInput(context),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _priorityField(context)),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dueDateLabel(context),
                  const Gap(8),
                  _dueDateInput(context),
                ],
              ),
            ),
            const Gap(12),
            Expanded(child: _durationField(context)),
          ],
        );
      },
    );
  }

  Widget _priorityField(BuildContext context) => Column(
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
  );

  Widget _dueDateLabel(BuildContext context) => editSectionLabel(
    context,
    'Due Date',
    tooltip:
        '**Due Date**\n\n'
        'When the task should be completed by.\n\n'
        'Overdue tasks show a red date chip in the task list. '
        'Tasks due today or tomorrow show amber.',
  );

  Widget _dueDateInput(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPickDueDate,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: dueDate != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                  onPressed: onClearDueDate,
                )
              : const Icon(Icons.event_outlined, size: 18),
        ),
        child: Text(
          dueDate != null
              ? '${dueDate!.day.toString().padLeft(2, '0')}/'
                    '${dueDate!.month.toString().padLeft(2, '0')}/'
                    '${dueDate!.year}'
              : 'No due date',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: dueDate != null ? null : cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _durationField(BuildContext context) => Column(
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
  );
}
