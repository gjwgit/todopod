/// File export helpers for todopod — Todo.txt and JSON backup writing.
///
/// These wrap the file-picker save dialog, which writes the bytes itself,
/// returning the saved path (or null if cancelled) so the calling screen
/// can show an appropriate status message. Kept separate to keep the
/// import/backup screen focused on layout and state.
///
// Time-stamp: <Friday 2026-07-17 09:03:11 +1000 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'package:todopod/models/task.dart';

/// Write [tasks] as Todo.txt lines to a user-chosen file.
/// Returns the saved path, or null if the user cancelled.
Future<String?> saveTasksTxt({
  required List<Task> tasks,
  required String prefix,
  required String timestamp,
}) async {
  final fileUri = await FilePicker.saveFile(
    dialogTitle: 'Save $prefix.txt',
    fileName: '${prefix}_$timestamp.txt',
    type: FileType.any,
    bytes: utf8.encode(tasks.map((t) => t.toTodoTxt()).join('\n')),
  );
  if (fileUri == null) return null;
  return fileUri.path;
}

/// Write a JSON backup of [tasks] and [done] to a user-chosen file.
/// Returns the saved path, or null if the user cancelled.
Future<String?> saveTasksJsonBackup({
  required List<Task> tasks,
  required List<Task> done,
  required String timestamp,
}) async {
  final bundle = {
    'exported_at': DateTime.now().toIso8601String(),
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'done': done.map((t) => t.toJson()).toList(),
  };
  final fileUri = await FilePicker.saveFile(
    dialogTitle: 'Save JSON File',
    fileName: 'todopod_backup_$timestamp.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
    bytes: utf8.encode(const JsonEncoder.withIndent('  ').convert(bundle)),
  );
  if (fileUri == null) return null;
  return fileUri.path;
}
