/// TaskEmptyState — extracted from tasks_screen_widgets.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/sort_order.dart';
import 'package:todopod/services/app_provider.dart';

class TaskEmptyState extends StatelessWidget {
  final bool hasFilters;
  final ColorScheme cs;
  final VoidCallback onAdd;

  const TaskEmptyState({
    super.key,
    required this.hasFilters,
    required this.cs,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasFilters ? Icons.filter_list_off : Icons.check_circle_outline,
          size: 64,
          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
        ),
        const Gap(16),
        Text(
          hasFilters ? 'No tasks match your filters' : 'No tasks yet',
          style: const TextStyle(fontSize: 16),
        ),
        if (!hasFilters) ...[
          const Gap(24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add your first task'),
            onPressed: onAdd,
          ),
        ],
      ],
    ),
  );
}
