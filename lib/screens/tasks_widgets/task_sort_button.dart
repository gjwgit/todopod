/// TaskSortButton — extracted from tasks_screen_widgets.dart.
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

import 'package:todopod/models/sort_order.dart';
import 'package:todopod/services/app_provider.dart';

class TaskSortButton extends StatelessWidget {
  final AppProvider provider;
  final ColorScheme cs;

  const TaskSortButton({super.key, required this.provider, required this.cs});

  @override
  Widget build(BuildContext context) {
    return MarkdownTooltip(
      message: '**Sort**\n\nChange the order in which tasks are listed.',
      child: PopupMenuButton<SortOrder>(
        tooltip: '', // suppress Flutter's default "Show menu" tooltip
        icon: const Icon(Icons.sort),
        onSelected: provider.setSortOrder,
        itemBuilder: (_) => [
          for (final order in SortOrder.values)
            PopupMenuItem(
              value: order,
              child: Row(
                children: [
                  if (provider.sortOrder == order)
                    Icon(Icons.check, size: 16, color: cs.primary)
                  else
                    const SizedBox(width: 16),
                  const Gap(8),
                  Text(_sortLabel(order)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _sortLabel(SortOrder o) => switch (o) {
    SortOrder.priority => 'Priority',
    SortOrder.dueDate => 'Due Date',
    SortOrder.project => 'Project',
    SortOrder.context => 'Context',
    SortOrder.creationDate => 'Creation Date',
    SortOrder.added => 'Date Added',
  };
}
