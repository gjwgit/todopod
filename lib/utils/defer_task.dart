/// Advance a task to its next Priority/Due-Date stage.
///
// Time-stamp: <2026-08-13>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:todopod/models/task.dart';

/// True when [task] has a further stage to defer to. A(Now)→B→C→D→E→F
/// (Parked) is a one-way progression — F and no-priority tasks have nowhere
/// left to go.
bool canDeferTask(Task task) => task.priority != null && task.priority != 'F';

/// Moves [task] to its next Priority/Due-Date stage:
///   • A (Now) → due today, priority B
///   • B (Today) → due tomorrow, priority C
///   • C (This Week) → due date +1 week, priority D
///   • D (Next Week) → due date +1 week, priority E
///   • E (Later) → priority F, due date unchanged
///
/// Callers must check [canDeferTask] first — there is no stage past F.
Task deferTask(Task task) {
  assert(canDeferTask(task), 'deferTask called with no further stage');

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  switch (task.priority) {
    case 'A':
      return task.copyWith(dueDate: todayDate, priority: 'B');
    case 'B':
      return task.copyWith(
        dueDate: todayDate.add(const Duration(days: 1)),
        priority: 'C',
      );
    case 'C':
      return task.copyWith(
        dueDate: (task.dueDate ?? todayDate).add(const Duration(days: 7)),
        priority: 'D',
      );
    case 'D':
      return task.copyWith(
        dueDate: (task.dueDate ?? todayDate).add(const Duration(days: 7)),
        priority: 'E',
      );
    default: // 'E'
      return task.copyWith(priority: 'F');
  }
}
