/// TaskParser — parse and serialise todo.txt format files.
///
// Time-stamp: <Wednesday 2026-04-01 12:42:37 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0

library;

import 'package:uuid/uuid.dart';

import 'package:todopod/models/task.dart';

const _uuid = Uuid();

/// Parse a todo.txt file content into a list of [Task]s.
///
/// Blank lines and comment lines (starting with #) are skipped.

List<Task> parseTodoTxt(String content) {
  final tasks = <Task>[];
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final task = _parseLine(trimmed);
    if (task != null) tasks.add(task);
  }
  return tasks;
}

// ── Line parser ───────────────────────────────────────────────────────────────

Task? _parseLine(String line) {
  var rest = line;
  bool completed = false;
  DateTime? completionDate;
  DateTime? creationDate;
  String? priority;

  // Completed: starts with "x "
  if (rest.startsWith('x ')) {
    completed = true;
    rest = rest.substring(2).trimLeft();
    // Optional completion date
    final d = _consumeDate(rest);
    if (d != null) {
      completionDate = d;
      rest = rest.substring(10).trimLeft();
    }
  }

  // Priority: (A)
  final priMatch = RegExp(r'^\(([A-Z])\) ').firstMatch(rest);
  if (priMatch != null) {
    priority = priMatch.group(1);
    rest = rest.substring(priMatch.end);
  }

  // Creation date
  final cd = _consumeDate(rest);
  if (cd != null) {
    creationDate = cd;
    rest = rest.substring(10).trimLeft();
  }

  if (rest.isEmpty) return null;

  // Extract special tokens from the remaining text
  final projects = <String>[];
  final contexts = <String>[];
  String? duration;
  DateTime? dueDate;
  final descWords = <String>[];

  for (final word in rest.split(' ')) {
    if (word.startsWith('+') && word.length > 1) {
      projects.add(word.substring(1));
    } else if (word.startsWith('@') && word.length > 1) {
      contexts.add(word.substring(1));
    } else if (word.startsWith('due:') && word.length > 4) {
      dueDate = DateTime.tryParse(word.substring(4));
    } else if (word.startsWith('=') && word.length > 1) {
      duration = word.substring(1);
    } else {
      descWords.add(word);
    }
  }

  return Task(
    id: _uuid.v4(),
    completed: completed,
    priority: priority,
    completionDate: completionDate,
    creationDate: creationDate,
    description: descWords.join(' ').trim(),
    projects: projects,
    contexts: contexts,
    duration: duration,
    dueDate: dueDate,
  );
}

DateTime? _consumeDate(String s) {
  if (s.length < 10) return null;
  return DateTime.tryParse(s.substring(0, 10));
}
