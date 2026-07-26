/// PriorityHeader — extracted from task_list_item.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:todopod/constants/app.dart';

class PriorityHeader extends StatelessWidget {
  final String? priority;
  final ColorScheme cs;
  final bool showDivider;

  /// Number of tasks in this section, appended to the label. Omitted when
  /// null, so callers that have no count still render a plain header.

  final int? count;

  const PriorityHeader({
    super.key,
    required this.priority,
    required this.cs,
    this.showDivider = true,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final name = priority != null
        ? '$priority — ${priorityLabels[priority] ?? priority}'
        : 'No Priority';
    final label = count == null
        ? name
        : '$name — $count task${count == 1 ? '' : 's'}';
    final color = priority != null
        ? (priorityColors[priority] ?? cs.primary)
        : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDivider) const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
