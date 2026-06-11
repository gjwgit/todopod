/// File export helpers for todopod — Todo.txt and JSON backup writing.
///
/// These wrap the file-picker save dialog and the actual file write,
/// returning the saved path (or null if cancelled) so the calling screen
/// can show an appropriate status message. Kept separate to keep the
/// import/backup screen focused on layout and state.
///
// Time-stamp: <2026-06-11>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3

library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:todopod/models/task.dart';

/// Write [tasks] as Todo.txt lines to a user-chosen file.
/// Returns the saved path, or null if the user cancelled.
Future<String?> saveTasksTxt({
  required List<Task> tasks,
  required String prefix,
  required String timestamp,
}) async {
  final savePath = await FilePicker.saveFile(
    dialogTitle: 'Save $prefix.txt',
    fileName: '${prefix}_$timestamp.txt',
    type: FileType.any,
  );
  if (savePath == null) return null;
  await File(
    savePath,
  ).writeAsBytes(utf8.encode(tasks.map((t) => t.toTodoTxt()).join('\n')));
  return savePath;
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
  final savePath = await FilePicker.saveFile(
    dialogTitle: 'Save JSON Backup',
    fileName: 'todopod_backup_$timestamp.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (savePath == null) return null;
  await File(
    savePath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(bundle));
  return savePath;
}
