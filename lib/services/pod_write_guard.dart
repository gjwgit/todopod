/// Helpers for invoking Pod save operations with friendly error reporting.
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart' show showPodAccessExceptionDialog;

import 'package:todopod/services/app_provider.dart';

/// Persist the active task list, reporting any exception via a friendly
/// dialogue.

Future<void> saveTodoAndReport(BuildContext context, AppProvider provider) =>
    _saveAndReport(context, provider.saveTodoToPod);

/// Persist the done task list, reporting any exception via a friendly
/// dialogue.

Future<void> saveDoneAndReport(BuildContext context, AppProvider provider) =>
    _saveAndReport(context, provider.saveDoneToPod);

/// Persist both task lists, reporting any exception via a friendly
/// dialogue.

Future<void> saveAllAndReport(BuildContext context, AppProvider provider) =>
    _saveAndReport(context, provider.saveAllToPod);

Future<void> _saveAndReport(
  BuildContext context,
  Future<Object?> Function() save,
) async {
  final error = await save();
  if (error == null) return;
  if (!context.mounted) return;
  await showPodAccessExceptionDialog(context, error);
}
