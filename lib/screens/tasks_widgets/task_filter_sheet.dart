/// TaskFilterSheet — extracted from tasks_screen_widgets.dart.
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

class TaskFilterSheet extends StatelessWidget {
  final AppProvider provider;

  const TaskFilterSheet({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filter Tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  provider.clearFilters();
                  Navigator.pop(context);
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
          const Gap(12),
          // Priority filter
          const Text('Priority', style: TextStyle(fontWeight: FontWeight.w500)),
          const Gap(8),
          Wrap(
            spacing: 8,
            children: [
              for (final p in priorities)
                FilterChip(
                  label: Text('$p — ${priorityLabels[p]}'),
                  selected: provider.filterPriority == p,
                  onSelected: (sel) {
                    provider.setFilterPriority(sel ? p : null);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
          const Gap(12),
          // Project filter
          if (provider.allProjects.isNotEmpty) ...[
            const Text(
              'Project',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              children: [
                for (final p in provider.allProjects)
                  FilterChip(
                    label: Text('+$p'),
                    selected: provider.filterProject == p,
                    onSelected: (sel) {
                      provider.setFilterProject(sel ? p : null);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const Gap(12),
          ],
          // Context filter
          if (provider.allContexts.isNotEmpty) ...[
            const Text(
              'Context',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              children: [
                for (final c in provider.allContexts)
                  FilterChip(
                    label: Text('@$c'),
                    selected: provider.filterContext == c,
                    onSelected: (sel) {
                      provider.setFilterContext(sel ? c : null);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ],
          const Gap(16),
        ],
      ),
    );
  }
}
