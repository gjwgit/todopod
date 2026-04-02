/// TaskEdit form field widgets — priority/date row and tag list builder.
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
import 'package:todopod/widgets/tag_autocomplete.dart';

// ── Priority + Due Date row ──────────────────────────────────────────────────

class PriorityDueDateRow extends StatelessWidget {
  final String? priority;
  final DateTime? dueDate;
  final ValueChanged<String?> onPriorityChanged;
  final VoidCallback onPickDueDate;
  final VoidCallback onClearDueDate;

  const PriorityDueDateRow({
    super.key,
    required this.priority,
    required this.dueDate,
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
              editSectionLabel(context, 'Priority'),
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
              editSectionLabel(context, 'Due Date'),
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
      ],
    );
  }
}

// ── Tag list (projects / contexts) ───────────────────────────────────────────

class TagListEditor extends StatelessWidget {
  final String label;
  final String prefix;
  final List<TextEditingController> controllers;
  final List<String> options;
  final String hintText;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const TagListEditor({
    super.key,
    required this.label,
    required this.prefix,
    required this.controllers,
    required this.options,
    required this.hintText,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      editSectionLabel(context, label),
      const Gap(8),
      ...controllers.asMap().entries.map(
        (e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(prefix, style: const TextStyle(fontSize: 16)),
              const Gap(8),
              Expanded(
                child: TagAutocomplete(
                  controller: e.value,
                  options: options,
                  hintText: hintText,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                onPressed: () => onRemove(e.key),
              ),
            ],
          ),
        ),
      ),
      TextButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: Text('Add ${label.toLowerCase()}'),
        onPressed: onAdd,
      ),
    ],
  );
}
