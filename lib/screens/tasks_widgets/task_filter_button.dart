/// TaskFilterButton — extracted from tasks_screen_widgets.dart.
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
import 'package:todopod/screens/tasks_widgets/task_filter_sheet.dart';
import 'package:todopod/services/app_provider.dart';

class TaskFilterButton extends StatelessWidget {
  final AppProvider provider;
  final ColorScheme cs;

  const TaskFilterButton({super.key, required this.provider, required this.cs});

  @override
  Widget build(BuildContext context) {
    final hasFilter =
        provider.filterProject != null ||
        provider.filterContext != null ||
        provider.filterPriority != null;

    return MarkdownTooltip(
      message: '**Filter**\n\nFilter tasks by priority, project or context.',
      child: IconButton(
        icon: Badge(
          isLabelVisible: hasFilter,
          child: const Icon(Icons.filter_list),
        ),
        onPressed: () => _showFilterSheet(context),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => TaskFilterSheet(provider: provider),
    );
  }
}
