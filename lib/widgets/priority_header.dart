/// PriorityHeader — extracted from task_list_item.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/widgets/task_tile.dart';

class PriorityHeader extends StatelessWidget {
  final String? priority;
  final ColorScheme cs;
  final bool showDivider;

  const PriorityHeader({
    super.key,
    required this.priority,
    required this.cs,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final label = priority != null
        ? '$priority — ${priorityLabels[priority] ?? priority}'
        : 'No Priority';
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
