/// OverdueScreen — active tasks whose due date has passed.
///
// Time-stamp: <Sunday 2026-07-26 09:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:provider/provider.dart';

import 'package:todopod/services/app_provider.dart';
import 'package:todopod/services/task_actions.dart';
import 'package:todopod/services/view_prefs.dart';
import 'package:todopod/utils/overdue.dart';
import 'package:todopod/widgets/task_tile.dart';

class OverdueScreen extends StatefulWidget {
  const OverdueScreen({super.key});

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen> {
  /// Sort direction for the list. Starts oldest due date first, so the
  /// longest-overdue task is at the top, then follows whatever direction was
  /// last chosen on this device. A view preference only — kept in
  /// SharedPreferences via ViewPrefs, never written to the Pod.

  bool _oldestFirst = true;

  @override
  void initState() {
    super.initState();
    _restoreSortOrder();
  }

  /// Restore the last-chosen direction. The list paints immediately with the
  /// default and flips once the stored preference arrives, so there is no
  /// spinner for a single bool.

  Future<void> _restoreSortOrder() async {
    final oldestFirst = await ViewPrefs.getBool(
      ViewPrefs.overdueOldestFirst,
      orElse: true,
    );
    if (!mounted || oldestFirst == _oldestFirst) return;

    setState(() => _oldestFirst = oldestFirst);
  }

  /// Reverse the direction and remember the choice.
  ///
  /// Saved here, on the toggle itself, rather than in dispose — Linux desktop
  /// lifecycle callbacks are unreliable on window close.

  Future<void> _toggleSortOrder() async {
    final oldestFirst = !_oldestFirst;
    setState(() => _oldestFirst = oldestFirst);
    await ViewPrefs.setBool(ViewPrefs.overdueOldestFirst, oldestFirst);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cs = Theme.of(context).colorScheme;

    // The provider hands back oldest due date first; reverse in place for the
    // other direction rather than re-sorting.

    final overdue = provider.overdueTasks;
    final tasks = _oldestFirst ? overdue : overdue.reversed.toList();

    final orderLabel = _oldestFirst ? 'oldest first' : 'most recent first';
    final canReverse = tasks.length > 1;

    return Scaffold(
      body: Column(
        children: [
          // ── Summary line and sort toggle ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.event_busy, size: 16, color: cs.error),
                const Gap(8),
                Expanded(
                  child: Text(
                    '${tasks.length} overdue task'
                    '${tasks.length == 1 ? '' : 's'} — $orderLabel',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ),
                MarkdownTooltip(
                  message: _sortTip(orderLabel, canReverse),
                  child: IconButton(
                    icon: const Icon(Icons.swap_vert, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: canReverse ? _toggleSortOrder : null,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Overdue task list ─────────────────────────────────────────
          if (provider.busy)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (tasks.isEmpty)
            Expanded(child: _emptyState(cs))
          else
            Expanded(
              child: ListView.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 52),
                itemBuilder: (_, i) => Row(
                  children: [
                    Expanded(
                      child: TaskTile(
                        task: tasks[i],
                        onTap: () => editTaskAction(
                          context: context,
                          provider: provider,
                          task: tasks[i],
                        ),
                        onComplete: (_) => completeTaskAction(
                          context: context,
                          provider: provider,
                          task: tasks[i],
                        ),
                        onEditField: (field) => editTaskAction(
                          context: context,
                          provider: provider,
                          task: tasks[i],
                          focusField: field,
                        ),
                      ),
                    ),
                    // How late the task is, so the worst stand out.
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        overdueLabel(tasks[i].dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Tooltip for the sort toggle. MarkdownTooltip wraps the button, so the
  /// message also shows while the button is disabled — use it to explain why.

  String _sortTip(String orderLabel, bool canReverse) => canReverse
      ? '''

**Reverse sort order**

Overdue tasks are listed by due date, $orderLabel. Tap to reverse the order.

'''
      : '''

**Reverse sort order**

Available once there is more than one overdue task.

''';

  Widget _emptyState(ColorScheme cs) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.event_available_outlined,
          size: 64,
          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
        ),
        const Gap(16),
        const Text(
          'Nothing overdue — you are up to date',
          style: TextStyle(fontSize: 16),
        ),
      ],
    ),
  );
}
