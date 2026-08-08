/// Shared task action helpers used by Tasks, Planner, and Kanban screens.
///
/// These factor out the open-dialog / update / save patterns that all three
/// screens use identically, so behaviour stays consistent and a future change
/// only needs to happen in one place.
///
// Time-stamp: <2026-05-20>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:todopod/models/task.dart';
import 'package:todopod/pages/task_edit.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/widgets/app_snack_bar.dart';

/// Open the task editor for [task], save any returned changes, and persist
/// to the Pod.
///
/// [focusField], if provided, opens the editor focused on a specific field
/// (used by inline tag-chip editing). The `AppProvider.updateTask` call
/// transparently moves the task to the done list when the edit toggles its
/// completed flag, so both `todo.ttl` and `done.ttl` need saving — hence
/// `saveAllToPod`.
Future<void> editTaskAction({
  required BuildContext context,
  required AppProvider provider,
  required Task task,
  String? focusField,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TaskEdit(
      task: task,
      focusField: focusField,
      onSave: (updated) async {
        provider.updateTask(updated);
        SolidWriteFailures.reportIfFailed(
          await provider.saveAllToPod(),
          during: 'saving the task',
        );
      },
    ),
  );
}

/// Mark [task] complete (moves it from active to done) and persist.
///
/// Confirms with a SnackBar offering Restore, which puts the task straight
/// back on the active list — the same wording the Done screen uses for the
/// same operation. Shown here rather than at each call site so Tasks,
/// Overdue, Planner and Kanban all behave identically. The bar auto-dismisses
/// whether or not Restore is used.
void completeTaskAction({
  required BuildContext context,
  required AppProvider provider,
  required Task task,
}) {
  provider.completeTask(task.id);
  SolidWriteFailures.watch(
    provider.saveAllToPod(),
    during: 'marking the task done',
  );

  showPositiveSnackBar(
    context,
    '"${task.description}" marked done.',
    actionLabel: 'Restore',
    onAction: () {
      provider.uncompleteTask(task.id);
      SolidWriteFailures.watch(
        provider.saveAllToPod(),
        during: 'restoring the task',
      );
    },
  );
}

/// Open the editor to create a new task, add it, and persist.
Future<void> addTaskAction({
  required BuildContext context,
  required AppProvider provider,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TaskEdit(
      onSave: (task) async {
        provider.addTask(task);
        SolidWriteFailures.reportIfFailed(
          await provider.saveTodoToPod(),
          during: 'adding the task',
        );
      },
    ),
  );
}
