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

import 'package:todopod/models/task.dart';
import 'package:todopod/pages/task_edit.dart';
import 'package:todopod/services/app_provider.dart';

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
  final updated = await showDialog<Task>(
    context: context,
    barrierDismissible: false,
    builder: (_) => TaskEdit(task: task, focusField: focusField),
  );
  if (updated != null) {
    provider.updateTask(updated);
    await provider.saveAllToPod();
  }
}

/// Mark [task] complete (moves it from active to done) and persist.
void completeTaskAction({required AppProvider provider, required Task task}) {
  provider.completeTask(task.id);
  provider.saveAllToPod();
}

/// Open the editor to create a new task, add it, and persist.
Future<void> addTaskAction({
  required BuildContext context,
  required AppProvider provider,
}) async {
  final task = await showDialog<Task>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const TaskEdit(),
  );
  if (task != null) {
    provider.addTask(task);
    await provider.saveTodoToPod();
  }
}
