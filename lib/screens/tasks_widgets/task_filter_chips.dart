/// TaskFilterChips — extracted from tasks_screen_widgets.dart.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:todopod/constants/app.dart';
import 'package:todopod/services/app_provider.dart';

class TaskFilterChips extends StatelessWidget {
  final AppProvider provider;
  final ColorScheme cs;

  const TaskFilterChips({super.key, required this.provider, required this.cs});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Wrap(
      spacing: 8,
      children: [
        if (provider.filterPriority != null)
          Chip(
            label: Text(
              '${provider.filterPriority} — '
              '${priorityLabels[provider.filterPriority]}',
            ),
            onDeleted: () => provider.setFilterPriority(null),
          ),
        if (provider.filterProject != null)
          Chip(
            label: Text('+${provider.filterProject}'),
            onDeleted: () => provider.setFilterProject(null),
          ),
        if (provider.filterContext != null)
          Chip(
            label: Text('@${provider.filterContext}'),
            onDeleted: () => provider.setFilterContext(null),
          ),
      ],
    ),
  );
}
