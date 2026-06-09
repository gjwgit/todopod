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

import 'package:solidui/solidui.dart' show ensurePodWritable;

import 'package:todopod/models/task.dart';
import 'package:todopod/pages/task_edit.dart';
import 'package:todopod/services/app_provider.dart';
import 'package:todopod/services/pod_write_guard.dart';

/// Open the task editor for [task], save any returned changes, and persist
/// to the Pod.
///
/// [focusField], if provided, opens the editor focused on a specific field
/// (used by inline tag-chip editing). The `AppProvider.updateTask` call
/// transparently moves the task to the done list when the edit toggles its
/// completed flag, so both `todo.ttl` and `done.ttl` need saving — hence
/// `saveAllToPod`.
///
/// The Pod-writable gate is checked *after* the editor returns but *before*
/// the in-memory mutation is applied. Without this, an edit made while the
/// user is logged out (or has no cached Security Key) would update the UI,
/// silently fail to persist, and then be overwritten by the next successful
/// load from the Pod.
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
  if (updated == null) return;
  if (!context.mounted) return;
  if (!await ensurePodWritable(
    context,
    actionDescription: 'saving your changes to this task',
  )) {
    return;
  }
  provider.updateTask(updated);
  if (!context.mounted) return;
  await saveAllAndReport(context, provider);
}

/// Mark [task] complete (moves it from active to done) and persist.
Future<void> completeTaskAction({
  required BuildContext context,
  required AppProvider provider,
  required Task task,
}) async {
  if (!await ensurePodWritable(
    context,
    actionDescription: 'marking this task complete',
  )) {
    return;
  }
  provider.completeTask(task.id);
  if (!context.mounted) return;
  await saveAllAndReport(context, provider);
}
