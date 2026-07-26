/// Overdue helpers — how far past its due date a task is.
///
// Time-stamp: <Sunday 2026-07-26 09:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

/// Whole days between [due] and today, positive when [due] is in the past.
///
/// Both dates are truncated to midnight so the result is a calendar-day count
/// and not affected by the time of day. [now] is injectable for testing.

int daysOverdue(DateTime due, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final dueDay = DateTime(due.year, due.month, due.day);

  return today.difference(dueDay).inDays;
}

/// True when [due] is a calendar date strictly before today.
///
/// A task due today is NOT overdue — there is still time to do it.

bool isOverdue(DateTime? due, {DateTime? now}) =>
    due != null && daysOverdue(due, now: now) > 0;

/// Short human-readable label for how late [due] is, e.g. "3 days late".
///
/// Returns an empty string when [due] is not in the past.

String overdueLabel(DateTime due, {DateTime? now}) {
  final days = daysOverdue(due, now: now);
  if (days <= 0) return '';
  if (days == 1) return '1 day late';
  if (days < 14) return '$days days late';
  if (days < 60) return '${days ~/ 7} weeks late';

  return '${days ~/ 30} months late';
}
