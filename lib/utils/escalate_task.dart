/// Move a task back to its previous Priority/Due-Date stage.
///
// Time-stamp: <2026-08-13>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:todopod/models/task.dart';

/// True when [task] has an earlier stage to escalate to. F (Parked)→E→D→C→B→A
/// (Now) is a one-way progression — A and no-priority tasks have nowhere
/// earlier to go.
bool canEscalateTask(Task task) =>
    task.priority != null && task.priority != 'A';

/// Moves [task] back to its previous Priority/Due-Date stage — the mirror of
/// the defer_task.dart progression:
///   • B (Today) → priority A, due today
///   • C (This Week) → priority B, due today
///   • D (Next Week) → priority C, due date unchanged
///   • E (Later) → priority D, due date unchanged
///   • F (Parked) → priority E, due date unchanged
///
/// Callers must check [canEscalateTask] first — there is no stage before A.
Task escalateTask(Task task) {
  assert(canEscalateTask(task), 'escalateTask called with no earlier stage');

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  switch (task.priority) {
    case 'B':
      return task.copyWith(dueDate: todayDate, priority: 'A');
    case 'C':
      return task.copyWith(dueDate: todayDate, priority: 'B');
    case 'D':
      return task.copyWith(priority: 'C');
    case 'E':
      return task.copyWith(priority: 'D');
    default: // 'F'
      return task.copyWith(priority: 'E');
  }
}
