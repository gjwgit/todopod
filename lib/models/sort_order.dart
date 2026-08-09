/// Sort order options for the task list.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

/// How tasks are ordered in the active task list.
enum SortOrder {
  priority,
  dueDate,
  duration,
  project,
  context,
  creationDate,
  added,
}

/// User-facing label for a [SortOrder], shared by the sort and "then by"
/// menus so the two stay in sync.
extension SortOrderLabel on SortOrder {
  String get label => switch (this) {
    SortOrder.priority => 'Priority',
    SortOrder.dueDate => 'Due Date',
    SortOrder.duration => 'Duration',
    SortOrder.project => 'Project',
    SortOrder.context => 'Context',
    SortOrder.creationDate => 'Creation Date',
    SortOrder.added => 'Date Added',
  };
}
