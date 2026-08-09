/// TaskSubSortButton — "then by" tie-breaker within the primary sort order.
///
// Time-stamp: <2026-08-09>
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

/// Sort orders offered as a sub-order. Excludes [SortOrder.added] (it never
/// compares, so it can't break a tie) and whichever order is currently
/// primary (comparing a criterion against itself is a no-op).
List<SortOrder> _subSortOptions(SortOrder primary) => SortOrder.values
    .where((o) => o != SortOrder.added && o != primary)
    .toList();

class TaskSubSortButton extends StatelessWidget {
  final AppProvider provider;
  final ColorScheme cs;

  const TaskSubSortButton({
    super.key,
    required this.provider,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final isAdded = provider.sortOrder == SortOrder.added;

    return MarkdownTooltip(
      message: isAdded
          ? '''

**Then By**

Not available when sorted by Date Added — that order isn't grouped, so
there's nothing to break ties within.

'''
          : '''

**Then By**

Choose a tie-breaker applied within each group of the main sort order.

For example, sort by Priority then by Duration to tackle the shortest
task in each priority group first.

''',
      child: PopupMenuButton<SortOrder?>(
        tooltip: '', // suppress Flutter's default "Show menu" tooltip
        enabled: !isAdded,
        icon: const Icon(Icons.low_priority),
        onSelected: provider.setSubSortOrder,
        itemBuilder: (_) => [
          PopupMenuItem(
            value: null,
            child: Row(
              children: [
                if (provider.subSortOrder == null)
                  Icon(Icons.check, size: 16, color: cs.primary)
                else
                  const SizedBox(width: 16),
                const Gap(8),
                const Text('None'),
              ],
            ),
          ),
          for (final order in _subSortOptions(provider.sortOrder))
            PopupMenuItem(
              value: order,
              child: Row(
                children: [
                  if (provider.subSortOrder == order)
                    Icon(Icons.check, size: 16, color: cs.primary)
                  else
                    const SizedBox(width: 16),
                  const Gap(8),
                  Text(order.label),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
