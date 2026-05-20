/// PlannerTile — extracted from planner_screen.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/models/task.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/services/task_actions.dart';

class PlannerTile extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const PlannerTile({
    required this.task,
    required this.onTap,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final priorityColor = task.priority != null
        ? priorityColors[task.priority] ?? cs.primary
        : cs.outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Priority dot
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: priorityColor,
                  shape: BoxShape.circle,
                ),
              ),
              // Description + tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.description,
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (task.projects.isNotEmpty || task.contexts.isNotEmpty)
                      Text(
                        [
                          ...task.projects.map((p) => '+$p'),
                          ...task.contexts.map((c) => '@$c'),
                        ].join(' '),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Complete button
              IconButton(
                icon: const Icon(Icons.check_circle_outline, size: 20),
                onPressed: onComplete,
                color: cs.primary.withValues(alpha: 0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
