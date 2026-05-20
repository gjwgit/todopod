/// PriorityBadge — extracted from task_tile.dart.
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

class PriorityBadge extends StatelessWidget {
  final String priority;
  final ColorScheme cs;

  const PriorityBadge({super.key, required this.priority, required this.cs});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority, cs);
    final label = priorityLabels[priority] ?? priority;

    return MarkdownTooltip(
      message: '**Priority $priority** — $label',
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
