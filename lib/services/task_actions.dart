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
import 'package:todopod/utils/defer_task.dart';
import 'package:todopod/utils/escalate_task.dart';
import 'package:todopod/widgets/app_snack_bar.dart';
import 'package:todopod/widgets/due_date_picker_dialog.dart';

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
        // Thrown rather than reported here: TaskEdit must see the failure so
        // it stays open with the work intact, and it does the reporting.
        final error = await provider.saveAllToPod();
        if (error != null) throw Exception(error);
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

/// Starting priorities whose defer step has no fixed due-date rule — B, C, D
/// and E are all "relative" stages (This Week, Next Week, Later, Parked)
/// with no one obvious date, so the user is asked instead of guessing.
/// A → B resolves to a concrete "today" and doesn't need asking.
const _deferPromptPriorities = {'B', 'C', 'D', 'E'};

/// Starting priorities whose escalate step has no fixed due-date rule — the
/// mirror of [_deferPromptPriorities]. B → A and C → B resolve to a concrete
/// "today" and don't need asking.
const _escalatePromptPriorities = {'D', 'E', 'F'};

/// Advance [task] to its next Priority/Due-Date stage (see [deferTask]) and
/// persist.
///
/// A (Now) → B is fully automatic (due today). For every other stage — B, C,
/// D and E, which have no fixed date rule — this prompts for the new due
/// date via [showDueDatePickerDialog] before applying the priority change.
/// Confirms with a SnackBar offering Undo, which restores the task's
/// previous priority and due date. Callers must check [canDeferTask] first —
/// there is no stage past F.
Future<void> deferTaskAction({
  required BuildContext context,
  required AppProvider provider,
  required Task task,
}) async {
  var updated = deferTask(task);
  if (_deferPromptPriorities.contains(task.priority)) {
    final choice = await showDueDatePickerDialog(
      context,
      initialDate: task.dueDate,
    );
    if (choice.cancelled) return;
    if (!context.mounted) return;
    updated = updated.copyWith(dueDate: choice.dueDate);
  }

  provider.updateTask(updated);
  SolidWriteFailures.watch(
    provider.saveTodoToPod(),
    during: 'deferring the task',
  );

  showPositiveSnackBar(
    context,
    '"${task.description}" moved to ${updated.priority}.',
    actionLabel: 'Undo',
    onAction: () {
      provider.updateTask(task);
      SolidWriteFailures.watch(
        provider.saveTodoToPod(),
        during: 'restoring the task',
      );
    },
  );
}

/// Move [task] back to its previous Priority/Due-Date stage (see
/// [escalateTask]) and persist.
///
/// B → A and C → B are fully automatic (due today). For D, E and F — which
/// have no fixed date rule — this prompts for the new due date via
/// [showDueDatePickerDialog] before applying the priority change. Confirms
/// with a SnackBar offering Undo, which restores the task's previous
/// priority and due date. Callers must check [canEscalateTask] first — there
/// is no stage before A.
Future<void> escalateTaskAction({
  required BuildContext context,
  required AppProvider provider,
  required Task task,
}) async {
  var updated = escalateTask(task);
  if (_escalatePromptPriorities.contains(task.priority)) {
    final choice = await showDueDatePickerDialog(
      context,
      initialDate: task.dueDate,
    );
    if (choice.cancelled) return;
    if (!context.mounted) return;
    updated = updated.copyWith(dueDate: choice.dueDate);
  }

  provider.updateTask(updated);
  SolidWriteFailures.watch(
    provider.saveTodoToPod(),
    during: 'escalating the task',
  );

  showPositiveSnackBar(
    context,
    '"${task.description}" moved to ${updated.priority}.',
    actionLabel: 'Undo',
    onAction: () {
      provider.updateTask(task);
      SolidWriteFailures.watch(
        provider.saveTodoToPod(),
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
        // Thrown rather than reported here: TaskEdit must see the failure so
        // it stays open with the work intact, and it does the reporting.
        final error = await provider.saveTodoToPod();
        if (error != null) throw Exception(error);
      },
    ),
  );
}
