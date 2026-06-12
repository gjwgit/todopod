/// Derive a task priority from its due date.
///
// Time-stamp: <2026-06-12>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

/// Derive a task priority from its [due] date, used for new tasks:
///   • today or no date (or earlier) → B
///   • later this week, up to and including the coming Sunday → C
///   • the following week (through the Sunday after) → D
///   • later than that → E
String priorityFromDueDate(DateTime? due) {
  if (due == null) return 'B';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(due.year, due.month, due.day);

  if (!dueDay.isAfter(today)) return 'B'; // today or earlier

  // End of this week = the coming Sunday (DateTime weekday: Mon=1..Sun=7).
  final endOfThisWeek = today.add(Duration(days: 7 - today.weekday));
  if (!dueDay.isAfter(endOfThisWeek)) return 'C';

  // End of next week = the Sunday after that.
  final endOfNextWeek = endOfThisWeek.add(const Duration(days: 7));
  if (!dueDay.isAfter(endOfNextWeek)) return 'D';

  return 'E';
}
